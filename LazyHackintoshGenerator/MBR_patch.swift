//
//  MBR_patch.swift
//  LazyHackintoshGenerator
//
//  Created by Arslan Ablikim on 10/5/16.
//  Copyright © 2016 Arslan Ablikim. All rights reserved.
//

import Foundation
import RxSwift

func MBR_Patch(OSInstallerPath: String) -> Observable<Void> {
    var result: Observable<Int32>
    if OSInstallerPath != "" {
        result = ShellCommand.shared.run("/bin/cp", ["-f", OSInstallerPath, "\(lazyImageMountPath)/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], "#Patch osinstaller#", 0)
    } else {
        result = OSInstaller_Patch(SystemVersion, SystemBuildVersion, "\(lazyImageMountPath.replacingOccurrences(of: " ", with: "\\ "))/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller")
    }
    if !SystemBuildVersion.SysBuildVerBiggerThan("16A284a") {
        result = result.flatMap({ _ in
            OSInstall_mpkg_Patch(SystemVersion, "\(lazyImageMountPath)/System/Installation/Packages/OSInstall.mpkg")
        })
    }
    return result.map({_ in
        viewController!.didReceiveProgress(2)
    })
}

func OSInstaller_Patch(_ SystemVersion: String, _ SystemBuildVersion: String, _ OSInstallerPath: String) -> Observable<Int32> {//progress:2%
    var patch: Observable<Int32>
    if SystemVersion.SysVerBiggerThan("10.11.99") {
        if SystemBuildVersion == "16A238m" {// 10.12 PB1+ MBR
            patch = ShellCommand.shared.run("/bin/sh", ["-c", "perl -pi -e 's|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x0F\\x84\\x91\\x00\\x00\\x00\\x48|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x90\\xE9\\x91\\x00\\x00\\x00\\x48|g' \(OSInstallerPath)"], "#Patch osinstaller#", 1)
        } else {// 10.12 DB1 only MBR
            patch = ShellCommand.shared.run("/bin/sh", ["-c", "perl -pi -e 's|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x0F\\x84\\x96\\x00\\x00\\x00\\x48|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x90\\xE9\\x96\\x00\\x00\\x00\\x48|g' \(OSInstallerPath)"], "#Patch osinstaller#", 1)
        }
    } else {// 10.10.x and 10.11.x MBR
        patch = ShellCommand.shared.run("/bin/sh", ["-c", "perl -pi -e 's|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x74\\x5F\\x48\\x8B\\x85|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\xEB\\x5F\\x48\\x8B\\x85|g' \(OSInstallerPath)"], "#Patch osinstaller#", 1)
    }
    return patch.flatMap({ _ in
        ShellCommand.shared.sudo("/usr/bin/codesign", ["-f", "-s", "-", OSInstallerPath], "#Patch osinstaller#", 1)
    })
}

func OSInstall_mpkg_Patch(_ SystemVersion: String, _ OSInstallPath: String) -> Observable<Int32> {//progress:0%
    var patch: Observable<Int32>
    patch = ShellCommand.shared.run("/bin/mkdir", ["/tmp/tech.arslan2012.lazy/osinstallmpkg"], "#Patch osinstall.mpkg#", 0).flatMap({ _ in
        ShellCommand.shared.run("/usr/bin/xar", ["-x", "-f", OSInstallPath, "-C", "/tmp/tech.arslan2012.lazy/osinstallmpkg"], "#Patch osinstall.mpkg#", 0)
    })
    if !SystemVersion.SysVerBiggerThan("10.11.99") {// 10.10.x and 10.11.x
        patch = patch.flatMap({ _ in
            ShellCommand.shared.run("/usr/bin/sed", ["-i", "\'\'", "--", "s/1024/512/g", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        }).flatMap({ _ in
            ShellCommand.shared.run("/usr/bin/sed", ["-i", "\'\'", "--", "s/var minRam = 2048/var minRam = 1024/g", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        }).flatMap({ _ in
            ShellCommand.shared.run("/usr/bin/sed", ["-i", "\'\'", "--", "s/osVersion=......... osBuildVersion=.......//g", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        }).flatMap({ _ in
            ShellCommand.shared.run("/usr/bin/sed", ["-i", "\'\'", "--", "/\\<installation-check script=\"installCheckScript()\"\\/>/d", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        }).flatMap({ _ in
            ShellCommand.shared.run("/usr/bin/sed", ["-i", "\'\'", "--", "/\\<volume-check script=\"volCheckScript()\"\\/>/d", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        })
    } else {// 10.12+ and deprecated since DB5/PB4
        patch = patch.flatMap({ _ in
            ShellCommand.shared.run("/usr/bin/sed", ["-i", "\'\'", "--", "/\\<installation-check script=\"InstallationCheck()\"\\/>/d", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        }).flatMap({ _ in
            ShellCommand.shared.run("/usr/bin/sed", ["-i", "\'\'", "--", "/\\<volume-check script=\"VolumeCheck()\"\\/>/d", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        })
    }
    patch = patch.flatMap({ _ in
        ShellCommand.shared.run("/bin/rm", [OSInstallPath], "#Patch osinstall.mpkg#", 0)
    }).flatMap({ _ in
        ShellCommand.shared.run("/bin/rm", ["/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution\'\'"], "#Patch osinstall.mpkg#", 0)
    }).flatMap({ _ in
        ShellCommand.shared.run("/usr/bin/xar", ["-cf", OSInstallPath, "."], "#Patch osinstall.mpkg#", 0, "/tmp/tech.arslan2012.lazy/osinstallmpkg")
    })
    return patch
}
