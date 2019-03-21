//
// Created by Arslan Ablikim on 30/06/2017.
// Copyright (c) 2017 Arslan Ablikim. All rights reserved.
//

import RxSwift

func Eject(_ cdrState: Bool, _ Path: String?) -> Observable<Void> {
    var name = Path ?? "\(NSHomeDirectory())/Desktop/";
    if (name == "\(NSHomeDirectory())/Desktop/") {
        name += "\(getCustomInstallerName()).dmg"
    }
    ShellCommand.shared.run("/usr/bin/chflags", ["nohidden", lazyImageMountPath], "#EJECTESD#", 0).subscribe()
    ShellCommand.shared.run("/usr/bin/hdiutil", ["detach", originalFileMountPath, "-force"], "#EJECTORG#", 0).subscribe()
    ShellCommand.shared.run("/usr/bin/hdiutil", ["detach", InstallESDMountPath, "-force"], "#EJECTESD#", 1).subscribe()
    ShellCommand.shared.run("/usr/bin/hdiutil", ["detach", lazyImageMountPath, "-force"], "#EJECTLAZY#", 1).subscribe()
    var result: Observable<Int32>;
    if cdrState {
        result = ShellCommand.shared.run("/usr/bin/hdiutil", ["convert", "\(tempFolderPath)/Lazy Installer.dmg", "-ov", "-format", "UDTO", "-o", "\(tempFolderPath)/Lazy Installer.cdr"], "#Create CDR#", 7).flatMap { _ in
            ShellCommand.shared.run("/bin/mv", ["\(tempFolderPath)/Lazy Installer.dmg", name], "#MV#", 0)
        }.flatMap { _ in
            ShellCommand.shared.run("/bin/mv", ["\(tempFolderPath)/Lazy Installer.cdr", name.replacingOccurrences(of: "dmg", with: "cdr")], "#MV#", 0)
        }
    } else {
        viewController!.didReceiveProgress(4)
        result = ShellCommand.shared.run("/bin/mv", ["\(tempFolderPath)/Lazy Installer.dmg", name], "#MV#", 3)
    }
    return result.map { _ in}
}
