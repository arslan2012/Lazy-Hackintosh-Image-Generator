import Foundation
protocol BatchProcessAPIProtocol {
	var debugLog:Bool{get set}
	func didReceiveProcessName(results: String)
	func didReceiveProgress(results: Double)
	func didReceiveErrorMessage(results: String)
	func didReceiveThreadExitMessage()
}

class BatchProcessAPI{
	var viewDelegate: BatchProcessAPIProtocol
	init(viewDelegate: BatchProcessAPIProtocol) {
		self.viewDelegate = viewDelegate
	}
	func shellCommand(path:String, arg: [String],label: String,progress: Double){
		let task = NSTask()
		task.launchPath = path
		task.arguments = arg
		let pipe = NSPipe()
		task.standardOutput = pipe
		task.launch()
		self.viewDelegate.didReceiveProcessName(label)
		task.waitUntilExit()
		self.viewDelegate.didReceiveProgress(progress)
		if self.viewDelegate.debugLog {
			let data = pipe.fileHandleForReading.readDataToEndOfFile()
			let output: String = String(data: data, encoding: NSUTF8StringEncoding)!
			let date = NSDate()
			let calendar = NSCalendar.currentCalendar()
			let components = calendar.components([.Hour, .Minute, .Second], fromDate: date)
			do{
				try "\(path) \(arg[0]),progress:\(progress)".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
				try output.appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
				try "==========\(components.hour):\(components.minute):\(components.second)==========".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
			}catch{}
		}
	}
	func privilegedShellCommand(path:String, arg: [String],label: String,progress: Double){
		let task = STPrivilegedTask()
		task.setLaunchPath(path)
		task.setArguments(arg)
		task.launch()
		self.viewDelegate.didReceiveProcessName(label)
		task.waitUntilExit()
		self.viewDelegate.didReceiveProgress(progress)
		if self.viewDelegate.debugLog {
			let date = NSDate()
			let calendar = NSCalendar.currentCalendar()
			let components = calendar.components([.Hour, .Minute, .Second], fromDate: date)
			do{
				try "sudo \(path) \(arg[0]),progress:\(progress)".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
				try "==========\(components.hour):\(components.minute):\(components.second)==========".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
			}catch{}
		}
	}
	func startGenerating(filePath:String,SizeVal:String,MBRPatchState:Bool,XCPMPatchState:Bool,cdrState:Bool,dropKernelState:Bool,extraDroppedFilePath:String){
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),{
			////////////////////////////mounting processes////////////////////////progress:7%
			let esdpath="/tmp/com.pcbeta.lazy/ESDMount"
			let lazypath = "/tmp/com.pcbeta.lazy/LazyMount"
			let fileManager = NSFileManager.defaultManager()
			do{
				let enumerator = try fileManager.contentsOfDirectoryAtPath("/tmp/com.pcbeta.lazy")
				for element in enumerator {
					if NSURL(fileURLWithPath:"/tmp/com.pcbeta.lazy/\(element)").checkResourceIsReachableAndReturnError(nil){
						self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/tmp/com.pcbeta.lazy/\(element)"], label: "#CleanDir#", progress: 0)
					}
				}
			}catch{}
			self.shellCommand("/bin/rm",arg: ["-rf","/tmp/com.pcbeta.lazy"], label: "#CleanDir#", progress: 0)
			self.shellCommand("/bin/mkdir",arg: ["/tmp/com.pcbeta.lazy"], label: "#CleanDir#", progress: 3)
			if filePath.hasSuffix("dmg") {
				let orgpath = "/tmp/com.pcbeta.lazy/OriginMount"
				self.shellCommand("/usr/bin/hdiutil",arg: ["attach",filePath,"-noverify","-nobrowse","-quiet","-mountpoint",orgpath], label: "#MOUNTORG#", progress: 2)
				do{
					let enumerator = try fileManager.contentsOfDirectoryAtPath(orgpath)
					for element in enumerator {
						if element.hasSuffix("app"){
							if NSURL(fileURLWithPath:"\(orgpath)/\(element)").checkResourceIsReachableAndReturnError(nil){
								self.shellCommand("/usr/bin/hdiutil",arg: ["attach","\(orgpath)/\(element)/Contents/SharedSupport/InstallESD.dmg","-noverify","-nobrowse","-quiet","-mountpoint",esdpath], label: "#MOUNTESD#", progress: 2)
							}else {
								self.viewDelegate.didReceiveErrorMessage("#Error in InstallESD image#")
							}
						}
					}
				}
				catch{
					self.viewDelegate.didReceiveErrorMessage("#Error in InstallESD image#")
				}
			} else if filePath.hasSuffix("app") {
				if NSURL(fileURLWithPath:"\(filePath)/Contents/SharedSupport/InstallESD.dmg").checkResourceIsReachableAndReturnError(nil){
					self.shellCommand("/usr/bin/hdiutil",arg: ["attach","\(filePath)/Contents/SharedSupport/InstallESD.dmg","-noverify","-nobrowse","-quiet","-mountpoint",esdpath], label: "#MOUNTESD#", progress: 4)
                }else {
					self.viewDelegate.didReceiveErrorMessage("#Error in InstallESD image#")
				}
			}
			////////////////////////////creating processes////////////////////////progress:24%
			self.shellCommand("/usr/bin/hdiutil",arg: ["create","-size","\(SizeVal)g","-layout","SPUD","-ov","-fs","HFS+J","-volname","OS X Lazy Installer","/tmp/com.pcbeta.lazy/Lazy Installer.dmg"], label: "#Create Lazy image#", progress: 22)
			self.shellCommand("/usr/bin/hdiutil",arg: ["attach","/tmp/com.pcbeta.lazy/Lazy Installer.dmg","-noverify","-nobrowse","-quiet","-mountpoint",lazypath], label: "#Mount Lazy image#", progress: 2)
			if !NSURL(fileURLWithPath:lazypath).checkResourceIsReachableAndReturnError(nil){
				self.viewDelegate.didReceiveErrorMessage("#Error in lazy image#")
			}
			////////////////////////////copying processes/////////////////////////progress:54%
			self.privilegedShellCommand("/usr/sbin/asr",arg: ["restore","--source","\(esdpath)/BaseSystem.dmg","--target",lazypath,"--erase","--format","HFS+","--noprompt","--noverify"], label: "#COPYBASE#",progress: 17)
			do{
				let enumerator = try fileManager.contentsOfDirectoryAtPath("/Volumes")
				for element in enumerator {
					if element.hasPrefix("OS X Base System"){
						if NSURL(fileURLWithPath:"/Volumes/\(element)").checkResourceIsReachableAndReturnError(nil){
							self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/\(element)"], label: "", progress: 0)
						}
					}
				}
			}
			catch{
				self.viewDelegate.didReceiveErrorMessage("#Error in lazy image#")
			}
			self.shellCommand("/usr/bin/hdiutil",arg: ["attach","/tmp/com.pcbeta.lazy/Lazy Installer.dmg","-noverify","-nobrowse","-quiet","-mountpoint",lazypath], label: "#Mount Lazy image#", progress: 2)
			self.privilegedShellCommand("/usr/sbin/diskutil",arg: ["rename","OS X Base System","OS X Lazy Installer"], label: "#COPYBASE#",progress: 2)
			self.shellCommand("/bin/cp",arg: ["\(esdpath)/BaseSystem.chunklist",lazypath], label: "#Copy ESD#", progress: 2)
			self.shellCommand("/bin/cp",arg: ["\(esdpath)/BaseSystem.dmg",lazypath], label: "#Copy ESD#", progress: 2)
			self.shellCommand("/bin/cp",arg: ["\(esdpath)/AppleDiagnostics.chunklist",lazypath], label: "#Copy ESD#", progress: 2)
			self.shellCommand("/bin/cp",arg: ["\(esdpath)/AppleDiagnostics.dmg",lazypath], label: "#Copy ESD#", progress: 2)
			self.shellCommand("/bin/rm",arg: ["-rf","\(lazypath)/System/Installation/Packages"], label: "#DELETEPACKAGE#", progress: 2)
			self.privilegedShellCommand("/bin/cp",arg: ["-R","\(esdpath)/Packages","\(lazypath)/System/Installation"], label: "#COPYPACKAGE#",progress: 22)
			self.shellCommand("/bin/mkdir",arg: ["\(lazypath)/System/Library/Kernels"], label: "#Create Kernels folder#", progress: 1)
			/////////////////////////version checking processes////////////////////progress:0%
			let SystemVersionPlistPath = "\(lazypath)/System/Library/CoreServices/SystemVersion.plist"
			let myDict = NSDictionary(contentsOfFile: SystemVersionPlistPath)
			let SystemVersion = myDict?.valueForKey("ProductVersion") as! String
			let SystemVersionBiggerThanElCapitan = "10.11.1".versionToInt().lexicographicalCompare(SystemVersion.versionToInt())
			let SystemVersionBiggerThanSierra = "10.11.99".versionToInt().lexicographicalCompare(SystemVersion.versionToInt())
			////////////////////////////patching processes////////////////////////progress:6%
			if MBRPatchState {
				if SystemVersionBiggerThanSierra {
					self.shellCommand("/bin/sh",arg: ["-c","perl -pi -e 's|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x0F\\x84\\x96\\x00\\x00\\x00\\x48|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\xE9\\x97\\x00\\x00\\x00\\x90\\x48|g' \(lazypath)/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], label: "#Patch osinstaller#",progress: 1)
				}else {
					self.shellCommand("/bin/sh",arg: ["-c","perl -pi -e 's|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x74\\x5F\\x48\\x8B\\x85|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\xEB\\x5F\\x48\\x8B\\x85|g' \(lazypath)/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], label: "#Patch osinstaller#",progress: 1)
				}
				self.privilegedShellCommand("/usr/bin/codesign",arg: ["-f","-s","-","\(lazypath)/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], label: "#Patch osinstaller#",progress: 1)
				
				self.shellCommand("/bin/mkdir",arg: ["/tmp/com.pcbeta.lazy/osinstallmpkg"], label: "#Patch osinstall.mpkg#", progress: 0)
				self.shellCommand("/usr/bin/xar",arg: ["-x","-f","\(lazypath)/System/Installation/Packages/OSInstall.mpkg","-C","/tmp/com.pcbeta.lazy/osinstallmpkg"], label: "#Patch osinstall.mpkg#", progress: 0)
				if !SystemVersionBiggerThanSierra {
					self.shellCommand("/usr/bin/sed",arg: ["-i","\'\'","--","s/1024/512/g","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], label: "#Patch osinstall.mpkg#", progress: 0)
					self.shellCommand("/usr/bin/sed",arg: ["-i","\'\'","--","s/var minRam = 2048/var minRam = 1024/g","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], label: "#Patch osinstall.mpkg#", progress: 0)
					self.shellCommand("/usr/bin/sed",arg: ["-i","\'\'","--","s/osVersion=......... osBuildVersion=.......//g","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], label: "#Patch osinstall.mpkg#", progress: 0)
					self.shellCommand("/usr/bin/sed",arg: ["-i","\'\'","--","/\\<installation-check script=\"installCheckScript()\"\\/>/d","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], label: "#Patch osinstall.mpkg#", progress: 0)
					self.shellCommand("/usr/bin/sed",arg: ["-i","\'\'","--","/\\<volume-check script=\"volCheckScript()\"\\/>/d","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], label: "#Patch osinstall.mpkg#", progress: 0)
				}else {
					self.shellCommand("/usr/bin/sed",arg: ["-i","\'\'","--","/\\<installation-check script=\"InstallationCheck()\"\\/>/d","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], label: "#Patch osinstall.mpkg#", progress: 0)
					self.shellCommand("/usr/bin/sed",arg: ["-i","\'\'","--","/\\<volume-check script=\"VolumeCheck()\"\\/>/d","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], label: "#Patch osinstall.mpkg#", progress: 0)
				}
				self.shellCommand("/bin/rm",arg: ["\(lazypath)/System/Installation/Packages/OSInstall.mpkg"], label: "#Patch osinstall.mpkg#", progress: 0)
				self.shellCommand("/bin/rm",arg: ["/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution\'\'"], label: "#Patch osinstall.mpkg#", progress: 0)
				let task = NSTask()
				task.launchPath = "/usr/bin/xar"
				task.arguments = ["-cf","\(lazypath)/System/Installation/Packages/OSInstall.mpkg","."]
				task.currentDirectoryPath = "/tmp/com.pcbeta.lazy/osinstallmpkg"
				task.launch()
				task.waitUntilExit()
				
			}else {
				self.viewDelegate.didReceiveProgress(2)
			}
			if dropKernelState {
				let task = NSTask()
				task.launchPath = NSBundle.mainBundle().pathForResource("lzvn", ofType: nil)!
				task.arguments = ["-d","\(lazypath)/System/Library/PrelinkedKernels/prelinkedkernel","kernel"]
				task.currentDirectoryPath = "/tmp/com.pcbeta.lazy/"
				task.launch()
				task.waitUntilExit()
				self.shellCommand("/bin/cp",arg: ["/tmp/com.pcbeta.lazy/kernel","\(lazypath)/System/Library/Kernels"], label: "#COPYKERNELF#", progress: 1)
			}else {
				self.viewDelegate.didReceiveProgress(1)
			}
            
            /*
             * The new features that the coder came up with:
             * 1. Kernel Local APIC fix.
             * 2. Extra kexts loading fix for Chameleon.
             * To be updated. 07/02/2016
             */
            
			if XCPMPatchState {
				if !SystemVersionBiggerThanSierra {
					self.shellCommand("/bin/sh",arg: ["-c","perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x02\\x00\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(lazypath)/System/Library/Kernels/kernel"], label: "#XCPMPATCH#",progress: 0)
				}
				self.shellCommand("/bin/sh",arg: ["-c","perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x4c\\x00\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(lazypath)/System/Library/Kernels/kernel"], label: "#XCPMPATCH#",progress: 0)
				if !SystemVersionBiggerThanElCapitan {
					self.shellCommand("/bin/sh",arg: ["-c","perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x90\\x01\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(lazypath)/System/Library/Kernels/kernel"], label: "#XCPMPATCH#",progress: 1)
				}else if SystemVersionBiggerThanSierra {
					self.shellCommand("/bin/sh",arg: ["-c","perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x90\\x33\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(lazypath)/System/Library/Kernels/kernel"], label: "#XCPMPATCH#",progress: 1)
				}else{
					self.shellCommand("/bin/sh",arg: ["-c","perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x90\\x13\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(lazypath)/System/Library/Kernels/kernel"], label: "#XCPMPATCH#",progress: 1)
				}
			}else {
				self.viewDelegate.didReceiveProgress(1)
			}
			self.shellCommand("/bin/cp",arg: ["-R",extraDroppedFilePath,"\(lazypath)/"], label: "#COPYEXTRA#", progress: 2)
			////////////////////////////ejecting processes////////////////////////progress:9%
			if cdrState {
				self.shellCommand("/usr/bin/hdiutil",arg: ["detach",lazypath], label: "#EJECTLAZY#", progress: 1)
				self.shellCommand("/usr/bin/hdiutil",arg: ["detach","\(esdpath)"], label: "#EJECTESD#", progress: 1)
				self.shellCommand("/usr/bin/hdiutil",arg: ["convert","/tmp/com.pcbeta.lazy/Lazy Installer.dmg","-ov","-format","UDTO","-o","/tmp/com.pcbeta.lazy/Lazy Installer.cdr"], label: "#Create CDR#", progress: 7)
				self.shellCommand("/bin/mv",arg: ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/"], label: "#MV#", progress: 0)
				self.shellCommand("/bin/mv",arg: ["/tmp/com.pcbeta.lazy/Lazy Installer.cdr","\(NSHomeDirectory())/Desktop/"], label: "#MV#", progress: 0)
			}else{
				self.shellCommand("/usr/bin/hdiutil",arg: ["detach","\(esdpath)"], label: "#EJECTESD#", progress: 2)
				self.shellCommand("/usr/bin/hdiutil",arg: ["detach",lazypath], label: "#EJECTLAZY#", progress: 2)
				self.shellCommand("/bin/mv",arg: ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/"], label: "#MV#", progress: 3)
			}
			self.shellCommand("/bin/rm",arg: ["-rf","/tmp/com.pcbeta.lazy"], label: "#MV#", progress: 0)
			self.viewDelegate.didReceiveProcessName("#FINISH#")
			self.viewDelegate.didReceiveThreadExitMessage()
		})
	}
}