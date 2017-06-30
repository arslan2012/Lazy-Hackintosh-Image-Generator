//
// Created by Arslan Ablikim on 30/06/2017.
// Copyright (c) 2017 PCBeta. All rights reserved.
//

import Foundation

func Copy() {
    privilegedCommand("/usr/sbin/asr", ["restore", "--source", baseSystemFilePath, "--target", lazyImageMountPath, "--erase", "--format", "HFS+", "--noprompt", "--noverify"], "#COPYBASE#", 17)
    var asrCompletedMounting = false;
    let asrTime = Timer.scheduledTimer(timeInterval: 200, target: BatchProcessAPI.self, selector: #selector(BatchProcessAPI.asrTimeout), userInfo: nil, repeats: false)
    while (!asrCompletedMounting) {
        do {
            let enumerator = try FileManager.default.contentsOfDirectory(atPath: "/Volumes")
            for element in enumerator {
                if element.hasPrefix("OS X Base System") {
                    if (URL(fileURLWithPath: "/Volumes/\(element)") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                        Command("/usr/bin/hdiutil", ["detach", "/Volumes/\(element)", "-force"], "#Wait Asr#", 0)
                    }
                }
            }
        } catch {
        }
        Command("/usr/bin/hdiutil", ["attach", "/tmp/com.pcbeta.lazy/Lazy Installer.dmg", "-noverify", "-nobrowse", "-quiet", "-mountpoint", lazyImageMountPath], "#Wait Asr#", 0)
        do {
            let enumerator = try FileManager.default.contentsOfDirectory(atPath: "\(lazyImageMountPath)")
            if enumerator.count > 2 {
                delegate!.didReceiveProgress(5)
                asrTime.invalidate()
                asrCompletedMounting = true
            }
        } catch {
            delegate!.didReceiveErrorMessage("#Error in lazy image#")
        }
    }
    if SystemVersion.SysVerBiggerThan("10.11.99") {
        privilegedCommand("/usr/sbin/diskutil", ["rename", "OS X Base System", "Sierra Custom Installer"], "#COPYBASE#", 2)
    } else if SystemVersion.SysVerBiggerThan("10.10.99") {
        privilegedCommand("/usr/sbin/diskutil", ["rename", "OS X Base System", "El Capitan Custom Installer"], "#COPYBASE#", 2)
    } else if SystemVersion.SysVerBiggerThan("10.9.99") {
        privilegedCommand("/usr/sbin/diskutil", ["rename", "OS X Base System", "Yosemite Custom Installer"], "#COPYBASE#", 2)
    } else {
        privilegedCommand("/usr/sbin/diskutil", ["rename", "OS X Base System", "OS X Custom Installer"], "#COPYBASE#", 2)
    }
    Command("/bin/cp", ["\(InstallESDMountPath)/BaseSystem.chunklist", lazyImageMountPath], "#Copy ESD#", 2)
    Command("/bin/cp", [baseSystemFilePath, lazyImageMountPath], "#Copy ESD#", 2)
    Command("/bin/cp", ["\(InstallESDMountPath)/AppleDiagnostics.chunklist", lazyImageMountPath], "#Copy ESD#", 2)
    Command("/bin/cp", ["\(InstallESDMountPath)/AppleDiagnostics.dmg", lazyImageMountPath], "#Copy ESD#", 2)
    Command("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Installation/Packages"], "#DELETEPACKAGE#", 2)
    privilegedCommand("/bin/cp", ["-R", "\(InstallESDMountPath)/Packages", "\(lazyImageMountPath)/System/Installation"], "#COPYPACKAGE#", 22)
    Command("/bin/mkdir", ["\(lazyImageMountPath)/System/Library/Kernels"], "#Create Kernels folder#", 1)
    if delegate!.debugLog {
        Logger("========copying done========")
    }
}