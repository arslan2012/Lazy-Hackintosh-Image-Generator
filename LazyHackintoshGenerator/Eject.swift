//
// Created by Arslan Ablikim on 30/06/2017.
// Copyright (c) 2017 Arslan Ablikim. All rights reserved.
//

import Foundation
import RxSwift

func Eject(_ cdrState: Bool, _ Path: String = "\(NSHomeDirectory())/Desktop/") -> Observable<Void> {
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
    ShellCommand.shared.run("/usr/bin/chflags", ["nohidden", lazyImageMountPath], "#EJECTESD#", 0).subscribe()
    ShellCommand.shared.run("/usr/bin/hdiutil", ["detach", originalFileMountPath, "-force"], "#EJECTORG#", 0).subscribe()
    ShellCommand.shared.run("/usr/bin/hdiutil", ["detach", InstallESDMountPath, "-force"], "#EJECTESD#", 1).subscribe()
    ShellCommand.shared.run("/usr/bin/hdiutil", ["detach", lazyImageMountPath, "-force"], "#EJECTLAZY#", 1).subscribe()
    if cdrState {
        return ShellCommand.shared.run("/usr/bin/hdiutil", ["convert", "/tmp/tech.arslan2012.lazy/Lazy Installer.dmg", "-ov", "-format", "UDTO", "-o", "/tmp/tech.arslan2012.lazy/Lazy Installer.cdr"], "#Create CDR#", 7).flatMap({_ in
            ShellCommand.shared.run("/bin/mv", ["/tmp/tech.arslan2012.lazy/Lazy Installer.dmg", name], "#MV#", 0)
        }).flatMap({_ in
            ShellCommand.shared.run("/bin/mv", ["/tmp/tech.arslan2012.lazy/Lazy Installer.cdr", name.replacingOccurrences(of: "dmg", with: "cdr")], "#MV#", 0)
        }).map({_ in})
    } else {
        viewController!.didReceiveProgress(4)
        return ShellCommand.shared.run("/bin/mv", ["/tmp/tech.arslan2012.lazy/Lazy Installer.dmg", name], "#MV#", 3).map({_ in})
    }
}
