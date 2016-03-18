//
//  ViewController.swift
//  LazyHackintoshGenerator
//
//  Created by ئ‍ارسلان ئابلىكىم on 2/5/16.
//  Copyright © 2016 PCBETA. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var filePath: NSTextField!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var progressLable: NSTextField!
    @IBOutlet weak var kernel: OtherFileDrop!
    @IBOutlet weak var start: NSButton!
    @IBOutlet weak var MBRPatch: NSButton!
    @IBOutlet weak var XCPMPatch: NSButton!
    @IBOutlet weak var cdr: NSButton!
    @IBOutlet weak var extra: OtherFileDrop!
    var language: String?
    let concurrentInsertingQueue = dispatch_queue_create("kext inserting", DISPATCH_QUEUE_CONCURRENT)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.language = NSLocale.preferredLanguages()[0]
        if self.language != "zh-Hans" || self.language != "en" {
            self.language = "en"
        }
        progress.hidden = true
        progressLable.hidden = true
        XCPMPatch.state = NSOffState
        cdr.state = NSOffState
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window!.title = "#TITLE#".localized(self.language!)
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    @IBAction func StartProcessing(sender: NSButton) {
        if NSURL(fileURLWithPath:filePath.stringValue).checkResourceIsReachableAndReturnError(nil){
            startGenerating()
        }else{
            let a = NSAlert()
            a.messageText = "#INPUTVOID#".localized(self.language!)
            a.runModal()
        }
//        do {
//            try NSURL(fileURLWithPath:filePath.stringValue).checkResourceIsReachableAndReturnError(nil)
//        }catch{
//                        let a = NSAlert()
//                        a.messageText = "#INPUTVOID#".localized(self.language!)
//                        a.runModal()
//        }
    }
    @IBAction func XCPMClicked(sender: NSButton) {
        if XCPMPatch.state == NSOnState {
            if kernel.droppedFilePath == "" {
                let a = NSAlert()
                a.messageText = "#NOKERNEL#".localized(self.language!)
                a.runModal()
                XCPMPatch.state = NSOffState
            }
        }
    }
    func shellCommand(path:String, arg: [String],label: String,progress: Double)->String{
        let task = NSTask()
        task.launchPath = path
        task.arguments = arg
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        dispatch_sync(self.concurrentInsertingQueue,{
            self.progressLable.stringValue = label.localized(self.language!)
        })
        task.waitUntilExit()
        dispatch_sync(self.concurrentInsertingQueue,{
            self.progress.incrementBy(progress)
        })
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = String(data: data, encoding: NSUTF8StringEncoding)!
        return output
    }
    func privilegedShellCommand(path:String, arg: [String],label: String,progress: Double){
        let task = STPrivilegedTask()
        task.setLaunchPath(path)
        task.setArguments(arg)
        task.launch()
        dispatch_sync(self.concurrentInsertingQueue,{
            self.progressLable.stringValue = label.localized(self.language!)
        })
        task.waitUntilExit()
        dispatch_sync(self.concurrentInsertingQueue,{
            self.progress.incrementBy(progress)
        })
    }
    func startGenerating(){
        start.enabled = false
        progress.hidden = false
        progressLable.hidden = false
        progress.startAnimation(self)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),{
            ////////////////////////////mounting processes////////////////////////
            self.shellCommand("/usr/bin/hdiutil",arg: ["attach",self.filePath.stringValue,"-noverify"], label: "#MOUNTORG#", progress: 2)
            self.shellCommand("/usr/bin/hdiutil",arg: ["attach",self.filePath.stringValue + "/Contents/SharedSupport/InstallESD.dmg","-noverify"], label: "#MOUNTESD#", progress: 0)
            let fileManager = NSFileManager.defaultManager()
            var esdpath = ""
            do{
                let enumerator = try fileManager.contentsOfDirectoryAtPath("/Volumes")
                for element in enumerator {
                    if element.hasPrefix("Install OS X"){
                        esdpath = element
                    }
                }
            }
            catch{
                
            }
            self.shellCommand("/usr/bin/hdiutil",arg: ["attach","/Volumes/"+esdpath+"/Install OS X El Capitan.app/Contents/SharedSupport/InstallESD.dmg","-noverify"], label: "#MOUNTESD#", progress: 0)
            do{
                let enumerator = try fileManager.contentsOfDirectoryAtPath("/Volumes")
                for element in enumerator {
                    if element.hasPrefix("OS X Install ESD"){
                        esdpath = element
                    }
                }
            }
            catch{
                let a = NSAlert()
                a.messageText = "#ESDFAILURE#".localized(self.language!)
                a.runModal()
                exit(0)
            }
            if esdpath == "" {
                let b = NSAlert()
                b.messageText = "#ESDFAILURE#".localized(self.language!)
                b.runModal()
                exit(0)
            }
            self.shellCommand("/usr/bin/hdiutil",arg: ["attach","/Volumes/"+esdpath+"/BaseSystem.dmg","-noverify"], label: "#MOUNTESD#", progress: 2)
            self.shellCommand("/bin/mkdir",arg: ["/tmp/com.pcbeta.lazy"], label: "#CREATE#", progress: 0)
            self.shellCommand("/usr/bin/hdiutil",arg: ["create","-megabytes","7650","-layout","SPUD","-fs","HFS+J","-volname","OS X El Capitan Lazy Installer","/tmp/com.pcbeta.lazy/Lazy Installer.dmg"], label: "#CREATE#", progress: 20)
            self.shellCommand("/usr/bin/hdiutil",arg: ["attach","/tmp/com.pcbeta.lazy/Lazy Installer.dmg"], label: "#MOUNTLAZY#", progress: 2)
            var lazypath = ""
            do{
                let enumerator = try fileManager.contentsOfDirectoryAtPath("/Volumes")
                for element in enumerator {
                    if element.hasPrefix("OS X El Capitan Lazy Installer"){
                        lazypath = element
                    }
                }
            }
            catch{
                let a = NSAlert()
                a.messageText = "#LAZYFAILURE#".localized(self.language!)
                a.runModal()
                exit(0)
            }
            if lazypath == ""{
                let b = NSAlert()
                b.messageText = "#LAZYFAILURE#".localized(self.language!)
                b.runModal()
                exit(0)
            }
            var basepath = ""
            do{
                let enumerator = try fileManager.contentsOfDirectoryAtPath("/Volumes")
                for element in enumerator {
                    if element.hasPrefix("OS X Base System"){
                        basepath = element
                    }
                }
            }
            catch{
                let a = NSAlert()
                a.messageText = "#BASEFAILURE#".localized(self.language!)
                a.runModal()
                exit(0)
            }
            if basepath == ""{
                let b = NSAlert()
                b.messageText = "#BASEFAILURE#".localized(self.language!)
                b.runModal()
                exit(0)
            }
            ////////////////////////////copying processes/////////////////////////
            self.privilegedShellCommand("/bin/cp",arg: ["-R","/Volumes/"+basepath+"/","/Volumes/"+lazypath], label: "#COPYBASE#",progress: 22)
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
            if self.MBRPatch.state == NSOnState {
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
                dispatch_sync(self.concurrentInsertingQueue,{
                    self.progress.incrementBy(2)
                })
            }
            if self.XCPMPatch.state == NSOnState {
                self.shellCommand("/bin/cp",arg: [self.kernel.droppedFilePath,"/Volumes/"+lazypath+"/System/Library/Kernels"], label: "#COPYKERNEL#", progress: 1)
                self.shellCommand("/usr/bin/perl",arg: ["-pi","-e","\'s|\\xe2\\x00\\x00\\x00\\x02\\x00\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g\'","/Volumes/"+lazypath+"/System/Library/Kernels/kernel"], label: "#XCPMPATCH#",progress: 0)
                self.shellCommand("/usr/bin/perl",arg: ["-pi","-e","\'s|\\xe2\\x00\\x00\\x00\\x4c\\x00\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g\'","/Volumes/"+lazypath+"/System/Library/Kernels/kernel"], label: "#XCPMPATCH#",progress: 0)
                self.shellCommand("/usr/bin/perl",arg: ["-pi","-e","\'s|\\xe2\\x00\\x00\\x00\\x90\\x01\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g\'","/Volumes/"+lazypath+"/System/Library/Kernels/kernel"], label: "#XCPMPATCH#",progress: 1)
            }else {
                self.shellCommand("/bin/cp",arg: [self.kernel.droppedFilePath,"/Volumes/"+lazypath+"/System/Library/Kernels"], label: "#COPYKERNEL#", progress: 2)
            }
            self.shellCommand("/bin/cp",arg: ["-R",self.extra.droppedFilePath,"/Volumes/"+lazypath+"/"], label: "#COPYEXTRA#", progress: 2)
            ////////////////////////////ejecting processes////////////////////////
            if self.cdr.state == NSOnState {
                self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+lazypath], label: "#EJECTLAZY#", progress: 0)
                self.shellCommand("/usr/bin/hdiutil",arg: ["convert","/tmp/com.pcbeta.lazy/Lazy Installer.dmg","-format","UDTO","-o","/tmp/com.pcbeta.lazy/Lazy Installer.cdr"], label: "#CREATECDR#", progress: 2)
                self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+basepath], label: "#EJECTBASE#", progress: 1)
                self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+esdpath], label: "#EJECTESD#", progress: 1)
                self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/Install OS X El Capitan"], label: "#EJECTORG#", progress: 0)
                self.shellCommand("/bin/mv",arg: ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/"], label: "#MV#", progress: 0)
                self.shellCommand("/bin/mv",arg: ["/tmp/com.pcbeta.lazy/Lazy Installer.cdr","\(NSHomeDirectory())/Desktop/"], label: "#MV#", progress: 0)
            }else{
                self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+basepath], label: "#EJECTBASE#", progress: 2)
                self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+esdpath], label: "#EJECTESD#", progress: 2)
                self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/Install OS X El Capitan"], label: "#EJECTORG#", progress: 0)
                self.shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+lazypath], label: "#EJECTLAZY#", progress: 0)
                self.shellCommand("/bin/mv",arg: ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg","\(NSHomeDirectory())/Desktop/"], label: "#MV#", progress: 0)
            }
            self.shellCommand("/bin/rm",arg: ["-rf","/tmp/com.pcbeta.lazy"], label: "MV", progress: 0)
            self.progress.stopAnimation(self)
            self.progressLable.stringValue = "#FINISH#".localized(self.language!)
            self.filePath.stringValue = ""
            self.start.enabled = true
        })
    }
    
    
}

