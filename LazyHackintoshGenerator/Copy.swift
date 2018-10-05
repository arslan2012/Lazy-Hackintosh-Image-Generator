//
// Created by Arslan Ablikim on 30/06/2017.
// Copyright (c) 2017 Arslan Ablikim. All rights reserved.
//

import Foundation
import RxSwift

func Copy() -> Observable<Void> {
    return ShellCommand.shared.sudo("/usr/sbin/asr", ["restore", "--source", baseSystemFilePath, "--target", lazyImageMountPath, "--erase", "--format", "HFS+", "--noprompt", "--noverify"], "#COPYBASE#", 17.0).flatMap({ _ -> Observable<[Int32]> in
        var detaches: [Observable<Int32>] = []
        do {
            let enumerator = try FileManager.default.contentsOfDirectory(atPath: "/Volumes")
            for element in enumerator {
                if element.hasPrefix("OS X Base System") {
                    if (URL(fileURLWithPath: "/Volumes/\(element)") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                        detaches.append(ShellCommand.shared.run("/usr/bin/hdiutil", ["detach", "/Volumes/\(element)", "-force"], "#Wait Asr#", 0))
                    }
                }
            }
        } catch {
        }
        return Observable.zip(detaches)
    }).flatMap({ _ in
        return ShellCommand.shared.run("/usr/bin/hdiutil", ["attach", "/tmp/tech.arslan2012.lazy/Lazy Installer.dmg", "-noverify", "-nobrowse", "-quiet", "-mountpoint", lazyImageMountPath], "#Wait Asr#", 0)
    }).flatMap({ _ -> Observable<Int32> in
        do {
            let enumerator = try FileManager.default.contentsOfDirectory(atPath: "\(lazyImageMountPath)")
            if enumerator.count > 2 {
                viewController!.didReceiveProgress(5)
            }
        } catch {
            viewController!.didReceiveErrorMessage("#Error in lazy image#")
        }
        if SystemVersion.SysVerBiggerThan("10.13.99") {
            return ShellCommand.shared.sudo("/usr/sbin/diskutil", ["rename", "OS X Base System", "Mojave Custom Installer"], "#COPYBASE#", 2)
        } else if SystemVersion.SysVerBiggerThan("10.12.99") {
            return ShellCommand.shared.sudo("/usr/sbin/diskutil", ["rename", "OS X Base System", "High Sierra Custom Installer"], "#COPYBASE#", 2)
        } else if SystemVersion.SysVerBiggerThan("10.11.99") {
            return ShellCommand.shared.sudo("/usr/sbin/diskutil", ["rename", "OS X Base System", "Sierra Custom Installer"], "#COPYBASE#", 2)
        } else if SystemVersion.SysVerBiggerThan("10.10.99") {
            return ShellCommand.shared.sudo("/usr/sbin/diskutil", ["rename", "OS X Base System", "El Capitan Custom Installer"], "#COPYBASE#", 2)
        } else if SystemVersion.SysVerBiggerThan("10.9.99") {
            return ShellCommand.shared.sudo("/usr/sbin/diskutil", ["rename", "OS X Base System", "Yosemite Custom Installer"], "#COPYBASE#", 2)
        } else {
            return ShellCommand.shared.sudo("/usr/sbin/diskutil", ["rename", "OS X Base System", "OS X Custom Installer"], "#COPYBASE#", 2)
        }
    }).flatMap({ _ -> Observable<[Int32]> in
        var copies: [Observable<Int32>] = []
        if SystemVersion.SysVerBiggerThan("10.12.99") {
            copies.append(ShellCommand.shared.run("/bin/cp", ["\(appFilePath)/Contents/SharedSupport/BaseSystem.chunklist", lazyImageMountPath], "#Copy ESD#", 2))
            copies.append(ShellCommand.shared.run("/bin/cp", ["\(appFilePath)/Contents/SharedSupport/BaseSystem.dmg", lazyImageMountPath], "#Copy ESD#", 2))
            copies.append(ShellCommand.shared.run("/bin/cp", ["\(appFilePath)/Contents/SharedSupport/AppleDiagnostics.chunklist", lazyImageMountPath], "#Copy ESD#", 2))
            copies.append(ShellCommand.shared.run("/bin/cp", ["\(appFilePath)/Contents/SharedSupport/AppleDiagnostics.dmg", lazyImageMountPath], "#Copy ESD#", 2))
        } else {
            copies.append(ShellCommand.shared.run("/bin/cp", ["\(InstallESDMountPath)/BaseSystem.chunklist", lazyImageMountPath], "#Copy ESD#", 2))
            copies.append(ShellCommand.shared.run("/bin/cp", ["\(InstallESDMountPath)/BaseSystem.dmg", lazyImageMountPath], "#Copy ESD#", 2))
            copies.append(ShellCommand.shared.run("/bin/cp", ["\(InstallESDMountPath)/AppleDiagnostics.chunklist", lazyImageMountPath], "#Copy ESD#", 2))
            copies.append(ShellCommand.shared.run("/bin/cp", ["\(InstallESDMountPath)/AppleDiagnostics.dmg", lazyImageMountPath], "#Copy ESD#", 2))
        }
        return Observable.zip(copies)
    }).flatMap({ _ in
        ShellCommand.shared.run("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Installation/Packages"], "#DELETEPACKAGE#", 2)
    }).flatMap({ _ in
        ShellCommand.shared.sudo("/bin/cp", ["-R", "\(InstallESDMountPath)/Packages", "\(lazyImageMountPath)/System/Installation"], "#COPYPACKAGE#", 22)
    }).flatMap({ _ in
        ShellCommand.shared.run("/bin/mkdir", ["\(lazyImageMountPath)/System/Library/Kernels"], "#Create Kernels folder#", 1)
    }).map({_ in
        if viewController!.debugLog {
            Logger("========copying done========")
        }
    })
}
