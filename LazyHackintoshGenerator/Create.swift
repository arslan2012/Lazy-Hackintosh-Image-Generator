//
// Created by Arslan Ablikim on 30/06/2017.
// Copyright (c) 2017 Arslan Ablikim. All rights reserved.
//

import RxSwift

func Create(_ SizeVal: String) -> Observable<Void> {
    return ShellCommand.shared.run("/usr/bin/hdiutil", ["create", "-size", "\(SizeVal)g", "-layout", "SPUD", "-ov", "-fs", "HFS+J", "-volname", "OS X Lazy Installer", "\(tempFolderPath)/Lazy Installer.dmg"], "#Create Lazy image#", 26).flatMap { _ in
        ShellCommand.shared.run("/usr/bin/hdiutil", ["attach", "\(tempFolderPath)/Lazy Installer.dmg", "-noverify", "-nobrowse", "-quiet", "-mountpoint", lazyImageMountPath], "#Mount Lazy image#", 2)
    }.map { _ in
        if !(URL(fileURLWithPath: lazyImageMountPath) as NSURL).checkResourceIsReachableAndReturnError(nil) {
            viewController!.didReceiveErrorMessage("#Error in lazy image#")
        }
        Logger("=======creating done========")
    }
}