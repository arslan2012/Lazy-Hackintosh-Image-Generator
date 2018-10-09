//
//  Global.swift
//  LazyHackintoshGenerator
//
//  Created by Arslan Ablikim on 10/5/16.
//  Copyright © 2016 Arslan Ablikim. All rights reserved.
//

protocol BatchProcessAPIProtocol {
    func didReceiveProcessName(_ results: String)
    func didReceiveProgress(_ results: Double)
    func didReceiveErrorMessage(_ results: String)
    func didReceiveThreadExitMessage()
}

protocol MenuControlProtocol {
    func ProcessStarted()
    func ProcessEnded()
}

var viewController: BatchProcessAPIProtocol? = nil
var debugLog = false

let tempFolderPath = "/tmp/tech.arslan2012.lazy"
let lazyImageMountPath = "\(tempFolderPath)/lazyMount"
let originalFileMountPath = "\(tempFolderPath)/originMount"
let baseSystemMountPath = "\(tempFolderPath)/baseMount"

var InstallESDMountPath = "\(tempFolderPath)/ESDMount"
var baseSystemFilePath = ""
var appFilePath = ""
var SystemVersion = ""
var SystemBuildVersion = ""