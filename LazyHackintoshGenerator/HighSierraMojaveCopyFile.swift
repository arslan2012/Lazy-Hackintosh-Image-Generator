//
// Created by Arslan Ablikim on 2018/8/8.
// Copyright (c) 2018 Arslan Ablikim. All rights reserved.
//

import Foundation
import RxSwift

func HighSierraMojaveCopyFile() -> Observable<Void> {
    var removes: [Observable<Int32>] = []
    removes.append(ShellCommand.shared.sudo("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Library/Frameworks/Quartz.framework"], "#DELETEPACKAGE#", 0))
    removes.append(ShellCommand.shared.sudo("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Library/Frameworks/QuickLook.framework"], "#DELETEPACKAGE#", 0))
    removes.append(ShellCommand.shared.sudo("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Library/PrivateFrameworks/ChunkingLibrary.framework"], "#DELETEPACKAGE#", 0))
    removes.append(ShellCommand.shared.sudo("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Library/PrivateFrameworks/GenerationalStorage.framework"], "#DELETEPACKAGE#", 0))
    removes.append(ShellCommand.shared.sudo("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Library/PrivateFrameworks/OSInstaller.framework"], "#DELETEPACKAGE#", 0))
    removes.append(ShellCommand.shared.sudo("/bin/rm", ["-rf", "\(lazyImageMountPath)/System/Installation/CDIS/macOS Installer.app"], "#DELETEPACKAGE#", 0))
    return Observable.zip(removes).flatMap({ _ in
        ShellCommand.shared.sudo("/bin/cp", ["-Rf", "\(Bundle.main.path(forResource: "System", ofType: nil)!)/", "\(lazyImageMountPath)/System/"], "#Copy ESD#", 0)
    }).flatMap({ _ in
        ShellCommand.shared.sudo("/bin/cp", ["\(baseSystemMountPath)/System/Installation/CDIS/macOS Installer.app/Contents/Resources/X.tiff", "\(lazyImageMountPath)/System/Installation/CDIS/macOS Installer.app/Contents/Resources/X.tiff"], "#Copy ESD#", 2)
    }).flatMap({ _ -> Observable<Void> in
        if SystemVersion.SysVerBiggerThan("10.13.99") {
            return ShellCommand.shared.sudo("/bin/cp", ["-f", "\(Bundle.main.path(forResource: "mojave2core", ofType: nil)!)", "\(lazyImageMountPath)/usr/bin/mojave2core"], "#Copy ESD#", 0).map({ _ in })
        } else {
            return Observable.of(())
        }
    })
}
