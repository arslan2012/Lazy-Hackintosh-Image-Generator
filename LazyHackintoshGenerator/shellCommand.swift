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
    private init() { //This prevents others from using the default '()' initializer for this class.
    }
    func Command(delegate:BatchProcessAPIProtocol,_ path:String,_ arg: [String],_ label: String,_ progress: Double) -> (status: Int32, output: String){
        delegate.didReceiveProcessName(label)
        let task = NSTask()
        task.launchPath = path
        task.arguments = arg
        let outpipe = NSPipe()
        task.standardOutput = outpipe
        let errpipe = NSPipe()
        task.standardError = errpipe
        task.launch()
        task.waitUntilExit()
        delegate.didReceiveProgress(progress)
        var output = ""
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if let string = String.fromCString(UnsafePointer(outdata.bytes)) {
            output = string.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
        }
        
        if delegate.debugLog {
            var error = ""
            let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
            if let string = String.fromCString(UnsafePointer(errdata.bytes)) {
                error = string.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            }
            let date = NSDate()
            let calendar = NSCalendar.currentCalendar()
            let components = calendar.components([.Hour, .Minute, .Second], fromDate: date)
            do{
                try "\(path) \(arg.joinWithSeparator(" ")),progress:\(progress)".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
                try output.appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
                try error.appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
                try "==========\(components.hour):\(components.minute):\(components.second)==========".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
            }catch{}
        }
        return (task.terminationStatus,output)
    }
    func Command(delegate:BatchProcessAPIProtocol,_ path:String,_ arg: [String],_ currentDirectoryPath:String,_ label: String,_ progress: Double) -> (status: Int32, output: String){
        delegate.didReceiveProcessName(label)
        let task = NSTask()
        task.launchPath = path
        task.arguments = arg
        task.currentDirectoryPath = currentDirectoryPath
        let outpipe = NSPipe()
        task.standardOutput = outpipe
        let errpipe = NSPipe()
        task.standardError = errpipe
        task.launch()
        task.waitUntilExit()
        delegate.didReceiveProgress(progress)
        
        var output = ""
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if let string = String.fromCString(UnsafePointer(outdata.bytes)) {
            output = string.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
        }
        
        if delegate.debugLog {
            var error = ""
            let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
            if let string = String.fromCString(UnsafePointer(errdata.bytes)) {
                error = string.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            }
            let date = NSDate()
            let calendar = NSCalendar.currentCalendar()
            let components = calendar.components([.Hour, .Minute, .Second], fromDate: date)
            do{
                try "\(path) \(arg.joinWithSeparator(" ")),progress:\(progress)".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
                try output.appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
                try error.appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
                try "==========\(components.hour):\(components.minute):\(components.second)==========".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
            }catch{}
        }
        return (task.terminationStatus,output)
    }
    func privilegedCommand(delegate:BatchProcessAPIProtocol,_ path:String,_  arg: [String],_ label: String,_ progress: Double){
        delegate.didReceiveProcessName(label)
        let task = STPrivilegedTask()
        task.setLaunchPath(path)
        task.setArguments(arg)
        task.launch()
        task.waitUntilExit()
        delegate.didReceiveProgress(progress)
        if delegate.debugLog {
            let date = NSDate()
            let calendar = NSCalendar.currentCalendar()
            let components = calendar.components([.Hour, .Minute, .Second], fromDate: date)
            do{
                try "sudo \(path) \(arg.joinWithSeparator(" ")),progress:\(progress)".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
                try "==========\(components.hour):\(components.minute):\(components.second)==========".appendLineToURL(NSURL(fileURLWithPath:"\(NSHomeDirectory())/Lazy log.txt"))
            }catch{}
        }
    }
}