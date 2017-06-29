//
//  GetSystemVersionFromPlist.swift
//  LazyHackintoshGenerator
//
//  Created by Arslan Ablikim on 11/2/16.
//  Copyright © 2016 PCBeta. All rights reserved.
//

import Foundation

func GetSystemVersionFromPlist(_ SystemVersionPlistPath: String) -> (String, String) {//progress:0%
    var SystemVersion = "", SystemBuildVersion = ""
    if let myDict = NSDictionary(contentsOfFile: SystemVersionPlistPath) {
        SystemVersion = myDict.value(forKey: "ProductVersion") as! String
        SystemBuildVersion = myDict.value(forKey: "ProductBuildVersion") as! String
    } else {
        delegate!.didReceiveErrorMessage("#Error in sysVer#")
    }
    if SystemVersion == "" || SystemBuildVersion == "" {
        delegate!.didReceiveErrorMessage("#Error in sysVer#")
    }
    if delegate!.debugLog {
        Logger("Detected System Version:\(SystemVersion) \(SystemBuildVersion)")
        Logger("===========================")
    }
    return (SystemVersion: SystemVersion, SystemBuildVersion: SystemBuildVersion)
}
