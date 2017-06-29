//
//  XCPM_patch.swift
//  LazyHackintoshGenerator
//
//  Created by Arslan Ablikim on 10/5/16.
//  Copyright © 2016 PCBeta. All rights reserved.
//

import Foundation

func XCPM_Patch(_ SystemVersion: String, _ kernelPath: String) {//progress:1%
    if !SystemVersion.SysVerBiggerThan("10.11.99") {
        Command("/bin/sh", ["-c", "perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x02\\x00\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(kernelPath)"], "#XCPMPATCH#", 0)
    }
    Command("/bin/sh", ["-c", "perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x4c\\x00\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(kernelPath)"], "#XCPMPATCH#", 0)
    if !SystemVersion.SysVerBiggerThan("10.11.1") {
        Command("/bin/sh", ["-c", "perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x90\\x01\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(kernelPath)"], "#XCPMPATCH#", 1)
    } else if SystemVersion.SysVerBiggerThan("10.11.99") {
        Command("/bin/sh", ["-c", "perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x90\\x33\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(kernelPath)"], "#XCPMPATCH#", 1)
    } else {
        Command("/bin/sh", ["-c", "perl -pi -e 's|\\xe2\\x00\\x00\\x00\\x90\\x13\\x00\\x00|\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00|g' \(kernelPath)"], "#XCPMPATCH#", 1)
    }
}
