//
//  shellCommand.swift
//  LazyHackintoshGenerator
//
//  Created by ئ‍ارسلان ئابلىكىم on 2/8/16.
//  Copyright © 2016 PCBETA. All rights reserved.
//

import Foundation
func shellCommand(path:String, arg: [String],label: String,progress: Double)->String{
    let task = NSTask()
    task.launchPath = path
    task.arguments = arg
    let pipe = NSPipe()
    task.standardOutput = pipe
    task.launch()
    progressLable.stringValue = label.localized(self.language!)
    task.waitUntilExit()
    progress.incrementBy(progress)
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
    progress.incrementBy(progress)
}