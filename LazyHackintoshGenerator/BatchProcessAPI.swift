import Foundation
protocol BatchProcessAPIProtocol {
    var debugLog:Bool{get set}
    func didReceiveProcessName(results: String)
    func didReceiveProgress(results: Double)
    func didReceiveErrorMessage(results: String)
    func didReceiveThreadExitMessage()
}
protocol MenuControlProtocol {
    func ProcessStarted()
    func ProcessEnded()
}

class BatchProcessAPI{
    var lazypath = "/tmp/com.pcbeta.lazy/LazyMount"
    let orgpath = "/tmp/com.pcbeta.lazy/OriginMount"
    var esdpath="/tmp/com.pcbeta.lazy/ESDMount"
    var SystemVersion = ""
    var SystemBuildVersion = ""
    var viewDelegate: BatchProcessAPIProtocol
    var AppDelegate: MenuControlProtocol
    let shell = shellCommand.sharedInstance
    let fileManager = NSFileManager.defaultManager()
    init(viewDelegate: BatchProcessAPIProtocol,AppDelegate: MenuControlProtocol) {
        self.viewDelegate = viewDelegate
        self.AppDelegate = AppDelegate
    }
    
    //the main work flow
    
    func startGenerating(filePath:String,_ SizeVal:String,_ MBRPatchState:Bool,_ LapicPatchState:Bool,_ XCPMPatchState:Bool,_ cdrState:Bool,_ dropKernelState:Bool,_ extraDroppedFilePath:String,_ Path:String,_ MountPath:String,_ OSInstallerPath:String){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),{
            self.AppDelegate.ProcessStarted()
            ////////////////////////////cleaning processes////////////////////////progress:3%
            if self.viewDelegate.debugLog {
                do{
                    try "=======Workflow Starting=======".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
                }catch{}
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
                self.OSInstaller_Patch()
                if !self.SystemBuildVersion.SysBuildVerBiggerThan("16A284a"){
                    self.OSInstall_mpkg_Patch()
                }
            }else {
                if OSInstallerPath != ""{
                    self.shell.Command(self.viewDelegate,"/bin/cp",["-f",OSInstallerPath,"\(self.lazypath)/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], "#Patch osinstaller#",0)
                    if !self.SystemBuildVersion.SysBuildVerBiggerThan("16A284a"){
                        self.OSInstall_mpkg_Patch()
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
                failedLapic = !self.LAPIC_Patch()
            }
            
            if XCPMPatchState {
                self.XCPM_Patch()
            }else {
                self.viewDelegate.didReceiveProgress(1)
            }
            
            self.shell.Command(self.viewDelegate,"/bin/cp",["-R",extraDroppedFilePath,"\(self.lazypath)/"], "#COPYEXTRA#", 2)
            if self.viewDelegate.debugLog {
                do{
                    try "=======patching done=======".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
                }catch{}
            }
            ////////////////////////////ejecting processes////////////////////////progress:9%
            if Path == "" {
                self.eject(cdrState)
            }else{
                self.eject(cdrState,Path)
            }
            
            self.shell.Command(self.viewDelegate,"/bin/rm",["-rf","/tmp/com.pcbeta.lazy"], "#Finishing#", 0)
            if failedLapic {
                self.viewDelegate.didReceiveProcessName("#Failed Lapic#")
            }else {
                self.viewDelegate.didReceiveProcessName("#FINISH#")
            }
            self.viewDelegate.didReceiveThreadExitMessage()
            self.AppDelegate.ProcessEnded()
        })
    }
    
    //functions below are processes
    
    private func clean(){
        do{
            let enumerator = try self.fileManager.contentsOfDirectoryAtPath("/tmp/com.pcbeta.lazy")
            for element in enumerator {
                if NSURL(fileURLWithPath:"/tmp/com.pcbeta.lazy/\(element)").checkResourceIsReachableAndReturnError(nil){
                    self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach","/tmp/com.pcbeta.lazy/\(element)","-force"], "#CleanDir#", 0)
                }
            }
        }catch{}
        self.shell.Command(self.viewDelegate,"/bin/rm",["-rf","/tmp/com.pcbeta.lazy"], "#CleanDir#", 0)
        self.shell.Command(self.viewDelegate,"/bin/mkdir",["/tmp/com.pcbeta.lazy"], "#CleanDir#", 3)
        if self.viewDelegate.debugLog {
            do{
                try "========cleaning done=======".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
            }catch{}
        }
    }
    private func mount(filePath:String){
        if filePath.hasSuffix("dmg") {
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["attach",filePath,"-noverify","-nobrowse","-quiet","-mountpoint",self.orgpath], "#MOUNTORG#", 2)
            if NSURL(fileURLWithPath:"\(orgpath)/BaseSystem.dmg").checkResourceIsReachableAndReturnError(nil) {
                esdpath = orgpath
            }else {
                do{
                    let enumerator = try fileManager.contentsOfDirectoryAtPath(orgpath)
                    for element in enumerator {
                        if element.hasSuffix("app") && NSURL(fileURLWithPath:"\(orgpath)/\(element)").checkResourceIsReachableAndReturnError(nil){
                            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["attach","\(orgpath)/\(element)/Contents/SharedSupport/InstallESD.dmg","-noverify","-nobrowse","-quiet","-mountpoint",esdpath], "#MOUNTESD#", 2)
                            break
                        }
                    }
                    if !NSURL(fileURLWithPath:"\(esdpath)/BaseSystem.dmg").checkResourceIsReachableAndReturnError(nil) {
                        self.viewDelegate.didReceiveErrorMessage("#Error in InstallESD image#")
                    }
                }
                catch{
                    self.viewDelegate.didReceiveErrorMessage("#Error in InstallESD image#")
                }
            }
        } else if filePath.hasSuffix("app") {
            if NSURL(fileURLWithPath:"\(filePath)/Contents/SharedSupport/InstallESD.dmg").checkResourceIsReachableAndReturnError(nil){
                self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["attach","\(filePath)/Contents/SharedSupport/InstallESD.dmg","-noverify","-nobrowse","-quiet","-mountpoint",esdpath], "#MOUNTESD#", 4)
            }else {
                self.viewDelegate.didReceiveErrorMessage("#Error in InstallESD image#")
            }
        }
        if self.viewDelegate.debugLog {
            do{
                try "=======mounting done=======".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
            }catch{}
        }
    }
    private func create(SizeVal:String,_ MountPath:String){
        if MountPath == ""{
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["create","-size","\(SizeVal)g","-layout","SPUD","-ov","-fs","HFS+J","-volname","OS X Lazy Installer","/tmp/com.pcbeta.lazy/Lazy Installer.dmg"], "#Create Lazy image#", 22)
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["attach","/tmp/com.pcbeta.lazy/Lazy Installer.dmg","-noverify","-nobrowse","-quiet","-mountpoint",self.lazypath], "#Mount Lazy image#", 2)
        }else{
            self.lazypath = MountPath
            self.viewDelegate.didReceiveProgress(24)
        }
        if !NSURL(fileURLWithPath:self.lazypath).checkResourceIsReachableAndReturnError(nil){
            self.viewDelegate.didReceiveErrorMessage("#Error in lazy image#")
        }
        if self.viewDelegate.debugLog {
            do{
                try "=======creating done=======".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
            }catch{}
        }
    }
    private func copy(){
        self.shell.privilegedCommand(self.viewDelegate,"/usr/sbin/asr",["restore","--source","\(self.esdpath)/BaseSystem.dmg","--target",self.lazypath,"--erase","--format","HFS+","--noprompt","--noverify"], "#COPYBASE#",17)
        do{
            let enumerator = try self.fileManager.contentsOfDirectoryAtPath("/Volumes")
            for element in enumerator {
                if element.hasPrefix("OS X Base System"){
                    if NSURL(fileURLWithPath:"/Volumes/\(element)").checkResourceIsReachableAndReturnError(nil){
                        self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach","/Volumes/\(element)","-force"], "", 0)
                    }
                }
            }
        }catch{}
        self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["attach","/tmp/com.pcbeta.lazy/Lazy Installer.dmg","-noverify","-nobrowse","-quiet","-mountpoint",self.lazypath], "#Mount Lazy image#", 2)
        do{
            let enumerator = try self.fileManager.contentsOfDirectoryAtPath("\(self.lazypath)/System")
            if enumerator.count < 2 {
                self.viewDelegate.didReceiveErrorMessage("#Error in lazy image#")
            }
        }
        catch{
            self.viewDelegate.didReceiveErrorMessage("#Error in lazy image#")
        }
        self.checkVersion()
        if self.SystemVersion.SysVerBiggerThan("10.11.99"){
            self.shell.privilegedCommand(self.viewDelegate,"/usr/sbin/diskutil",["rename","OS X Base System","Sierra Custom Installer"], "#COPYBASE#",2)
        }else if self.SystemVersion.SysVerBiggerThan("10.10.99"){
            self.shell.privilegedCommand(self.viewDelegate,"/usr/sbin/diskutil",["rename","OS X Base System","El Capitan Custom Installer"], "#COPYBASE#",2)
        }else if self.SystemVersion.SysVerBiggerThan("10.9.99"){
            self.shell.privilegedCommand(self.viewDelegate,"/usr/sbin/diskutil",["rename","OS X Base System","Yosemite Custom Installer"], "#COPYBASE#",2)
        }else{
            self.shell.privilegedCommand(self.viewDelegate,"/usr/sbin/diskutil",["rename","OS X Base System","OS X Custom Installer"], "#COPYBASE#",2)
        }
        self.shell.Command(self.viewDelegate,"/bin/cp",["\(self.esdpath)/BaseSystem.chunklist",self.lazypath], "#Copy ESD#", 2)
        self.shell.Command(self.viewDelegate,"/bin/cp",["\(self.esdpath)/BaseSystem.dmg",self.lazypath], "#Copy ESD#", 2)
        self.shell.Command(self.viewDelegate,"/bin/cp",["\(self.esdpath)/AppleDiagnostics.chunklist",self.lazypath], "#Copy ESD#", 2)
        self.shell.Command(self.viewDelegate,"/bin/cp",["\(self.esdpath)/AppleDiagnostics.dmg",self.lazypath], "#Copy ESD#", 2)
        self.shell.Command(self.viewDelegate,"/bin/rm",["-rf","\(self.lazypath)/System/Installation/Packages"], "#DELETEPACKAGE#", 2)
        self.shell.privilegedCommand(self.viewDelegate,"/bin/cp",["-R","\(self.esdpath)/Packages","\(self.lazypath)/System/Installation"], "#COPYPACKAGE#",22)
        self.shell.Command(self.viewDelegate,"/bin/mkdir",["\(self.lazypath)/System/Library/Kernels"], "#Create Kernels folder#", 1)
        if self.viewDelegate.debugLog {
            do{
                try "========copying done=======".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
            }catch{}
        }
    }
    private func copy(MountPath:String){
        self.shell.privilegedCommand(self.viewDelegate,"/usr/sbin/asr",["restore","--source","\(self.esdpath)/BaseSystem.dmg","--target",self.lazypath,"--erase","--format","HFS+","--noprompt","--noverify"], "#COPYBASE#",19)
        var tmpname = ""
        do{
            let enumerator = try self.fileManager.contentsOfDirectoryAtPath("/Volumes")
            for element in enumerator {
                if element.hasPrefix("OS X Base System"){
                    if NSURL(fileURLWithPath:"/Volumes/\(element)/System").checkResourceIsReachableAndReturnError(nil){
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
        self.shell.privilegedCommand(self.viewDelegate,"/usr/sbin/diskutil",["rename",tmpname,changedName], "#COPYBASE#",2)
        do{
            let enumerator = try self.fileManager.contentsOfDirectoryAtPath("/Volumes")
            for element in enumerator {
                if element.hasPrefix(changedName){
                    if NSURL(fileURLWithPath:"/Volumes/\(element)/System").checkResourceIsReachableAndReturnError(nil){
                        lazypath = "/Volumes/\(element)"
                    }
                }
            }
        }catch{
            self.viewDelegate.didReceiveErrorMessage("#Error in lazy image#")
        }
        self.shell.Command(self.viewDelegate,"/bin/cp",["\(self.esdpath)/BaseSystem.chunklist",self.lazypath], "#Copy ESD#", 2)
        self.shell.Command(self.viewDelegate,"/bin/cp",["\(self.esdpath)/BaseSystem.dmg",self.lazypath], "#Copy ESD#", 2)
        self.shell.Command(self.viewDelegate,"/bin/cp",["\(self.esdpath)/AppleDiagnostics.chunklist",self.lazypath], "#Copy ESD#", 2)
        self.shell.Command(self.viewDelegate,"/bin/cp",["\(self.esdpath)/AppleDiagnostics.dmg",self.lazypath], "#Copy ESD#", 2)
        self.shell.Command(self.viewDelegate,"/bin/rm",["-rf","\(self.lazypath)/System/Installation/Packages"], "#DELETEPACKAGE#", 2)
        self.shell.privilegedCommand(self.viewDelegate,"/bin/cp",["-R","\(self.esdpath)/Packages","\(self.lazypath)/System/Installation"], "#COPYPACKAGE#",22)
        self.shell.Command(self.viewDelegate,"/bin/mkdir",["\(self.lazypath)/System/Library/Kernels"], "#Create Kernels folder#", 1)
        if self.viewDelegate.debugLog {
            do{
                try "========copying done=======".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
            }catch{}
        }
    }
    private func eject(cdrState:Bool){
        self.shell.Command(self.viewDelegate,"/usr/bin/chflags",["nohidden",self.lazypath], "#EJECTESD#", 0)
        if cdrState {
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach",self.orgpath,"-force"], "#EJECTORG#", 0)
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach",self.esdpath,"-force"], "#EJECTESD#", 1)
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach",self.lazypath,"-force"], "#EJECTLAZY#", 1)
            
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["convert","/tmp/com.pcbeta.lazy/Lazy Installer.dmg","-ov","-format","UDTO","-o","/tmp/com.pcbeta.lazy/Lazy Installer.cdr"], "#Create CDR#", 7)
            
            if self.SystemVersion.SysVerBiggerThan("10.11.99"){
                self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/Sierra Custom Installer.dmg"], "#MV#", 0)
                self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.cdr","\(NSHomeDirectory())/Desktop/Sierra Custom Installer.cdr"], "#MV#", 0)
            }else if self.SystemVersion.SysVerBiggerThan("10.10.99") {
                self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/El Capitan Custom Installer.dmg"], "#MV#", 0)
                self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.cdr","\(NSHomeDirectory())/Desktop/El Capitan Custom Installer.cdr"], "#MV#", 0)
            }else if self.SystemVersion.SysVerBiggerThan("10.9.99") {
                self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/Yosemite Custom Installer.dmg"], "#MV#", 0)
                self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.cdr","\(NSHomeDirectory())/Desktop/Yosemite Custom Installer.cdr"], "#MV#", 0)
            }else {
                self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/"], "#MV#", 0)
                self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.cdr","\(NSHomeDirectory())/Desktop/"], "#MV#", 0)
            }
        }else{
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach",self.orgpath,"-force"], "#EJECTORG#", 2)
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach",self.esdpath,"-force"], "#EJECTESD#", 2)
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach",self.lazypath,"-force"], "#EJECTLAZY#", 2)
            
            if self.SystemVersion.SysVerBiggerThan("10.11.99"){
                self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/Sierra Custom Installer.dmg"], "#MV#", 3)
            }else if self.SystemVersion.SysVerBiggerThan("10.10.99"){
                self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/El Capitan Custom Installer.dmg"], "#MV#", 3)
            }else if self.SystemVersion.SysVerBiggerThan("10.9.99"){
                self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/Yosemite Custom Installer.dmg"], "#MV#", 3)
            }else{
                self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/"], "#MV#", 3)
            }
        }
    }
    private func eject(cdrState:Bool,_ Path:String){
        self.shell.Command(self.viewDelegate,"/usr/bin/chflags",["nohidden",self.lazypath], "#EJECTESD#", 0)
        if cdrState {
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach",self.orgpath,"-force"], "#EJECTORG#", 0)
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach",self.esdpath,"-force"], "#EJECTESD#", 1)
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach",self.lazypath,"-force"], "#EJECTLAZY#", 1)
            
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["convert","/tmp/com.pcbeta.lazy/Lazy Installer.dmg","-ov","-format","UDTO","-o","/tmp/com.pcbeta.lazy/Lazy Installer.cdr"], "#Create CDR#", 7)
            self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg",Path], "#MV#", 0)
            self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.cdr",Path.stringByReplacingOccurrencesOfString("dmg", withString: "cdr")], "#MV#", 0)
        }else{
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach",self.orgpath,"-force"], "#EJECTORG#", 2)
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach",self.esdpath,"-force"], "#EJECTESD#", 2)
            self.shell.Command(self.viewDelegate,"/usr/bin/hdiutil",["detach",self.lazypath,"-force"], "#EJECTLAZY#", 2)
            self.shell.Command(self.viewDelegate,"/bin/mv",["/tmp/com.pcbeta.lazy/Lazy Installer.dmg",Path], "#MV#", 3)
        }
    }
    
    //functions below are sub processes
    
    private func checkVersion() {//progress:0%
        if self.viewDelegate.debugLog {
            shell.Command(self.viewDelegate,"/bin/ls",["-l","\(lazypath)/System/Library/CoreServices/SystemVersion.plist"], "#Mount Lazy image#", 0)
        }
        let SystemVersionPlistPath = "\(lazypath)/System/Library/CoreServices/SystemVersion.plist"
        if let myDict = NSDictionary(contentsOfFile: SystemVersionPlistPath) {
            SystemVersion = myDict.valueForKey("ProductVersion") as! String
            SystemBuildVersion = myDict.valueForKey("ProductBuildVersion") as! String
        }else {
            self.viewDelegate.didReceiveErrorMessage("#Error in sysVer#")
        }
        if SystemVersion == "" || SystemBuildVersion == "" {
            self.viewDelegate.didReceiveErrorMessage("#Error in sysVer#")
        }
        if self.viewDelegate.debugLog {
            do{
                try "Detected System Version:\(SystemVersion) \(SystemBuildVersion)".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
                try "===========================".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
            }catch{}
        }
    }
    
    private func OSInstaller_Patch(){//progress:2%
        if self.SystemVersion.SysVerBiggerThan("10.11.99") {
            if self.SystemBuildVersion == "16A238m"{
                shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x0F\\x84\\x91\\x00\\x00\\x00\\x48|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x90\\xE9\\x91\\x00\\x00\\x00\\x48|g' \(self.lazypath.stringByReplacingOccurrencesOfString(" ", withString: "\\ "))/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], "#Patch osinstaller#",1)
            }else{
                shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x0F\\x84\\x96\\x00\\x00\\x00\\x48|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\xE9\\x97\\x00\\x00\\x00\\x90\\x48|g' \(self.lazypath.stringByReplacingOccurrencesOfString(" ", withString: "\\ "))/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], "#Patch osinstaller#",1)
            }
        }else {
            shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x74\\x5F\\x48\\x8B\\x85|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\xEB\\x5F\\x48\\x8B\\x85|g' \(self.lazypath.stringByReplacingOccurrencesOfString(" ", withString: "\\ "))/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], "#Patch osinstaller#",1)
        }
        shell.privilegedCommand(self.viewDelegate,"/usr/bin/codesign",["-f","-s","-","\(self.lazypath)/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], "#Patch osinstaller#",1)
    }
    
    private func OSInstall_mpkg_Patch(){//progress:0%
        shell.Command(self.viewDelegate,"/bin/mkdir",["/tmp/com.pcbeta.lazy/osinstallmpkg"], "#Patch osinstall.mpkg#", 0)
        shell.Command(self.viewDelegate,"/usr/bin/xar",["-x","-f","\(self.lazypath)/System/Installation/Packages/OSInstall.mpkg","-C","/tmp/com.pcbeta.lazy/osinstallmpkg"], "#Patch osinstall.mpkg#", 0)
        if !self.SystemVersion.SysVerBiggerThan("10.11.99") {
            shell.Command(self.viewDelegate,"/usr/bin/sed",["-i","\'\'","--","s/1024/512/g","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
            shell.Command(self.viewDelegate,"/usr/bin/sed",["-i","\'\'","--","s/var minRam = 2048/var minRam = 1024/g","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
            shell.Command(self.viewDelegate,"/usr/bin/sed",["-i","\'\'","--","s/osVersion=......... osBuildVersion=.......//g","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
            shell.Command(self.viewDelegate,"/usr/bin/sed",["-i","\'\'","--","/\\<installation-check script=\"installCheckScript()\"\\/>/d","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
            shell.Command(self.viewDelegate,"/usr/bin/sed",["-i","\'\'","--","/\\<volume-check script=\"volCheckScript()\"\\/>/d","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        }else {
            shell.Command(self.viewDelegate,"/usr/bin/sed",["-i","\'\'","--","/\\<installation-check script=\"InstallationCheck()\"\\/>/d","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
            shell.Command(self.viewDelegate,"/usr/bin/sed",["-i","\'\'","--","/\\<volume-check script=\"VolumeCheck()\"\\/>/d","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        }
        shell.Command(self.viewDelegate,"/bin/rm",["\(self.lazypath)/System/Installation/Packages/OSInstall.mpkg"], "#Patch osinstall.mpkg#", 0)
        shell.Command(self.viewDelegate,"/bin/rm",["/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution\'\'"], "#Patch osinstall.mpkg#", 0)
        shell.Command(self.viewDelegate,"/usr/bin/xar",["-cf","\(self.lazypath)/System/Installation/Packages/OSInstall.mpkg","."], "/tmp/com.pcbeta.lazy/osinstallmpkg", "#Patch osinstall.mpkg#", 0)
    }
    
    private func Drop_Kernel() {//progress:1%
        shell.Command(self.viewDelegate,NSBundle.mainBundle().pathForResource("lzvn", ofType: nil)!,["-d","\(self.lazypath)/System/Library/PrelinkedKernels/prelinkedkernel","kernel"],"/tmp/com.pcbeta.lazy/", "#COPYKERNELF#", 0)
        shell.Command(self.viewDelegate,"/bin/cp",["/tmp/com.pcbeta.lazy/kernel","\(self.lazypath)/System/Library/Kernels"], "#COPYKERNELF#", 1)
        if !self.SystemVersion.SysVerBiggerThan("10.11") {
            /////// 10.10.x
            shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\xE8\\x25\\x00\\x00\\x00\\xEB\\x05\\xE8\\xCE\\x02\\x00\\x00|\\xE8\\x25\\x00\\x00\\x00\\x90\\x90\\xE8\\xCE\\x02\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
        }else if self.SystemVersion.SysVerBiggerThan("10.11.99"){
            if self.SystemBuildVersion == "16A201w"{
                /////// 10.12.DB1.116A201w
                shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\xC3\\x48\\x85\\xDB\\x74\\x71\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|\\xC3\\x48\\x85\\xDB\\xEB\\x12\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
                shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\xE8\\x25\\x00\\x00\\x00\\xEB\\x05\\xE8\\xCE\\x02\\x00\\x00|\\xE8\\x25\\x00\\x00\\x00\\x90\\x90\\xE8\\xCE\\x02\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
            }else if self.SystemBuildVersion == "16A238m" || self.SystemBuildVersion == "16A239j"{
                /////// 10.12.PB1.16A238m, 10.12.DB2.16A239j
                shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\xC3\\x48\\x85\\xDB\\x74\\x71\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|\\xC3\\x48\\x85\\xDB\\xEB\\x12\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
                shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\xE8\\x25\\x00\\x00\\x00\\xEB\\x05\\xE8\\x7E\\x05\\x00\\x00|\\xE8\\x25\\x00\\x00\\x00\\x90\\x90\\xE8\\x7E\\x05\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
            }
        }else {
            //////// 10.11.x
            shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\xC3\\x48\\x85\\xDB\\x74\\x70\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|\\xC3\\x48\\x85\\xDB\\xEB\\x12\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
            shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\xE8\\x25\\x00\\x00\\x00\\xEB\\x05\\xE8\\xCE\\x02\\x00\\x00|\\xE8\\x25\\x00\\x00\\x00\\x90\\x90\\xE8\\xCE\\x02\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
        }
        shell.Command(self.viewDelegate,"/bin/chmod",["+x","\(self.lazypath)/System/Library/Kernels/kernel"], "#COPYKERNELF#",0)
    }
    
    private func XCPM_Patch() {//progress:1%
        if !self.SystemVersion.SysVerBiggerThan("10.11.99") {
            shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x02\\x00\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#XCPMPATCH#",0)
        }
        shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x4c\\x00\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#XCPMPATCH#",0)
        if !self.SystemVersion.SysVerBiggerThan("10.11.1") {
            shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x90\\x01\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#XCPMPATCH#",1)
        }else if self.SystemVersion.SysVerBiggerThan("10.11.99") {
            shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x90\\x33\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#XCPMPATCH#",1)
        }else{
            shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x90\\x13\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#XCPMPATCH#",1)
        }
    }
    
    private func LAPIC_Patch() -> Bool {//progress:0%
        //////using rainbow chart method to speed up the patching process
        //        let transients:[String:String]=[
        //            "14A389":"\\xe8\\xd4\\x54\\xf1\\xff",
        //            "14B25":"\\xe8\\xd4\\x54\\xf1\\xff",
        //            "14C109":"\\xe8\\x54\\xed\\xf0\\xff",
        //            "14D131":"\\xe8\\x14\\xc8\\xf0\\xff",
        //            "14E46":"\\xe8\\x14\\xc8\\xf0\\xff",
        //            "14F27":"\\xe8\\x64\\xc6\\xf0\\xff",
        //            "15A284":"\\xe8\\xcd\\x6b\\xf0\\xff",
        //            "15B42":"\\xe8\\xfd\\x68\\xf0\\xff",
        //            "15C50":"\\xe8\\xed\\x53\\xf0\\xff",
        //            "15D21":"\\xe8\\xed\\x53\\xf0\\xff",
        //            "15E65":"\\xe8\\xbd\\x48\\xf0\\xff",
        //            "15F34":"\\xe8\\xcd\\x46\\xf0\\xff",
        //            "15G31":"\\xe8\\x0d\\x46\\xf0\\xff",
        //            ///////below is beta version patches
        //            "16A201w":"\\xe8\\x3d\\xdf\\xee\\xff",
        //            "16A238m":"\\xe8\\x2d\\x58\\xee\\xff"
        //        ]
        //        if let key = transients[self.SystemBuildVersion] {
        //            shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\(key)|\\x90\\x90\\x90\\x90\\x90|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#LAPICPATCH#",0)
        //            return true
        //        }else{
        //if rainbow chart fails, using donovan6000 and sherlocks method of finding hex _panic value method
        var FindingBlock = 0x0000001C250C8B65,offset = 0,patchoffset = 0
        if !self.SystemVersion.SysVerBiggerThan("10.11.1") {//if Yosemite
            FindingBlock = 0x0000001C25048B65
            offset = 33
            patchoffset = 28
        }else if self.SystemVersion.SysVerBiggerThan("10.11.99") {//if Sierra
            offset = 1409
            patchoffset = 1398
        }else{// if El Capitan
            offset = 1411
            patchoffset = 1400
        }
        var tmp1 = 0,tmp2 = 0,key = ""
        let file: NSData! = NSData(contentsOfURL: NSURL(fileURLWithPath: "\(self.lazypath)/System/Library/Kernels/kernel"))
        for i in 0...(file.length - offset) {
            file.getBytes(&tmp1, range: NSMakeRange(i, 7))
            file.getBytes(&tmp2, range: NSMakeRange(i+offset, 7))
            if tmp1 == FindingBlock && tmp2 == FindingBlock {
                var tmp3 = 0
                for n in 0...4{
                    file.getBytes(&tmp3, range: NSMakeRange(i+patchoffset+n, 1))
                    key += "\\x"
                    key += String(tmp3, radix: 16, uppercase: false)
                }
                break
            }
        }
        if key == "" {
            return false
        }else {
            shell.Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\(key)|\\x90\\x90\\x90\\x90\\x90|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#LAPICPATCH#",0)
            return true
        }
    }
    //}
}