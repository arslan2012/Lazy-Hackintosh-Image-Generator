//
//  shellCommand.swift
//  LazyHackintoshGenerator
//
//  Created by ئ‍ارسلان ئابلىكىم on 7/27/16.
//  Copyright © 2016 PCBeta. All rights reserved.
//

import Foundation

@discardableResult
func Command(_ path:String,_ arg: [String],_ label: String,_ progress: Double,_ currentDirectoryPath:String = "") -> Int32{
    delegate!.didReceiveProcessName(label)
    let task = Process()
    task.launchPath = path
    task.arguments = arg
    if currentDirectoryPath != ""{
        task.currentDirectoryPath = currentDirectoryPath
    }
    let outpipe = Pipe()
    task.standardOutput = outpipe
    let errpipe = Pipe()
    task.standardError = errpipe
    task.launch()
    task.waitUntilExit()
    delegate!.didReceiveProgress(progress)
    
    if delegate!.debugLog {
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outdata, encoding: String.Encoding.utf8)!
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        let error = String(data: errdata, encoding: String.Encoding.utf8)!
        let date = Date()
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([.hour, .minute, .second], from: date)
        Logger("==========\(components.hour!):\(components.minute!):\(components.second!)==========")
        Logger("\(path) \(arg.joined(separator: " ")),progress:\(progress)")
        Logger(output)
        Logger(error)
    }
    return task.terminationStatus
}

@discardableResult
func privilegedCommand(_ path:String,_  arg: [String],_ label: String = "",_ progress: Double = 0){
    delegate!.didReceiveProcessName(label)
    let task = STPrivilegedTask()
    task.setLaunchPath(path)
    task.setArguments(arg)
    task.launch()
    task.waitUntilExit()
    delegate!.didReceiveProgress(progress)
    if delegate!.debugLog {
        let date = Date()
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([.hour, .minute, .second], from: date)
        Logger("==========\(components.hour!):\(components.minute!):\(components.second!)==========")
        Logger("sudo \(path) \(arg.joined(separator: " "))")
    }
}
