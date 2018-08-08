//
//  MBR_patch.swift
//  LazyHackintoshGenerator
//
//  Created by Arslan Ablikim on 10/5/16.
//  Copyright © 2016 PCBeta. All rights reserved.
//

import Foundation

func OSInstaller_Patch(_ SystemVersion: String, _ SystemBuildVersion: String, _ OSInstallerPath: String) {//progress:2%
    if SystemVersion.SysVerBiggerThan("10.11.99") {
        if SystemBuildVersion == "16A238m" {// 10.12 PB1+ MBR
            Command("/bin/sh", ["-c", "perl -pi -e 's|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x0F\\x84\\x91\\x00\\x00\\x00\\x48|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x90\\xE9\\x91\\x00\\x00\\x00\\x48|g' \(OSInstallerPath)"], "#Patch osinstaller#", 1)
        } else {// 10.12 DB1 only MBR
            Command("/bin/sh", ["-c", "perl -pi -e 's|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x0F\\x84\\x96\\x00\\x00\\x00\\x48|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x90\\xE9\\x96\\x00\\x00\\x00\\x48|g' \(OSInstallerPath)"], "#Patch osinstaller#", 1)
        }
    } else {// 10.10.x and 10.11.x MBR
        Command("/bin/sh", ["-c", "perl -pi -e 's|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\x74\\x5F\\x48\\x8B\\x85|\\x48\\x8B\\x78\\x28\\x48\\x85\\xFF\\xEB\\x5F\\x48\\x8B\\x85|g' \(OSInstallerPath)"], "#Patch osinstaller#", 1)
    }
    privilegedCommand("/usr/bin/codesign", ["-f", "-s", "-", OSInstallerPath], "#Patch osinstaller#", 1)
}

func OSInstall_mpkg_Patch(_ SystemVersion: String, _ OSInstallPath: String) {//progress:0%
    Command("/bin/mkdir", ["/tmp/tech.arslan2012.lazy/osinstallmpkg"], "#Patch osinstall.mpkg#", 0)
    Command("/usr/bin/xar", ["-x", "-f", OSInstallPath, "-C", "/tmp/tech.arslan2012.lazy/osinstallmpkg"], "#Patch osinstall.mpkg#", 0)
    if !SystemVersion.SysVerBiggerThan("10.11.99") {// 10.10.x and 10.11.x
        Command("/usr/bin/sed", ["-i", "\'\'", "--", "s/1024/512/g", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        Command("/usr/bin/sed", ["-i", "\'\'", "--", "s/var minRam = 2048/var minRam = 1024/g", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        Command("/usr/bin/sed", ["-i", "\'\'", "--", "s/osVersion=......... osBuildVersion=.......//g", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        Command("/usr/bin/sed", ["-i", "\'\'", "--", "/\\<installation-check script=\"installCheckScript()\"\\/>/d", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        Command("/usr/bin/sed", ["-i", "\'\'", "--", "/\\<volume-check script=\"volCheckScript()\"\\/>/d", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
    } else {// 10.12+ and deprecated since DB5/PB4
        Command("/usr/bin/sed", ["-i", "\'\'", "--", "/\\<installation-check script=\"InstallationCheck()\"\\/>/d", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
        Command("/usr/bin/sed", ["-i", "\'\'", "--", "/\\<volume-check script=\"VolumeCheck()\"\\/>/d", "/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution"], "#Patch osinstall.mpkg#", 0)
    }
    Command("/bin/rm", [OSInstallPath], "#Patch osinstall.mpkg#", 0)
    Command("/bin/rm", ["/tmp/tech.arslan2012.lazy/osinstallmpkg/Distribution\'\'"], "#Patch osinstall.mpkg#", 0)
    Command("/usr/bin/xar", ["-cf", OSInstallPath, "."], "#Patch osinstall.mpkg#", 0, "/tmp/tech.arslan2012.lazy/osinstallmpkg")
}
