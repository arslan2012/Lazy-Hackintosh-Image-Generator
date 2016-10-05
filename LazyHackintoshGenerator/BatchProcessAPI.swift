import Foundation

class BatchProcessAPI{
    var lazypath = "/tmp/com.pcbeta.lazy/LazyMount"
    let orgpath = "/tmp/com.pcbeta.lazy/OriginMount"
    var esdpath="/tmp/com.pcbeta.lazy/ESDMount"
    var SystemVersion = ""
    var SystemBuildVersion = ""
    var viewDelegate: BatchProcessAPIProtocol
    var AppDelegate: MenuControlProtocol
    let fileManager = FileManager.default
    init(AppDelegate: MenuControlProtocol) {
        self.viewDelegate = delegate!
        self.AppDelegate = AppDelegate
    }
    
    //the main work flow
    func startGenerating(
        filePath:String,
        SizeVal:String,
        MBRPatchState:Bool,
        LapicPatchState:Bool,
        XCPMPatchState:Bool,
        cdrState:Bool,
        dropKernelState:Bool,
        extraDroppedFilePath:String,
        Path:String,
        MountPath:String,
        OSInstallerPath:String
        ){
        DispatchQueue.main.async{
            self.maintainAuth()
            _ = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.maintainAuth), userInfo: nil, repeats: true)
        }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async{
            self.AppDelegate.ProcessStarted()
            ////////////////////////////cleaning processes////////////////////////progress:3%
            if self.viewDelegate.debugLog {
                let options = [
                    filePath,
                    SizeVal,
                    MBRPatchState ? "true" : "false",
                    LapicPatchState ? "true" : "false",
                    XCPMPatchState ? "true" : "false",
                    cdrState ? "true" : "false",
                    dropKernelState ? "true" : "false",
                    extraDroppedFilePath,
                    Path,
                    MountPath,
                    OSInstallerPath] as [String]
                Logger("=======Workflow Starting======")
                Logger(options.joined(separator: ","))
            }
            self.clean()
            ////////////////////////////mounting processes////////////////////////progress:4%
            self.mount(filePath)
            ////////////////////////////creating processes////////////////////////progress:24%
            self.create(SizeVal,MountPath)
            ////////////////////////////copying processes/////////////////////////progress:54%
            if MountPath == "" {
                self.copy()
            }else{
                self.copy(MountPath)
            }
            ////////////////////////////patching processes////////////////////////progress:6%
            if MBRPatchState {
                OSInstaller_Patch(self.SystemVersion,self.SystemBuildVersion,"\(self.lazypath.replacingOccurrences(of: " ", with: "\\ "))/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller")
                if !self.SystemBuildVersion.SysBuildVerBiggerThan("16A284a"){
                    OSInstall_mpkg_Patch(self.SystemVersion,"\(self.lazypath)/System/Installation/Packages/OSInstall.mpkg")
                }
            }else {
                if OSInstallerPath != ""{
                    Command("/bin/cp",["-f",OSInstallerPath,"\(self.lazypath)/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], "#Patch osinstaller#",0)
                    if !self.SystemBuildVersion.SysBuildVerBiggerThan("16A284a"){
                        OSInstall_mpkg_Patch(self.SystemVersion,"\(self.lazypath)/System/Installation/Packages/OSInstall.mpkg")
                    }
                }
                self.viewDelegate.didReceiveProgress(2)
            }
            if dropKernelState {
                self.Drop_Kernel()
            }else {
                self.viewDelegate.didReceiveProgress(1)
            }
            
            var failedLapic = false
            if LapicPatchState{
                failedLapic = LAPIC_Patch(self.SystemVersion,"\(self.lazypath)/System/Library/Kernels/kernel")
            }
            
            if XCPMPatchState {
                XCPM_Patch(self.SystemVersion,"\(self.lazypath)/System/Library/Kernels/kernel")
            }else {
                self.viewDelegate.didReceiveProgress(1)
            }
            
            Command("/bin/cp",["-R",extraDroppedFilePath,"\(self.lazypath)/"], "#COPYEXTRA#", 2)
            if self.viewDelegate.debugLog {
                Logger("=======patching done========")
            }
            ////////////////////////////ejecting processes////////////////////////progress:9%
            if Path == "" {
                self.eject(cdrState)
            }else{
                self.eject(cdrState,Path)
            }
            
            Command("/bin/rm",["-rf","/tmp/com.pcbeta.lazy"], "#Finishing#", 0)
            if failedLapic {
                self.viewDelegate.didReceiveProcessName("#Failed Lapic#")
            }else {
                self.viewDelegate.didReceiveProcessName("#FINISH#")
            }
            self.viewDelegate.didReceiveThreadExitMessage()
            self.AppDelegate.ProcessEnded()
        }
    }
    
    //functions below are processes
    
    private func clean(){
        do{
            let enumerator = try self.fileManager.contentsOfDirectory(atPath: "/tmp/com.pcbeta.lazy")
            for element in enumerator {
                Command("/usr/bin/hdiutil",["detach","/tmp/com.pcbeta.lazy/\(element)","-force"], "#CleanDir#", 0)
            }
        }catch{}
        Command("/bin/rm",["-rf","/tmp/com.pcbeta.lazy"], "#CleanDir#", 0)
        Command("/bin/mkdir",["/tmp/com.pcbeta.lazy"], "#CleanDir#", 3)
        if self.viewDelegate.debugLog {
            Logger("========cleaning done========")
        }
    }
    private func mount(_ filePath:String){
        if filePath.hasSuffix("dmg") {
            Command("/usr/bin/hdiutil",["attach",filePath,"-noverify","-nobrowse","-quiet","-mountpoint",self.orgpath], "#MOUNTORG#", 2)
            if (URL(fileURLWithPath:"\(orgpath)/BaseSystem.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                esdpath = orgpath
            }else {
                do{
                    let enumerator = try fileManager.contentsOfDirectory(atPath: orgpath)
                    for element in enumerator {
                        if element.hasSuffix("app") && (URL(fileURLWithPath:"\(orgpath)/\(element)") as NSURL).checkResourceIsReachableAndReturnError(nil){
                            Command("/usr/bin/hdiutil",["attach","\(orgpath)/\(element)/Contents/SharedSupport/InstallESD.dmg","-noverify","-nobrowse","-quiet","-mountpoint",esdpath], "#MOUNTESD#", 2)
                            break
                        }
                    }
                    if !(URL(fileURLWithPath:"\(esdpath)/BaseSystem.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                        self.viewDelegate.didReceiveErrorMessage("#Error in InstallESD image#")
                    }
                }
                catch{
                    self.viewDelegate.didReceiveErrorMessage("#Error in InstallESD image#")
                }
            }
        } else if filePath.hasSuffix("app") {
            if (URL(fileURLWithPath:"\(filePath)/Contents/SharedSupport/InstallESD.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil){
                Command("/usr/bin/hdiutil",["attach","\(filePath)/Contents/SharedSupport/InstallESD.dmg","-noverify","-nobrowse","-quiet","-mountpoint",esdpath], "#MOUNTESD#", 4)
            }else {
                self.viewDelegate.didReceiveErrorMessage("#Error in InstallESD image#")
            }
        }
        if self.viewDelegate.debugLog {
            Logger("=======mounting done========")
        }
    }
    private func create(_ SizeVal:String,_ MountPath:String){
        if MountPath == ""{
            Command("/usr/bin/hdiutil",["create","-size","\(SizeVal)g","-layout","SPUD","-ov","-fs","HFS+J","-volname","OS X Lazy Installer","/tmp/com.pcbeta.lazy/Lazy Installer.dmg"], "#Create Lazy image#", 22)
            Command("/usr/bin/hdiutil",["attach","/tmp/com.pcbeta.lazy/Lazy Installer.dmg","-noverify","-nobrowse","-quiet","-mountpoint",self.lazypath], "#Mount Lazy image#", 2)
        }else{
            self.lazypath = MountPath
            self.viewDelegate.didReceiveProgress(24)
        }
        if !(URL(fileURLWithPath:self.lazypath) as NSURL).checkResourceIsReachableAndReturnError(nil){
            self.viewDelegate.didReceiveErrorMessage("#Error in lazy image#")
        }
        if self.viewDelegate.debugLog {
            Logger("=======creating done========")
        }
    }
    private func copy(){
        privilegedCommand("/usr/sbin/asr",["restore","--source","\(self.esdpath)/BaseSystem.dmg","--target",self.lazypath,"--erase","--format","HFS+","--noprompt","--noverify"], "#COPYBASE#",17)
        var asrCompletedMounting = false;
        let asrTime = Timer.scheduledTimer(timeInterval: 200, target: self, selector: #selector(BatchProcessAPI.asrTimeout), userInfo: nil, repeats: false)
        while(!asrCompletedMounting){
            do{
                let enumerator = try self.fileManager.contentsOfDirectory(atPath: "/Volumes")
                for element in enumerator {
                    if element.hasPrefix("OS X Base System"){
                        if (URL(fileURLWithPath:"/Volumes/\(element)") as NSURL).checkResourceIsReachableAndReturnError(nil){
                            Command("/usr/bin/hdiutil",["detach","/Volumes/\(element)","-force"], "#Wait Asr#", 0)
                        }
                    }
                }
            }catch{}
            Command("/usr/bin/hdiutil",["attach","/tmp/com.pcbeta.lazy/Lazy Installer.dmg","-noverify","-nobrowse","-quiet","-mountpoint",self.lazypath], "#Wait Asr#", 0)
            do{
                let enumerator = try self.fileManager.contentsOfDirectory(atPath: "\(self.lazypath)")
                if enumerator.count > 2 {
                    self.viewDelegate.didReceiveProgress(2)
                    asrTime.invalidate()
                    asrCompletedMounting = true
                }
            }
            catch{
                self.viewDelegate.didReceiveErrorMessage("#Error in lazy image#")
            }
        }
        self.checkVersion()
        if self.SystemVersion.SysVerBiggerThan("10.11.99"){
            privilegedCommand("/usr/sbin/diskutil",["rename","OS X Base System","Sierra Custom Installer"], "#COPYBASE#",2)
        }else if self.SystemVersion.SysVerBiggerThan("10.10.99"){
            privilegedCommand("/usr/sbin/diskutil",["rename","OS X Base System","El Capitan Custom Installer"], "#COPYBASE#",2)
        }else if self.SystemVersion.SysVerBiggerThan("10.9.99"){
            privilegedCommand("/usr/sbin/diskutil",["rename","OS X Base System","Yosemite Custom Installer"], "#COPYBASE#",2)
        }else{
            privilegedCommand("/usr/sbin/diskutil",["rename","OS X Base System","OS X Custom Installer"], "#COPYBASE#",2)
        }
        Command("/bin/cp",["\(self.esdpath)/BaseSystem.chunklist",self.lazypath], "#Copy ESD#", 2)
        Command("/bin/cp",["\(self.esdpath)/BaseSystem.dmg",self.lazypath], "#Copy ESD#", 2)
        Command("/bin/cp",["\(self.esdpath)/AppleDiagnostics.chunklist",self.lazypath], "#Copy ESD#", 2)
        Command("/bin/cp",["\(self.esdpath)/AppleDiagnostics.dmg",self.lazypath], "#Copy ESD#", 2)
        Command("/bin/rm",["-rf","\(self.lazypath)/System/Installation/Packages"], "#DELETEPACKAGE#", 2)
        privilegedCommand("/bin/cp",["-R","\(self.esdpath)/Packages","\(self.lazypath)/System/Installation"], "#COPYPACKAGE#",22)
        Command("/bin/mkdir",["\(self.lazypath)/System/Library/Kernels"], "#Create Kernels folder#", 1)
        if self.viewDelegate.debugLog {
            Logger("========copying done========")
        }
    }
    private func copy(_ MountPath:String){
        privilegedCommand("/usr/sbin/asr",["restore","--source","\(self.esdpath)/BaseSystem.dmg","--target",self.lazypath,"--erase","--format","HFS+","--noprompt","--noverify"], "#COPYBASE#",19)
        var tmpname = ""
        do{
            let enumerator = try self.fileManager.contentsOfDirectory(atPath: "/Volumes")
            for element in enumerator {
                if element.hasPrefix("OS X Base System"){
                    if (URL(fileURLWithPath:"/Volumes/\(element)/System") as NSURL).checkResourceIsReachableAndReturnError(nil){
                        tmpname = element
                    }
                }
            }
        }catch{
            self.viewDelegate.didReceiveErrorMessage("#Error in lazy image#")
        }
        lazypath = "/Volumes/\(tmpname)"
        self.checkVersion()
        var changedName = ""
        if self.SystemVersion.SysVerBiggerThan("10.11.99"){
            changedName = "Sierra Custom Installer"
        }else if self.SystemVersion.SysVerBiggerThan("10.10.99"){
            changedName = "El Capitan Custom Installer"
        }else if self.SystemVersion.SysVerBiggerThan("10.9.99"){
            changedName = "Yosemite Custom Installer"
        }else{
            changedName = "OS X Custom Installer"
        }
        privilegedCommand("/usr/sbin/diskutil",["rename",tmpname,changedName], "#COPYBASE#",2)
        do{
            let enumerator = try self.fileManager.contentsOfDirectory(atPath: "/Volumes")
            for element in enumerator {
                if element.hasPrefix(changedName){
                    if (URL(fileURLWithPath:"/Volumes/\(element)/System") as NSURL).checkResourceIsReachableAndReturnError(nil){
                        lazypath = "/Volumes/\(element)"
                    }
                }
            }
        }catch{
            self.viewDelegate.didReceiveErrorMessage("#Error in lazy image#")
        }
        Command("/bin/cp",["\(self.esdpath)/BaseSystem.chunklist",self.lazypath], "#Copy ESD#", 2)
        Command("/bin/cp",["\(self.esdpath)/BaseSystem.dmg",self.lazypath], "#Copy ESD#", 2)
        Command("/bin/cp",["\(self.esdpath)/AppleDiagnostics.chunklist",self.lazypath], "#Copy ESD#", 2)
        Command("/bin/cp",["\(self.esdpath)/AppleDiagnostics.dmg",self.lazypath], "#Copy ESD#", 2)
        Command("/bin/rm",["-rf","\(self.lazypath)/System/Installation/Packages"], "#DELETEPACKAGE#", 2)
        privilegedCommand("/bin/cp",["-R","\(self.esdpath)/Packages","\(self.lazypath)/System/Installation"], "#COPYPACKAGE#",22)
        Command("/bin/mkdir",["\(self.lazypath)/System/Library/Kernels"], "#Create Kernels folder#", 1)
        if self.viewDelegate.debugLog {
            Logger("========copying done========")
        }
    }
    private func eject(_ cdrState:Bool,_ Path:String = "\(NSHomeDirectory())/Desktop/"){
        Command("/usr/bin/chflags",["nohidden",self.lazypath], "#EJECTESD#", 0)
        if cdrState {
            Command("/usr/bin/hdiutil",["detach",self.orgpath,"-force"], "#EJECTORG#", 0)
            Command("/usr/bin/hdiutil",["detach",self.esdpath,"-force"], "#EJECTESD#", 1)
            Command("/usr/bin/hdiutil",["detach",self.lazypath,"-force"], "#EJECTLAZY#", 1)
            
            Command("/usr/bin/hdiutil",["convert","/tmp/com.pcbeta.lazy/Lazy Installer.dmg","-ov","-format","UDTO","-o","/tmp/com.pcbeta.lazy/Lazy Installer.cdr"], "#Create CDR#", 7)
            if (Path == "\(NSHomeDirectory())/Desktop/"){
                if self.SystemVersion.SysVerBiggerThan("10.11.99"){
                    Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(Path)Sierra Custom Installer.dmg"], "#MV#", 0)
                    Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.cdr","\(Path)Sierra Custom Installer.cdr"], "#MV#", 0)
                }else if self.SystemVersion.SysVerBiggerThan("10.10.99") {
                    Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(Path)El Capitan Custom Installer.dmg"], "#MV#", 0)
                    Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.cdr","\(Path)El Capitan Custom Installer.cdr"], "#MV#", 0)
                }else if self.SystemVersion.SysVerBiggerThan("10.9.99") {
                    Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(Path)Yosemite Custom Installer.dmg"], "#MV#", 0)
                    Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.cdr","\(Path)Yosemite Custom Installer.cdr"], "#MV#", 0)
                }else {
                    Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg",Path], "#MV#", 0)
                    Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.cdr",Path], "#MV#", 0)
                }
            }else {
                Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg",Path], "#MV#", 0)
                Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.cdr",Path.replacingOccurrences(of: "dmg", with: "cdr")], "#MV#", 0)
            }
        }else{
            Command("/usr/bin/hdiutil",["detach",self.orgpath,"-force"], "#EJECTORG#", 2)
            Command("/usr/bin/hdiutil",["detach",self.esdpath,"-force"], "#EJECTESD#", 2)
            Command("/usr/bin/hdiutil",["detach",self.lazypath,"-force"], "#EJECTLAZY#", 2)
            if (Path == "\(NSHomeDirectory())/Desktop/"){
                if self.SystemVersion.SysVerBiggerThan("10.11.99"){
                    Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(Path)Sierra Custom Installer.dmg"], "#MV#", 3)
                }else if self.SystemVersion.SysVerBiggerThan("10.10.99"){
                    Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(Path)El Capitan Custom Installer.dmg"], "#MV#", 3)
                }else if self.SystemVersion.SysVerBiggerThan("10.9.99"){
                    Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(Path)Yosemite Custom Installer.dmg"], "#MV#", 3)
                }else{
                    Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg",Path], "#MV#", 3)
                }
            }else{
                Command("/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg",Path], "#MV#", 3)
            }
            
        }
    }
    
    //functions below are sub processes
    
    private func checkVersion() {//progress:0%
        let SystemVersionPlistPath = "\(lazypath)/System/Library/CoreServices/SystemVersion.plist"
        if let myDict = NSDictionary(contentsOfFile: SystemVersionPlistPath) {
            SystemVersion = myDict.value(forKey: "ProductVersion") as! String
            SystemBuildVersion = myDict.value(forKey: "ProductBuildVersion") as! String
        }else {
            self.viewDelegate.didReceiveErrorMessage("#Error in sysVer#")
        }
        if SystemVersion == "" || SystemBuildVersion == "" {
            self.viewDelegate.didReceiveErrorMessage("#Error in sysVer#")
        }
        if self.viewDelegate.debugLog {
            Logger("Detected System Version:\(SystemVersion) \(SystemBuildVersion)")
            Logger("===========================")
        }
    }
    
    private func Drop_Kernel() {//progress:1%
        Command(Bundle.main.path(forResource: "lzvn", ofType: nil)!,["-d","\(self.lazypath)/System/Library/PrelinkedKernels/prelinkedkernel","kernel"], "#COPYKERNELF#", 0, "/tmp/com.pcbeta.lazy/")
        Command("/bin/cp",["/tmp/com.pcbeta.lazy/kernel","\(self.lazypath)/System/Library/Kernels"], "#COPYKERNELF#", 1)
        if !self.SystemVersion.SysVerBiggerThan("10.11") {
            /////// 10.10.x
            Command("/bin/sh",["-c","perl -pi -e 's|\\xE8\\x25\\x00\\x00\\x00\\xEB\\x05\\xE8\\xCE\\x02\\x00\\x00|\\xE8\\x25\\x00\\x00\\x00\\x90\\x90\\xE8\\xCE\\x02\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
        }else if self.SystemVersion.SysVerBiggerThan("10.11.99"){
            if self.SystemBuildVersion == "16A201w"{
                /////// 10.12.DB1.116A201w
                Command("/bin/sh",["-c","perl -pi -e 's|\\xC3\\x48\\x85\\xDB\\x74\\x71\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|\\xC3\\x48\\x85\\xDB\\xEB\\x12\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
                Command("/bin/sh",["-c","perl -pi -e 's|\\xE8\\x25\\x00\\x00\\x00\\xEB\\x05\\xE8\\xCE\\x02\\x00\\x00|\\xE8\\x25\\x00\\x00\\x00\\x90\\x90\\xE8\\xCE\\x02\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
            }else if self.SystemBuildVersion == "16A238m" || self.SystemBuildVersion == "16A239j"{
                /////// 10.12.PB1.16A238m, 10.12.DB2.16A239j
                Command("/bin/sh",["-c","perl -pi -e 's|\\xC3\\x48\\x85\\xDB\\x74\\x71\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|\\xC3\\x48\\x85\\xDB\\xEB\\x12\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
                Command("/bin/sh",["-c","perl -pi -e 's|\\xE8\\x25\\x00\\x00\\x00\\xEB\\x05\\xE8\\x7E\\x05\\x00\\x00|\\xE8\\x25\\x00\\x00\\x00\\x90\\x90\\xE8\\x7E\\x05\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
            }
        }else {
            //////// 10.11.x
            Command("/bin/sh",["-c","perl -pi -e 's|\\xC3\\x48\\x85\\xDB\\x74\\x70\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|\\xC3\\x48\\x85\\xDB\\xEB\\x12\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
            Command("/bin/sh",["-c","perl -pi -e 's|\\xE8\\x25\\x00\\x00\\x00\\xEB\\x05\\xE8\\xCE\\x02\\x00\\x00|\\xE8\\x25\\x00\\x00\\x00\\x90\\x90\\xE8\\xCE\\x02\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
        }
        Command("/bin/chmod",["+x","\(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
    }
    @objc func maintainAuth() {
        STPrivilegedTask.extendAuthorizationRef()
    }
    @objc func asrTimeout(timer:Timer) {
        self.viewDelegate.didReceiveErrorMessage("#Asr Timeout#")
    }
}
