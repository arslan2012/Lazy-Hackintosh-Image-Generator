//
// Created by Arslan Ablikim on 30/06/2017.
// Copyright (c) 2017 Arslan Ablikim. All rights reserved.
//

import RxSwift

func MountDisks(_ filePath: String) -> Observable<Void> {
    var result = Observable.of(())
    if filePath.hasSuffix("dmg") {
        result = ShellCommand.shared.run("/usr/bin/hdiutil", ["attach", filePath, "-noverify", "-nobrowse", "-quiet", "-mountpoint", originalFileMountPath], "#MOUNTORG#", 0.0).flatMap({ _ -> Observable<Void> in
            if (URL(fileURLWithPath: "\(originalFileMountPath)/BaseSystem.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                InstallESDMountPath = originalFileMountPath
                baseSystemFilePath = "\(InstallESDMountPath)/BaseSystem.dmg"
            } else {
                do {
                    let enumerator = try FileManager.default.contentsOfDirectory(atPath: originalFileMountPath)
                    return Observable.from(enumerator).single { element in
                        element.hasSuffix("app") && (URL(fileURLWithPath: "\(originalFileMountPath)/\(element)/Contents/SharedSupport/InstallESD.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil)
                    }.flatMap { element in
                        ShellCommand.shared.run("/usr/bin/hdiutil", ["attach", "\(originalFileMountPath)/\(element)/Contents/SharedSupport/InstallESD.dmg", "-noverify", "-nobrowse", "-quiet", "-mountpoint", InstallESDMountPath], "#MOUNTESD#", 0).map { _ in
                            if (URL(fileURLWithPath: "\(originalFileMountPath)/\(element)/Contents/SharedSupport/BaseSystem.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                                baseSystemFilePath = "\(originalFileMountPath)/\(element)/Contents/SharedSupport/BaseSystem.dmg"
                                appFilePath = "\(originalFileMountPath)/\(element)"
                            } else if (URL(fileURLWithPath: "\(InstallESDMountPath)/BaseSystem.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                                baseSystemFilePath = "\(InstallESDMountPath)/BaseSystem.dmg"
                            } else {
                                viewController!.didReceiveErrorMessage("#Error in InstallESD image#")
                            }
                        }
                    }
                } catch {
                    viewController!.didReceiveErrorMessage("#Error in InstallESD image#")
                }
            }
            return result
        })
    } else if filePath.hasSuffix("app") {
        if (URL(fileURLWithPath: "\(filePath)/Contents/SharedSupport/InstallESD.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
            result = ShellCommand.shared.run("/usr/bin/hdiutil", ["attach", "\(filePath)/Contents/SharedSupport/InstallESD.dmg", "-noverify", "-nobrowse", "-quiet", "-mountpoint", InstallESDMountPath], "#MOUNTESD#", 0).map { _ in
                if (URL(fileURLWithPath: "\(filePath)/Contents/SharedSupport/BaseSystem.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                    baseSystemFilePath = "\(filePath)/Contents/SharedSupport/BaseSystem.dmg"
                } else if (URL(fileURLWithPath: "\(InstallESDMountPath)/BaseSystem.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                    baseSystemFilePath = "\(InstallESDMountPath)/BaseSystem.dmg"
                } else {
                    viewController!.didReceiveErrorMessage("#Error in InstallESD image#")
                }
                appFilePath = filePath
            }
        } else {
            viewController!.didReceiveErrorMessage("#Error in InstallESD image#")
        }
    }
    //////////////////mount BaseSystem.dmg to determine the system version
    result = result.flatMap { _ in
        ShellCommand.shared.run("/usr/bin/hdiutil", ["attach", baseSystemFilePath, "-noverify", "-nobrowse", "-quiet", "-mountpoint", baseSystemMountPath], "#MOUNTORG#", 0)
    }.map { _ in
        (SystemVersion, SystemBuildVersion) = GetSystemVersionFromPlist("\(baseSystemMountPath)/System/Library/CoreServices/SystemVersion.plist")

        Logger("=======mounting done========")
    }

    return result
}