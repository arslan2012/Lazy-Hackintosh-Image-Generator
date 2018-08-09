//
// Created by Arslan Ablikim on 30/06/2017.
// Copyright (c) 2017 PCBeta. All rights reserved.
//

import Foundation

func MountDisks(_ filePath: String) {
    if filePath.hasSuffix("dmg") {
        Command("/usr/bin/hdiutil", ["attach", filePath, "-noverify", "-nobrowse", "-quiet", "-mountpoint", originalFileMountPath], "#MOUNTORG#", 0)
        if (URL(fileURLWithPath: "\(originalFileMountPath)/BaseSystem.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
            InstallESDMountPath = originalFileMountPath
            baseSystemFilePath = "\(InstallESDMountPath)/BaseSystem.dmg"
        } else {
            do {
                let enumerator = try FileManager.default.contentsOfDirectory(atPath: originalFileMountPath)
                for element in enumerator {
                    if element.hasSuffix("app") && (URL(fileURLWithPath: "\(originalFileMountPath)/\(element)/Contents/SharedSupport/InstallESD.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                        Command("/usr/bin/hdiutil", ["attach", "\(originalFileMountPath)/\(element)/Contents/SharedSupport/InstallESD.dmg", "-noverify", "-nobrowse", "-quiet", "-mountpoint", InstallESDMountPath], "#MOUNTESD#", 0)
                        if (URL(fileURLWithPath: "\(originalFileMountPath)/\(element)/Contents/SharedSupport/BaseSystem.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                            baseSystemFilePath = "\(originalFileMountPath)/\(element)/Contents/SharedSupport/BaseSystem.dmg"
                            appFilePath = "\(originalFileMountPath)/\(element)"
                        } else if (URL(fileURLWithPath: "\(InstallESDMountPath)/BaseSystem.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                            baseSystemFilePath = "\(InstallESDMountPath)/BaseSystem.dmg"
                        } else {
                            delegate!.didReceiveErrorMessage("#Error in InstallESD image#")
                        }
                        break
                    }
                }
            } catch {
                delegate!.didReceiveErrorMessage("#Error in InstallESD image#")
            }
        }
    } else if filePath.hasSuffix("app") {
        if (URL(fileURLWithPath: "\(filePath)/Contents/SharedSupport/InstallESD.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
            Command("/usr/bin/hdiutil", ["attach", "\(filePath)/Contents/SharedSupport/InstallESD.dmg", "-noverify", "-nobrowse", "-quiet", "-mountpoint", InstallESDMountPath], "#MOUNTESD#", 0)
            if (URL(fileURLWithPath: "\(filePath)/Contents/SharedSupport/BaseSystem.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                baseSystemFilePath = "\(filePath)/Contents/SharedSupport/BaseSystem.dmg"
            } else if (URL(fileURLWithPath: "\(InstallESDMountPath)/BaseSystem.dmg") as NSURL).checkResourceIsReachableAndReturnError(nil) {
                baseSystemFilePath = "\(InstallESDMountPath)/BaseSystem.dmg"
            } else {
                delegate!.didReceiveErrorMessage("#Error in InstallESD image#")
            }
            appFilePath = filePath
        } else {
            delegate!.didReceiveErrorMessage("#Error in InstallESD image#")
        }
    }
    //////////////////mount BaseSystem.dmg to determine the system version
    Command("/usr/bin/hdiutil", ["attach", baseSystemFilePath, "-noverify", "-nobrowse", "-quiet", "-mountpoint", baseSystemMountPath], "#MOUNTORG#", 0)
    (SystemVersion, SystemBuildVersion) = GetSystemVersionFromPlist("\(baseSystemMountPath)/System/Library/CoreServices/SystemVersion.plist")

    if delegate!.debugLog {
        Logger("=======mounting done========")
    }
}