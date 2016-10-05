//
//  LAPIC_patch.swift
//  LazyHackintoshGenerator
//
//  Created by Arslan Ablikim on 10/5/16.
//  Copyright © 2016 PCBeta. All rights reserved.
//

import Foundation
func LAPIC_Patch(_ SystemVersion:String,_ Path:String) -> Bool {//progress:0%
    //////using rainbow chart method to speed up the patching process
    //        let transients:[String:String]=[
    //            "14A389":"\\xe8\\xd4\\x54\\xf1\\xff",
    //            "14B25":"\\xe8\\xd4\\x54\\xf1\\xff",
    //            "14C109":"\\xe8\\x54\\xed\\xf0\\xff",
    //            "14D131":"\\xe8\\x14\\xc8\\xf0\\xff",
    //            "14E46":"\\xe8\\x14\\xc8\\xf0\\xff",
    //            "14F27":"\\xe8\\x64\\xc6\\xf0\\xff",
    //            "15A284":"\\xe8\\xcd\\x6b\\xf0\\xff",
    //            "15B42":"\\xe8\\xfd\\x68\\xf0\\xff",
    //            "15C50":"\\xe8\\xed\\x53\\xf0\\xff",
    //            "15D21":"\\xe8\\xed\\x53\\xf0\\xff",
    //            "15E65":"\\xe8\\xbd\\x48\\xf0\\xff",
    //            "15F34":"\\xe8\\xcd\\x46\\xf0\\xff",
    //            "15G31":"\\xe8\\x0d\\x46\\xf0\\xff",
    //            ///////below is beta version patches
    //            "16A201w":"\\xe8\\x3d\\xdf\\xee\\xff",
    //            "16A238m":"\\xe8\\x2d\\x58\\xee\\xff"
    //        ]
    //        if let key = transients[self.SystemBuildVersion] {
    //            Command(self.viewDelegate,"/bin/sh",["-c","perl -pi -e 's|\(key)|\\x90\\x90\\x90\\x90\\x90|g' \(self.lazypath)/System/Library/Kernels/kernel"], "#LAPICPATCH#",0)
    //            return true
    //        }else{
    //if rainbow chart fails, using donovan6000 and sherlocks method of finding hex _panic value method
    var FindingBlock:[UInt8],offset = 0,patchoffset = 0
    if !SystemVersion.SysVerBiggerThan("10.11.1") {//if Yosemite
        FindingBlock = [0x65,0x8B,0x04,0x25,0x1C,0x00,0x00,0x00]
        offset = 33
        patchoffset = 28
    }else if SystemVersion.SysVerBiggerThan("10.11.99") {//if Sierra
        FindingBlock = [0x65,0x8B,0x0C,0x25,0x1C,0x00,0x00,0x00]
        offset = 1409
        patchoffset = 1398
    }else{// if El Capitan
        FindingBlock = [0x65,0x8B,0x0C,0x25,0x1C,0x00,0x00,0x00]
        offset = 1411
        patchoffset = 1400
    }
    var tmp1 = [UInt8](repeating:0, count:8),tmp2 = [UInt8](repeating:0, count:8),key = ""
    let file: Data! = try? Data(contentsOf: URL(fileURLWithPath: Path))
    for i in 0...(file.count - offset - 8) {
        file.copyBytes(to: &tmp1, from: i..<i+8)
        file.copyBytes(to: &tmp2, from: i+offset..<i+offset+8)
        if tmp1 == FindingBlock && tmp2 == FindingBlock {
            var tmp3:UInt8 = 0
            for n in 0...4{
                file.copyBytes(to: &tmp3, from: i+patchoffset+n..<i+patchoffset+n+1)
                key += "\\x"
                key += String(tmp3, radix: 16, uppercase: false)
            }
            break
        }
    }
    if key == "" {
        return false
    }else {
        Command("/bin/sh",["-c","perl -pi -e 's|\(key)|\\x90\\x90\\x90\\x90\\x90|g' \(Path)"], "#LAPICPATCH#",0)
        return true
    }
}
