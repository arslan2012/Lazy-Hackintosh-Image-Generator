//
//  BatchProcessAPI.swift
//  LazyHackintoshGenerator
//
//  Created by ئ‍ارسلان ئابلىكىم on 4/18/16.
//  Copyright © 2016 PCBETA. All rights reserved.
//

import Foundation
protocol BatchProcessAPIProtocol {
	func didReceiveProcessName(results: String)
	func didReceiveProgress(results: Double)
	func didReceiveErrorMessage(results: String)
}

class BatchProcessAPI{
	var delegate: BatchProcessAPIProtocol
	init(delegate: BatchProcessAPIProtocol) {
		self.delegate = delegate
	}
	func shellCommand(path:String, arg: [String],label: String,progress: Double)->String{
		let task = NSTask()
		task.launchPath = path
		task.arguments = arg
		let pipe = NSPipe()
		task.standardOutput = pipe
		task.launch()
		self.delegate.didReceiveProcessName(label)
		task.waitUntilExit()
		self.delegate.didReceiveProgress(progress)
		let data = pipe.fileHandleForReading.readDataToEndOfFile()
		let output: String = String(data: data, encoding: NSUTF8StringEncoding)!
		return output
	}
	func privilegedShellCommand(path:String, arg: [String],label: String,progress: Double){
		let task = STPrivilegedTask()
		task.setLaunchPath(path)
		task.setArguments(arg)
		task.launch()
		self.delegate.didReceiveProcessName(label)
		task.waitUntilExit()
		self.delegate.didReceiveProgress(progress)
	}
	func startGenerating(filePath:String,SizeVal:String,MBRPatchState:Bool,XCPMPatchState:Bool,cdrState:Bool,kernelDroppedFilePath:String,extraDroppedFilePath:String){
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),{
			////////////////////////////mounting processes////////////////////////
			self.shellCommand("/usr/bin/hdiutil",arg: ["attach",filePath,"-noverify"], label: "#MOUNTORG#", progress: 2)
			self.shellCommand("/usr/bin/hdiutil",arg: ["attach",filePath + "/Contents/SharedSupport/InstallESD.dmg","-noverify"], label: "#MOUNTESD#", progress: 0)
			let fileManager = NSFileManager.defaultManager()
			var esdpath = "",apppath = ""
			do{
				let enumerator = try fileManager.contentsOfDirectoryAtPath("/Volumes")
				for element in enumerator {
					if element.hasPrefix("Install OS X"){
						esdpath = element
						if NSURL(fileURLWithPath:"/Volumes/"+esdpath).checkResourceIsReachableAndReturnError(nil){
							break
						}
					}
				}
			}
			catch{
				
			}
			if esdpath != "" {
				do{
					let enumerator = try fileManager.contentsOfDirectoryAtPath("/Volumes/"+esdpath)
					for element in enumerator {
						if element.hasPrefix("Install OS "){
							apppath = element
							if NSURL(fileURLWithPath:"/Volumes/"+esdpath+"/"+apppath+"/Contents/SharedSupport/InstallESD.dmg").checkResourceIsReachableAndReturnError(nil){
								break
							}
						}
					}
				}
				catch{
					
				}
				self.shellCommand("/usr/bin/hdiutil",arg: ["attach","/Volumes/"+esdpath+"/"+apppath+"/Contents/SharedSupport/InstallESD.dmg","-noverify"], label: "#MOUNTESD#", progress: 0)
			}
			do{
				let enumerator = try fileManager.contentsOfDirectoryAtPath("/Volumes")
				for element in enumerator {
					if element.hasPrefix("OS X Install ESD"){
						esdpath = element
						if NSURL(fileURLWithPath:"/Volumes/"+esdpath+"/BaseSystem.dmg").checkResourceIsReachableAndReturnError(nil){
							break
						}
					}
				}
			}
			catch{
				self.delegate.didReceiveErrorMessage("#ESDFAILURE#")
			}
			if esdpath == "" {
				self.delegate.didReceiveErrorMessage("#ESDFAILURE#")
			}
			self.shellCommand("/usr/bin/hdiutil",arg: ["attach","/Volumes/"+esdpath+"/BaseSystem.dmg","-noverify"], label: "#MOUNTESD#", progress: 2)
			self.shellCommand("/bin/mkdir",arg: ["/tmp/com.pcbeta.lazy"], label: "#CREATE#", progress: 0)
			self.shellCommand("/usr/bin/hdiutil",arg: ["create","-size",SizeVal+"g","-layout","SPUD","-ov","-fs","HFS+J","-volname","OS X Lazy Installer","/tmp/com.pcbeta.lazy/Lazy Installer.dmg"], label: "#CREATE#", progress: 20)
			self.shellCommand("/usr/bin/hdiutil",arg: ["attach","/tmp/com.pcbeta.lazy/Lazy Installer.dmg"], label: "#MOUNTLAZY#", progress: 2)
			var lazypath = ""
			do{
				let enumerator = try fileManager.contentsOfDirectoryAtPath("/Volumes")
				for element in enumerator {
					if element.hasPrefix("OS X Lazy Installer"){
						lazypath = element
						if NSURL(fileURLWithPath:"/Volumes/"+lazypath).checkResourceIsReachableAndReturnError(nil){
							break
						}
					}
				}
			}
			catch{
				self.delegate.didReceiveErrorMessage("#LAZYFAILURE#")
			}
			if lazypath == ""{
				self.delegate.didReceiveErrorMessage("#LAZYFAILURE#")
			}
			var basepath = ""
			do{
				let enumerator = try fileManager.contentsOfDirectoryAtPath("/Volumes")
				for element in enumerator {
					if element.hasPrefix("OS X Base System"){
						basepath = element
						if NSURL(fileURLWithPath:"/Volumes/"+basepath).checkResourceIsReachableAndReturnError(nil){
							break
						}
					}
				}
			}
			catch{
				self.delegate.didReceiveErrorMessage("#BASEFAILURE#")
			}
			if basepath == ""{
				self.delegate.didReceiveErrorMessage("#BASEFAILURE#")
			}
			////////////////////////////copying processes/////////////////////////
			self.privilegedShellCommand("/usr/sbin/asr",arg: ["restore","-source","/Volumes/"+basepath+"/","-target","/Volumes/"+lazypath,"-erase","-format","HFS+","-noprompt"], label: "#COPYBASE#",progress: 22)
			self.privilegedShellCommand("/usr/sbin/diskutil",arg: ["rename","OS X Base System",lazypath], label: "#COPYBASE#",progress: 0)
			self.shellCommand("/bin/cp",arg: ["/Volumes/"+esdpath+"/BaseSystem.chunklist","/Volumes/"+lazypath], label: "#COPYESD#", progress: 2)
			self.shellCommand("/bin/cp",arg: ["/Volumes/"+esdpath+"/BaseSystem.dmg","/Volumes/"+lazypath], label: "#COPYESD#", progress: 2)
			self.shellCommand("/bin/cp",arg: ["/Volumes/"+esdpath+"/AppleDiagnostics.chunklist","/Volumes/"+lazypath], label: "#COPYESD#", progress: 2)
			self.shellCommand("/bin/cp",arg: ["/Volumes/"+esdpath+"/AppleDiagnostics.dmg","/Volumes/"+lazypath], label: "#COPYESD#", progress: 2)
			self.shellCommand("/bin/rm",arg: ["-rf","/Volumes/"+lazypath+"/System/Installation/Packages"], label: "#DELETEPACKAGE#", progress: 2)
			self.privilegedShellCommand("/bin/cp",arg: ["-R","/Volumes/"+esdpath+"/Packages","/Volumes/"+lazypath+"/System/Installation"], label: "#COPYPACKAGE#",progress: 22)
			self.shellCommand("/bin/mkdir",arg: ["/Volumes/"+lazypath+"/System/Library/Kernels"], label: "#CREATEKERNELSF#", progress: 0)
			self.shellCommand("/bin/mkdir",arg: ["/tmp/com.pcbeta.lazy/kernel"], label: "#COPYKERNEL#", progress: 2)
			self.shellCommand("/usr/bin/xar",arg: ["-x","-f","/Volumes/"+lazypath+"/System/Installation/Packages/Essentials.pkg","-C","/tmp/com.pcbeta.lazy/kernel"], label: "#COPYKERNEL#", progress: 4)
			self.shellCommand("/bin/cp",arg: ["-R","/tmp/com.pcbeta.lazy/kernel/KerberosPlugins","/Volumes/"+lazypath+"/System/Library/"], label: "#COPYKERNEL#", progress: 2)
			self.shellCommand("/bin/cp",arg: ["-R","/tmp/com.pcbeta.lazy/kernel/Kernels","/Volumes/"+lazypath+"/System/Library/"], label: "#COPYKERNEL#", progress: 2)
			////////////////////////////patching processes////////////////////////
			if MBRPatchState {
				self.privilegedShellCommand("/usr/bin/perl",arg: ["-pi","-e","\'s|x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x74\\x5F\\x48\\x8B\\x85|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\xEB\\x5F\\x48\\x8B\\x85|g\'","/Volumes/"+lazypath+"/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], label: "#PATCH01#",progress: 1)
				self.privilegedShellCommand("/usr/bin/codesign",arg: ["-f","-s","-","/Volumes/"+lazypath+"/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], label: "#PATCH01#",progress: 1)
				
				self.shellCommand("/bin/mkdir",arg: ["/tmp/com.pcbeta.lazy/osinstallmpkg"], label: "#PATCH02#", progress: 0)
				self.shellCommand("/usr/bin/xar",arg: ["-x","-f","/Volumes/"+lazypath+"/System/Installation/Packages/OSInstall.mpkg","-C","/tmp/com.pcbeta.lazy/osinstallmpkg"], label: "#PATCH02#", progress: 0)
				self.shellCommand("/usr/bin/sed",arg: ["-i","\'\'","--","s/1024/512/g","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], label: "#PATCH02#", progress: 0)
				self.shellCommand("/usr/bin/sed",arg: ["-i","\'\'","--","s/var minRam = 2048/var minRam = 1024/g","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], label: "#PATCH02#", progress: 0)
				self.shellCommand("/usr/bin/sed",arg: ["-i","\'\'","--","/\\<installation-check script=\"installCheckScript()\"\\/>/d","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], label: "#PATCH02#", progress: 0)
				self.shellCommand("/usr/bin/sed",arg: ["-i","\'\'","--","/\\<volume-check script=\"volCheckScript()\"\\/>/d","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], label: "#PATCH02#", progress: 0)
				self.shellCommand("/usr/bin/sed",arg: ["-i","\'\'","--","s/osVersion=......... osBuildVersion=.......//g","/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution"], label: "#PATCH02#", progress: 0)
				self.shellCommand("/bin/rm",arg: ["/Volumes/"+lazypath+"/System/Installation/Packages/OSInstall.mpkg"], label: "#PATCH02#", progress: 0)
				self.shellCommand("/bin/rm",arg: ["/tmp/com.pcbeta.lazy/osinstallmpkg/Distribution\'\'"], label: "#PATCH02#", progress: 0)
				let task = NSTask()
				task.launchPath = "/usr/bin/xar"
				task.arguments = ["-cf","/Volumes/"+lazypath+"/System/Installation/Packages/OSInstall.mpkg","."]
				task.currentDirectoryPath = "/tmp/com.pcbeta.lazy/osinstallmpkg"
				task.launch()
				task.waitUntilExit()
				
			}else {
				self.delegate.didReceiveProgress(2)
			}
			if XCPMPatchState {
				self.shellCommand("/bin/cp",arg: [kernelDroppedFilePath,"/Volumes/"+lazypath+"/System/Library/Kernels"], label: "#COPYKERNEL#", progress: 1)
				self.shellCommand("/usr/bin/perl",arg: ["-pi","-e","\'s|\\xe2\\x00\\x00\\x00\\x02\\x00\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g\'","/Volumes/"+lazypath+"/System/Library/Kernels/kernel"], label: "#XCPMPATCH#",progress: 0)
				self.shellCommand("/usr/bin/perl",arg: ["-pi","-e","\'s|\\xe2\\x00\\x00\\x00\\x4c\\x00\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g\'","/Volumes/"+lazypath+"/System/Library/Kernels/kernel"], label: "#XCPMPATCH#",progress: 0)
				self.shellCommand("/usr/bin/perl",arg: ["-pi","-e","\'s|\\xe2\\x00\\x00\\x00\\x90\\x01\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g\'","/Volumes/"+lazypath+"/System/Library/Kernels/kernel"], label: "#XCPMPATCH#",progress: 1)
			}else {
				self.shellCommand("/bin/cp",arg: [kernelDroppedFilePath,"/Volumes/"+lazypath+"/System/Library/Kernels"], label: "#COPYKERNEL#", progress: 2)
			}
			self.shellCommand("/bin/cp",arg: ["-R",extraDroppedFilePath,"/Volumes/"+lazypath+"/"], label: "#COPYEXTRA#", progress: 2)
			////////////////////////////ejecting processes////////////////////////
			if cdrState {
				self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+lazypath], label: "#EJECTLAZY#", progress: 0)
				self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+basepath], label: "#EJECTBASE#", progress: 1)
				self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+esdpath], label: "#EJECTESD#", progress: 1)
				self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/Install OS X El Capitan"], label: "#EJECTORG#", progress: 0)
				self.shellCommand("/usr/bin/hdiutil",arg: ["convert","/tmp/com.pcbeta.lazy/Lazy Installer.dmg","-ov","-format","UDTO","-o","/tmp/com.pcbeta.lazy/Lazy Installer.cdr"], label: "#CREATECDR#", progress: 2)
				self.shellCommand("/bin/mv",arg: ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/"], label: "#MV#", progress: 0)
				self.shellCommand("/bin/mv",arg: ["/tmp/com.pcbeta.lazy/Lazy Installer.cdr","\(NSHomeDirectory())/Desktop/"], label: "#MV#", progress: 0)
			}else{
				self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+basepath], label: "#EJECTBASE#", progress: 2)
				self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+esdpath], label: "#EJECTESD#", progress: 2)
				self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/Install OS X El Capitan"], label: "#EJECTORG#", progress: 0)
				self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+lazypath], label: "#EJECTLAZY#", progress: 0)
				self.shellCommand("/bin/mv",arg: ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/"], label: "#MV#", progress: 0)
			}
			self.shellCommand("/bin/rm",arg: ["-rf","/tmp/com.pcbeta.lazy"], label: "#MV#", progress: 0)
			self.delegate.didReceiveProcessName("#FINISH#")
		})
	}
}