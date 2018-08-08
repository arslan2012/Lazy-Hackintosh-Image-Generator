//
// Created by Arslan Ablikim on 30/06/2017.
// Copyright (c) 2017 PCBeta. All rights reserved.
//

import Foundation

func Eject(_ cdrState: Bool, _ Path: String = "\(NSHomeDirectory())/Desktop/") {
    var name = Path;
    if (Path == "\(NSHomeDirectory())/Desktop/") {
        if SystemVersion.SysVerBiggerThan("10.13.99") {
            name += "Mojave Custom Installer.dmg"
        } else if SystemVersion.SysVerBiggerThan("10.12.99") {
            name += "High Sierra Custom Installer.dmg"
        } else if SystemVersion.SysVerBiggerThan("10.11.99") {
            name += "Sierra Custom Installer.dmg"
        } else if SystemVersion.SysVerBiggerThan("10.10.99") {
            name += "El Capitan Custom Installer.dmg"
        } else if SystemVersion.SysVerBiggerThan("10.9.99") {
            name += "Yosemite Custom Installer.dmg"
        }
    }
    Command("/usr/bin/chflags", ["nohidden", lazyImageMountPath], "#EJECTESD#", 0)
    if cdrState {
        Command("/usr/bin/hdiutil", ["detach", originalFileMountPath, "-force"], "#EJECTORG#", 0)
        Command("/usr/bin/hdiutil", ["detach", InstallESDMountPath, "-force"], "#EJECTESD#", 1)
        Command("/usr/bin/hdiutil", ["detach", lazyImageMountPath, "-force"], "#EJECTLAZY#", 1)

        Command("/usr/bin/hdiutil", ["convert", "/tmp/tech.arslan2012.lazy/Lazy Installer.dmg", "-ov", "-format", "UDTO", "-o", "/tmp/tech.arslan2012.lazy/Lazy Installer.cdr"], "#Create CDR#", 7)
        Command("/bin/mv", ["/tmp/tech.arslan2012.lazy/Lazy Installer.dmg", name], "#MV#", 0)
        Command("/bin/mv", ["/tmp/tech.arslan2012.lazy/Lazy Installer.cdr", name.replacingOccurrences(of: "dmg", with: "cdr")], "#MV#", 0)
    } else {
        Command("/usr/bin/hdiutil", ["detach", originalFileMountPath, "-force"], "#EJECTORG#", 2)
        Command("/usr/bin/hdiutil", ["detach", InstallESDMountPath, "-force"], "#EJECTESD#", 2)
        Command("/usr/bin/hdiutil", ["detach", lazyImageMountPath, "-force"], "#EJECTLAZY#", 2)
        Command("/bin/mv", ["/tmp/tech.arslan2012.lazy/Lazy Installer.dmg", name], "#MV#", 3)
    }
}
