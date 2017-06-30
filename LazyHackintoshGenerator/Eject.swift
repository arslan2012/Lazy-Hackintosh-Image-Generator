//
// Created by Arslan Ablikim on 30/06/2017.
// Copyright (c) 2017 PCBeta. All rights reserved.
//

import Foundation

func Eject(_ cdrState: Bool, _ Path: String = "\(NSHomeDirectory())/Desktop/") {
    Command("/usr/bin/chflags", ["nohidden", lazyImageMountPath], "#EJECTESD#", 0)
    if cdrState {
        Command("/usr/bin/hdiutil", ["detach", originalFileMountPath, "-force"], "#EJECTORG#", 0)
        Command("/usr/bin/hdiutil", ["detach", InstallESDMountPath, "-force"], "#EJECTESD#", 1)
        Command("/usr/bin/hdiutil", ["detach", lazyImageMountPath, "-force"], "#EJECTLAZY#", 1)

        Command("/usr/bin/hdiutil", ["convert", "/tmp/com.pcbeta.lazy/Lazy Installer.dmg", "-ov", "-format", "UDTO", "-o", "/tmp/com.pcbeta.lazy/Lazy Installer.cdr"], "#Create CDR#", 7)
        if (Path == "\(NSHomeDirectory())/Desktop/") {
            if SystemVersion.SysVerBiggerThan("10.11.99") {
                Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg", "\(Path)Sierra Custom Installer.dmg"], "#MV#", 0)
                Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.cdr", "\(Path)Sierra Custom Installer.cdr"], "#MV#", 0)
            } else if SystemVersion.SysVerBiggerThan("10.10.99") {
                Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg", "\(Path)El Capitan Custom Installer.dmg"], "#MV#", 0)
                Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.cdr", "\(Path)El Capitan Custom Installer.cdr"], "#MV#", 0)
            } else if SystemVersion.SysVerBiggerThan("10.9.99") {
                Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg", "\(Path)Yosemite Custom Installer.dmg"], "#MV#", 0)
                Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.cdr", "\(Path)Yosemite Custom Installer.cdr"], "#MV#", 0)
            } else {
                Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg", Path], "#MV#", 0)
                Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.cdr", Path], "#MV#", 0)
            }
        } else {
            Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg", Path], "#MV#", 0)
            Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.cdr", Path.replacingOccurrences(of: "dmg", with: "cdr")], "#MV#", 0)
        }
    } else {
        Command("/usr/bin/hdiutil", ["detach", originalFileMountPath, "-force"], "#EJECTORG#", 2)
        Command("/usr/bin/hdiutil", ["detach", InstallESDMountPath, "-force"], "#EJECTESD#", 2)
        Command("/usr/bin/hdiutil", ["detach", lazyImageMountPath, "-force"], "#EJECTLAZY#", 2)
        if (Path == "\(NSHomeDirectory())/Desktop/") {
            if SystemVersion.SysVerBiggerThan("10.11.99") {
                Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg", "\(Path)Sierra Custom Installer.dmg"], "#MV#", 3)
            } else if SystemVersion.SysVerBiggerThan("10.10.99") {
                Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg", "\(Path)El Capitan Custom Installer.dmg"], "#MV#", 3)
            } else if SystemVersion.SysVerBiggerThan("10.9.99") {
                Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg", "\(Path)Yosemite Custom Installer.dmg"], "#MV#", 3)
            } else {
                Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg", Path], "#MV#", 3)
            }
        } else {
            Command("/bin/mv", ["/tmp/com.pcbeta.lazy/Lazy Installer.dmg", Path], "#MV#", 3)
        }

    }
}