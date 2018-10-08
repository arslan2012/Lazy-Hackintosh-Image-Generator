//
//  Helper.swift
//  MyApplication
//
//  Created by Erik Berglund on 2016-12-06.
//  Copyright © 2016 Erik Berglund. All rights reserved.
//

import Foundation

class Helper: NSObject, HelperProtocol, NSXPCListenerDelegate {

    private var connections = [NSXPCConnection]()
    private var listener: NSXPCListener
    private var shouldQuit = false
    private var shouldQuitCheckInterval = 1.0

    override init() {
        self.listener = NSXPCListener(machServiceName: HelperConstants.machServiceName)
        super.init()
        self.listener.delegate = self
    }

    /* 
        Starts the helper tool
     */
    func run() {
        self.listener.resume()

        // Kepp the helper running until shouldQuit variable is set to true.
        // This variable is changed to true in the connection invalidation handler in the listener(_ listener:shoudlAcceptNewConnection:) funciton.
        while !shouldQuit {
            RunLoop.current.run(until: Date.init(timeIntervalSinceNow: shouldQuitCheckInterval))
        }
    }

    /*
        Called when the application connects to the helper
     */
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {

        // MARK: Here a check should be added to verify the application that is calling the helper
        // For example, checking that the codesigning is equal on the calling binary as this helper.

        newConnection.remoteObjectInterface = NSXPCInterface(with: ProcessProtocol.self)
        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        newConnection.exportedObject = self;
        newConnection.invalidationHandler = (() -> Void)? {
            if let indexValue = self.connections.index(of: newConnection) {
                self.connections.remove(at: indexValue)
            }

            if self.connections.count == 0 {
                self.shouldQuit = true
            }
        }
        self.connections.append(newConnection)
        newConnection.resume()
        return true
    }

    /*
        Return bundle version for this helper
     */
    func getVersion(reply: (String) -> Void) {
        reply(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)
    }

    /*
        Not really used in this test app, but there might be reasons to support multiple simultaneous connections.
     */
    private func connection() -> NSXPCConnection {
        //
        return self.connections.last!
    }


    /*
        General private function to run an external command
     */
    func runTask(_ path: String, _ arg: [String], _ currentDirectoryPath: String, _ reply: @escaping (Int32) -> Void) {
        let task = Process()
        task.launchPath = path
        task.arguments = arg
        if currentDirectoryPath != "" {
            task.currentDirectoryPath = currentDirectoryPath
        }
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe
        if let remoteObject = self.connection().remoteObjectProxy as? ProcessProtocol {
            let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outdata, encoding: String.Encoding.utf8)!
            let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: errdata, encoding: String.Encoding.utf8)!
            remoteObject.saveLog(path, arg, output, error)
        }
        task.terminationHandler = { task in
            reply(task.terminationStatus)
        }
        task.launch()
    }

    func runTask(_ path: String, _ arg: [String], _ currentDirectoryPath: String, _ reply: @escaping (Int32) -> Void, _ authData: NSData) {

        // Check the passed authorization, if the user need to authenticate to use this command the user might be prompted depending on the settings and/or cached authentication.
        if !HelperAuthorization().checkAuthorization(authData: authData, command: NSStringFromSelector(#selector(HelperProtocol.runTask(_:_:_:_:_:)))) {
            reply(-1)
        }
        // Run the task
        runTask(path, arg, currentDirectoryPath, reply)
    }
}