//
// Created by Arslan Ablikim on 30/06/2017.
// Copyright (c) 2017 PCBeta. All rights reserved.
//

import Foundation

func Create(_ SizeVal: String) {
    Command("/usr/bin/hdiutil", ["create", "-size", "\(SizeVal)g", "-layout", "SPUD", "-ov", "-fs", "HFS+J", "-volname", "OS X Lazy Installer", "/tmp/com.pcbeta.lazy/Lazy Installer.dmg"], "#Create Lazy image#", 26)
    Command("/usr/bin/hdiutil", ["attach", "/tmp/com.pcbeta.lazy/Lazy Installer.dmg", "-noverify", "-nobrowse", "-quiet", "-mountpoint", lazyImageMountPath], "#Mount Lazy image#", 2)
    if !(URL(fileURLWithPath: lazyImageMountPath) as NSURL).checkResourceIsReachableAndReturnError(nil) {
        delegate!.didReceiveErrorMessage("#Error in lazy image#")
    }
    if delegate!.debugLog {
        Logger("=======creating done========")
    }
}