//
//  shellCommand.swift
//  LazyHackintoshGenerator
//
//  Created by ئ‍ارسلان ئابلىكىم on 7/27/16.
//  Copyright © 2016 PCBeta. All rights reserved.
//

import Foundation
class shellCommand {
    static let sharedInstance = shellCommand()
    fileprivate init() { //This prevents others from using the default '()' initializer for this class.
    }
    @discardableResult
    func Command(_ delegate:BatchProcessAPIProtocol,_ path:String,_ arg: [String],_ label: String,_ progress: Double) -> Int32{
        return Command(delegate,path,arg,"",label,progress)
    }
    @discardableResult
    func Command(_ delegate:BatchProcessAPIProtocol,_ path:String,_ arg: [String],_ currentDirectoryPath:String,_ label: String,_ progress: Double) -> Int32{
        delegate.didReceiveProcessName(label)
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
        delegate.didReceiveProgress(progress)
        
        if delegate.debugLog {
            let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outdata, encoding: String.Encoding.utf8)!
            let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: errdata, encoding: String.Encoding.utf8)!
            let date = Date()
            let calendar = Calendar.current
            let components = (calendar as NSCalendar).components([.hour, .minute, .second], from: date)
            do{
                try "==========\(components.hour!):\(components.minute!):\(components.second!)==========".appendLineToURL(URL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
                try "\(path) \(arg.joined(separator: " ")),progress:\(progress)".appendLineToURL(URL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
                try output.appendLineToURL(URL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
                try error.appendLineToURL(URL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
            }catch{}
        }
        return task.terminationStatus
    }
    
    @discardableResult
    func privilegedCommand(_ delegate:BatchProcessAPIProtocol,_ path:String,_  arg: [String],_ label: String,_ progress: Double){
        delegate.didReceiveProcessName(label)
        privilegedCommand(delegate, path, arg)
        delegate.didReceiveProgress(progress)
    }
    @discardableResult
    func privilegedCommand(_ delegate:BatchProcessAPIProtocol,_ path:String,_  arg: [String]){
        let task = STPrivilegedTask()
        task.setLaunchPath(path)
        task.setArguments(arg)
        task.launch()
        task.waitUntilExit()
        if delegate.debugLog {
            let date = Date()
            let calendar = Calendar.current
            let components = (calendar as NSCalendar).components([.hour, .minute, .second], from: date)
            do{
                try "==========\(components.hour!):\(components.minute!):\(components.second!)==========".appendLineToURL(URL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
                try "sudo \(path) \(arg.joined(separator: " "))".appendLineToURL(URL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
            }catch{}
        }
    }
}
