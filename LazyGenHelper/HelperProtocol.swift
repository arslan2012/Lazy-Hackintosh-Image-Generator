//
//  HelperProtocol.swift
//  MyApplication
//
//  Created by Erik Berglund on 2016-12-06.
//  Copyright © 2016 Erik Berglund. All rights reserved.
//

import Foundation

struct HelperConstants {
    static let machServiceName = "tech.arslan2012.LazyHackintoshGeneratorHelper"
}

// Protocol to list all functions the main application can call in the helper
@objc(HelperProtocol)
protocol HelperProtocol {
    func getVersion(reply: @escaping (String) -> Void)
    func runTask(_ path: String, _ arg: [String], _ currentDirectoryPath: String, _ reply: @escaping (Int32) -> Void, _ authData: NSData)
    func runTask(_ path: String, _ arg: [String], _ currentDirectoryPath: String, _ reply: @escaping (Int32) -> Void)
}
