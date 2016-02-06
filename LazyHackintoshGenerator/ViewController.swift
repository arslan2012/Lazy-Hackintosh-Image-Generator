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
        //self.view.window.title = "懒人镜像制作器";

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    @IBAction func StartProcessing(sender: NSButton) {
        if filePath != ""{
            startGenerating()
        }else{
            let a = NSAlert()
            a.messageText = "未设置镜像！"
            a.runModal()
        }
    }
    func shellCommand(path:String, arg: [String],label: String,progress: Double)->String{
        let task = NSTask()
        task.launchPath = path
        task.arguments = arg
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        progressLable.stringValue = label
        task.waitUntilExit()
        self.progress.incrementBy(progress)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = String(data: data, encoding: NSUTF8StringEncoding)!
        return output
    }
    func privilegedShellCommand(path:String, arg: [String],progress: Double){
        let task = STPrivilegedTask()
        task.setLaunchPath(path)
        task.setArguments(arg)
        task.launch()
        task.waitUntilExit()
        self.progress.incrementBy(progress)
    }
    func startGenerating(){
        progress.hidden = false
        progressLable.hidden = false
        progress.startAnimation(self)
        shellCommand("/usr/bin/hdiutil",arg: ["attach",filePath.stringValue,"-noverify"], label: "挂载镜像", progress: 2)
        shellCommand("/usr/bin/hdiutil",arg: ["attach",filePath.stringValue + "/Contents/SharedSupport/InstallESD.dmg","-noverify"], label: "挂载ESD镜像", progress: 0)
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
        shellCommand("/usr/bin/hdiutil",arg: ["attach","/Volumes/"+esdpath+"/Install OS X El Capitan.app/Contents/SharedSupport/InstallESD.dmg","-noverify"], label: "挂载ESD镜像", progress: 0)
        do{
            let enumerator = try fileManager.contentsOfDirectoryAtPath("/Volumes")
            for element in enumerator {
                if element.hasPrefix("OS X Install ESD"){
                    esdpath = element
                }
            }
            if esdpath == "" {
                let a = NSAlert()
                a.messageText = "对不起未找到ESD镜像挂载点"
                a.runModal()
                exit(0)
            }
        }
        catch{
            let a = NSAlert()
            a.messageText = "对不起未找到ESD镜像挂载点"
            a.runModal()
            exit(0)
        }
        shellCommand("/usr/bin/hdiutil",arg: ["attach","/Volumes/"+esdpath+"/BaseSystem.dmg","-noverify"], label: "挂载ESD镜像", progress: 2)
        shellCommand("/usr/bin/hdiutil",arg: ["create","-megabytes","7650","-layout","SPUD","-fs","HFS+J","-volname","OS X El Capitan Lazy Installer","\(NSHomeDirectory())/Desktop/Lazy Installer.dmg"], label: "正在创建镜像，请稍候...", progress: 20)
        shellCommand("/usr/bin/hdiutil",arg: ["attach","\(NSHomeDirectory())/Desktop/Lazy Installer.dmg"], label: "挂载生成的镜像", progress: 2)
        progressLable.stringValue = "复制Base System文件"
        var basepath = ""
        do{
            let enumerator = try fileManager.contentsOfDirectoryAtPath("/Volumes")
            for element in enumerator {
                if element.hasPrefix("OS X Base System"){
                    basepath = element
                }
            }
            if basepath == ""{
                let a = NSAlert()
                a.messageText = "对不起未找到Base System镜像挂载点"
                a.runModal()
                exit(0)
            }
        }
        catch{
            let a = NSAlert()
            a.messageText = "对不起未找到Base System镜像挂载点"
            a.runModal()
            exit(0)
        }
        privilegedShellCommand("/bin/cp",arg: ["-R","/Volumes/"+basepath+"/","/Volumes/OS X El Capitan Lazy Installer"], progress: 32)
        shellCommand("/bin/cp",arg: ["/Volumes/"+esdpath+"/BaseSystem.chunklist","/Volumes/OS X El Capitan Lazy Installer"], label: "复制Install ESD文件", progress: 2)
        shellCommand("/bin/cp",arg: ["/Volumes/"+esdpath+"/BaseSystem.dmg","/Volumes/OS X El Capitan Lazy Installer"], label: "复制Install ESD文件", progress: 2)
        shellCommand("/bin/cp",arg: ["/Volumes/"+esdpath+"/AppleDiagnostics.chunklist","/Volumes/OS X El Capitan Lazy Installer"], label: "复制Install ESD文件", progress: 2)
        shellCommand("/bin/cp",arg: ["/Volumes/"+esdpath+"/AppleDiagnostics.dmg","/Volumes/OS X El Capitan Lazy Installer"], label: "复制Install ESD文件", progress: 2)
        shellCommand("/bin/rm",arg: ["-rf","/Volumes/OS X El Capitan Lazy Installer/System/Installation/Packages"], label: "删除Packages文件夹", progress: 2)
        progressLable.stringValue = "复制Packages文件夹到S/I"
        privilegedShellCommand("/bin/cp",arg: ["-R","/Volumes/"+esdpath+"/Packages","/Volumes/OS X El Capitan Lazy Installer/System/Installation"], progress: 20)
        shellCommand("/bin/mkdir",arg: ["/Volumes/OS X El Capitan Lazy Installer/System/Library/Kernels"], label: "创建kernels文件夹", progress: 0)
        shellCommand("/bin/cp",arg: [OSInstaller.droppedFilePath,"/Volumes/OS X El Capitan Lazy Installer/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A"], label: "复制OSInstaller文件", progress: 2)
        shellCommand("/bin/cp",arg: [mpkg.droppedFilePath,"/Volumes/OS X El Capitan Lazy Installer/System/Installation/Packages"], label: "复制OSInstall.mpkg文件", progress: 2)
        shellCommand("/bin/cp",arg: [kernel.droppedFilePath,"/Volumes/OS X El Capitan Lazy Installer/System/Library/Kernels"], label: "复制Kernel文件", progress: 2)
        shellCommand("/bin/cp",arg: ["-R",extra.droppedFilePath,"/Volumes/OS X El Capitan Lazy Installer/"], label: "复制Extra文件夹", progress: 2)
        shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+basepath], label: "卸载Base System镜像", progress: 2)
        shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/"+esdpath], label: "卸载ESD镜像", progress: 2)
        shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/Install OS X El Capitan"], label: "卸载镜像", progress: 0)
        shellCommand("/usr/bin/hdiutil",arg: ["detach","/Volumes/OS X El Capitan Lazy Installer"], label: "卸载懒人镜像", progress: 0)
        progress.stopAnimation(self)
        progressLable.stringValue = "已经完成"
    }


}

