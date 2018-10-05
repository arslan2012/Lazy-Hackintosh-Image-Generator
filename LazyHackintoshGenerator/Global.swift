//
//  Global.swift
//  LazyHackintoshGenerator
//
//  Created by Arslan Ablikim on 10/5/16.
//  Copyright © 2016 Arslan Ablikim. All rights reserved.
//

import Foundation

protocol BatchProcessAPIProtocol {
    var debugLog: Bool { get set }
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
var appDelegate: MenuControlProtocol? = nil
let lazyImageMountPath = "/tmp/tech.arslan2012.lazy/lazyMount"
let originalFileMountPath = "/tmp/tech.arslan2012.lazy/originMount"
let baseSystemMountPath = "/tmp/tech.arslan2012.lazy/baseMount"
var InstallESDMountPath = "/tmp/tech.arslan2012.lazy/ESDMount"
var baseSystemFilePath = ""
var appFilePath = ""
var SystemVersion = ""
var SystemBuildVersion = ""