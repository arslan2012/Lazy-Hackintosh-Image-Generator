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
    @IBOutlet weak var OSInstaller: OtherFileDrop!
    @IBOutlet weak var mpkg: OtherFileDrop!
    @IBOutlet weak var kernel: OtherFileDrop!
    @IBOutlet weak var extra: OtherFileDrop!

    override func viewDidLoad() {
        super.viewDidLoad()
        progress.hidden = true
        progressLable.hidden = true

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    func shellCommand(path:String, arg: [String],label: String,progress: Double){
        let task = NSTask()
        task.launchPath = path
        task.arguments = arg
        task.launch()
        progressLable.stringValue = label
        task.waitUntilExit()
        self.progress.incrementBy(progress)
        if task.terminationStatus != 0 {
            print("error on " + path + " " + arg[0])
            exit(EXIT_FAILURE)
        }
    }
    func privilegedShellCommand(path:String, arg: [String],label: String,progress: Double){
        let task = STPrivilegedTask()
        task.setLaunchPath(path)
        task.setArguments(arg)
        task.launch()
        progressLable.stringValue = label
        task.waitUntilExit()
        self.progress.incrementBy(progress)
    }
    func startGenerating(){
        progress.hidden = false
        progressLable.hidden = false
        progress.startAnimation(self)
        shellCommand("/usr/bin/hdiutil",arg: ["attach",filePath.stringValue,"-noverify"], label: "挂载镜像", progress: 2)
        shellCommand("/usr/bin/hdiutil",arg: ["attach","/Volumes/Install OS X El Capitan/Install OS X El Capitan.app/Contents/SharedSupport/InstallESD.dmg","-noverify"], label: "挂载ESD镜像", progress: 0)
        shellCommand("/usr/bin/hdiutil",arg: ["attach","/Volumes/OS X Install ESD/BaseSystem.dmg","-noverify"], label: "挂载ESD镜像", progress: 2)
        shellCommand("/usr/bin/hdiutil",arg: ["create","-megabytes","7650","-layout","SPUD","-fs","HFS+J","-volname","OS X El Capitan Lazy Installer","\(NSHomeDirectory())/Desktop/Lazy Installer.dmg"], label: "正在创建镜像，请稍候...", progress: 20)
        shellCommand("/usr/bin/hdiutil",arg: ["attach","\(NSHomeDirectory())/Desktop/Lazy Installer.dmg"], label: "挂载生成的镜像", progress: 2)
        privilegedShellCommand("/bin/cp",arg: ["-R","/Volumes/OS X Base System/","/Volumes/OS X El Capitan Lazy Installer"], label: "复制Base System文件", progress: 20)
        shellCommand("/bin/cp",arg: ["/Volumes/OS X Base System/BaseSystem.chunklist","/Volumes/OS X El Capitan Lazy Installer"], label: "复制Base System文件", progress: 2)
        shellCommand("/bin/cp",arg: ["/Volumes/OS X Base System/BaseSystem.dmg","/Volumes/OS X El Capitan Lazy Installer"], label: "复制Base System文件", progress: 2)
        shellCommand("/bin/cp",arg: ["/Volumes/OS X Base System/AppleDiagnostics.chunklist","/Volumes/OS X El Capitan Lazy Installer"], label: "复制Base System文件", progress: 2)
        shellCommand("/bin/cp",arg: ["/Volumes/OS X Base System/AppleDiagnostics.dmg","/Volumes/OS X El Capitan Lazy Installer"], label: "复制Base System文件", progress: 2)
        shellCommand("/bin/rm",arg: ["-rf","/Volumes/OS X El Capitan Lazy Installer/System/Installation/Packages"], label: "删除Packages文件夹", progress: 2)
        privilegedShellCommand("/bin/cp",arg: ["-R","/Volumes/OS X Install ESD/Packages","/Volumes/OS X El Capitan Lazy Installer/System/Installation"], label: "复制Packages文件夹到S/I", progress: 10)
        shellCommand("/bin/mkdir",arg: ["/Volumes/OS X El Capitan Lazy Installer/System/Library/Kernels"], label: "创建kernels文件夹", progress: 0)
        shellCommand("/bin/cp",arg: [OSInstaller.droppedFilePath,"/Volumes/OS X El Capitan Lazy Installer/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A"], label: "复制OSInstaller文件", progress: 10)
        shellCommand("/bin/cp",arg: [mpkg.droppedFilePath,"/Volumes/OS X El Capitan Lazy Installer/System/Installation/Packages"], label: "复制OSInstall.mpkg文件", progress: 2)
        shellCommand("/bin/cp",arg: [kernel.droppedFilePath,"/Volumes/OS X El Capitan Lazy Installer/System/Library/Kernels"], label: "复制Kernel文件", progress: 2)
        shellCommand("/bin/cp",arg: ["-R",extra.droppedFilePath,"/Volumes/OS X El Capitan Lazy Installer/System/Library/Kernels"], label: "复制Kernel文件", progress: 2)
        shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/OS X Base System"], label: "卸载Base System镜像", progress: 2)
        shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/OS X Install ESD"], label: "卸载ESD镜像", progress: 2)
        shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/Install OS X El Capitan"], label: "卸载镜像", progress: 0)
    }


}

