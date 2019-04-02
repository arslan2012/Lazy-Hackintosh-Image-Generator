import Foundation
import RxSwift

//the main work flow
func workFlow(
        InstallerPath: String,
        SizeVal: String,
        cdrState: Bool,
        dropKernelState: Bool,
        extraDroppedFilePath: String,
        Path: String,
        OSInstallerPath: String
) {
    let appDelegate = NSApplication.shared.delegate as! MenuControlProtocol
    appDelegate.ProcessStarted()
    let options = [
        SizeVal,
        cdrState ? "true" : "false",
        dropKernelState ? "true" : "false",
        extraDroppedFilePath,
        Path,
        OSInstallerPath] as [String]
    Logger("=======Workflow Starting======")
    Logger(options.joined(separator: ","))
    ShellCommand.shared.sudo("/bin/rm", ["-rf", tempFolderPath], "#CleanDir#", 0).flatMap { _ in
        ShellCommand.shared.run("/bin/mkdir", [tempFolderPath], "#CleanDir#", 0)
    }.flatMap { _ in
        MountDisks(InstallerPath)
    }.flatMap {
        Create(SizeVal)
    }.flatMap {
        Copy()
    }.flatMap { _ -> Observable<Void> in
        if (SystemVersion.SysVerBiggerThan("10.12.99")) {
            return HighSierraMojaveCopyFile()
        } else {
            return MBR_Patch(OSInstallerPath: OSInstallerPath)
        }
    }.flatMap { _ -> Observable<Void> in
        if dropKernelState {
            return Drop_Kernel().map { _ in }
        } else {
            viewController!.didReceiveProgress(2)
            return Observable.of(())
        }
    }.flatMap {
        ShellCommand.shared.run("/bin/cp", ["-R", extraDroppedFilePath, "\(lazyImageMountPath)/"], "#COPYEXTRA#", 2)
    }.flatMap { _ -> Observable<Int32> in
        Logger("=======patching done========")
        return Eject(cdrState, Path == "" ? nil : Path)
    }.subscribe(onNext: { _ in
        viewController!.didReceiveProcessName("#FINISH#")
        viewController!.didReceiveThreadExitMessage()
        appDelegate.ProcessEnded()
    })
}

