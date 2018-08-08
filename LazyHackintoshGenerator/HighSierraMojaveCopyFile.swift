//
// Created by Arslan Ablikim on 2018/8/8.
// Copyright (c) 2018 PCBeta. All rights reserved.
//

import Foundation

func HighSierraMojaveCopyFile() {
    privilegedCommand("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Library/Frameworks/Quartz.framework"], "#DELETEPACKAGE#", 0)
    privilegedCommand("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Library/Frameworks/QuickLook.framework"], "#DELETEPACKAGE#", 0)
    privilegedCommand("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Library/PrivateFrameworks/ChunkingLibrary.framework"], "#DELETEPACKAGE#", 0)
    privilegedCommand("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Library/PrivateFrameworks/GenerationalStorage.framework"], "#DELETEPACKAGE#", 0)
    privilegedCommand("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Library/PrivateFrameworks/OSInstaller.framework"], "#DELETEPACKAGE#", 0)
    privilegedCommand("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Installation/CDIS/macOS Installer.app"], "#DELETEPACKAGE#", 0)
    privilegedCommand("/bin/cp", ["-Rf", "\(Bundle.main.path(forResource: "System", ofType: nil)!)/", "\(lazyImageMountPath)/System/"], "#Copy ESD#", 0)
    privilegedCommand("/bin/cp", ["\(baseSystemMountPath)/System/Installation/CDIS/macOS Installer.app/Contents/Resources/X.tiff", "\(lazyImageMountPath)/System/Installation/CDIS/macOS Installer.app/Contents/Resources/X.tiff"], "#Copy ESD#", 2)
    if SystemVersion.SysVerBiggerThan("10.13.99") {
        privilegedCommand("/bin/cp", ["-f", "\(Bundle.main.path(forResource: "mojave2core", ofType: nil)!)", "\(lazyImageMountPath)/usr/bin/mojave2core"], "#Copy ESD#", 0)
    }
}
