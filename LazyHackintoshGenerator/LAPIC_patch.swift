//
//  LAPIC_patch.swift
//  LazyHackintoshGenerator
//
//  Created by Arslan Ablikim on 10/5/16.
//  Copyright © 2016 PCBeta. All rights reserved.
//

import Foundation

func LAPIC_Patch(_ SystemVersion: String, _ Path: String) -> Bool {//progress:0%
    var FindingBlock: [UInt8], offset = 0, patchoffset = 0
    if !SystemVersion.SysVerBiggerThan("10.11.1") {//if Yosemite
        FindingBlock = [0x65, 0x8B, 0x04, 0x25, 0x1C, 0x00, 0x00, 0x00]
        offset = 33
        patchoffset = 28
    } else if SystemVersion.SysVerBiggerThan("10.11.99") {//if Sierra
        FindingBlock = [0x65, 0x8B, 0x0C, 0x25, 0x1C, 0x00, 0x00, 0x00]
        offset = 1409
        patchoffset = 1398
    } else {// if El Capitan
        FindingBlock = [0x65, 0x8B, 0x0C, 0x25, 0x1C, 0x00, 0x00, 0x00]
        offset = 1411
        patchoffset = 1400
    }
    var tmp1 = [UInt8](repeating: 0, count: 8), tmp2 = [UInt8](repeating: 0, count: 8), key = ""
    let file: Data! = try? Data(contentsOf: URL(fileURLWithPath: Path))
    for i in 0...(file.count - offset - 8) {
        file.copyBytes(to: &tmp1, from: i..<i + 8)
        file.copyBytes(to: &tmp2, from: i + offset..<i + offset + 8)
        if tmp1 == FindingBlock && tmp2 == FindingBlock {
            var tmp3: UInt8 = 0
            for n in 0...4 {
                file.copyBytes(to: &tmp3, from: i + patchoffset + n..<i + patchoffset + n + 1)
                key += "\\x"
                key += String(tmp3, radix: 16, uppercase: false)
            }
            break
        }
    }
    if key == "" {
        return false
    } else {
        Command("/bin/sh", ["-c", "perl -pi -e 's|\(key)|\\x90\\x90\\x90\\x90\\x90|g' \(Path)"], "#LAPICPATCH#", 0)
        return true
    }
}
