import Foundation
import RxSwift

class BatchProcessAPI {
    //the main work flow
    func startGenerating(
            InstallerPath: String,
            SizeVal: String,
            cdrState: Bool,
            dropKernelState: Bool,
            extraDroppedFilePath: String,
            Path: String,
            OSInstallerPath: String
    ) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            appDelegate!.ProcessStarted()
            ////////////////////////////cleaning processes////////////////////////progress:3%
            if viewController!.debugLog {
                let options = [
                    SizeVal,
                    cdrState ? "true" : "false",
                    dropKernelState ? "true" : "false",
                    extraDroppedFilePath,
                    Path,
                    OSInstallerPath] as [String]
                Logger("=======Workflow Starting======")
                Logger(options.joined(separator: ","))
            }
            ShellCommand.shared.sudo("/bin/rm", ["-rf", "/tmp/tech.arslan2012.lazy"], "#CleanDir#", 0).flatMap { _ in
                ShellCommand.shared.run("/bin/mkdir", ["/tmp/tech.arslan2012.lazy"], "#CleanDir#", 0)
            }.flatMap { _ in
                ////////////////////////////mounting processes////////////////////////
                MountDisks(InstallerPath)
            }.flatMap { _ in
                ////////////////////////creating processes////////////////////////progress:28%
                Create(SizeVal)
            }.flatMap { _ in
                ////////////////////////copying processes/////////////////////////progress:57%
                Copy()
            }.flatMap { _ -> Observable<Void> in
                ////////////////////////patching processes////////////////////////progress:6%
                if (SystemVersion.SysVerBiggerThan("10.12.99")) {
                    return HighSierraMojaveCopyFile()
                } else {
                    return MBR_Patch(OSInstallerPath: OSInstallerPath)
                }
            }.flatMap { _ -> Observable<Void> in
                if dropKernelState {
                    return Drop_Kernel()
                } else {
                    viewController!.didReceiveProgress(2)
                    return Observable.of(())
                }
            }.flatMap { _ -> Observable<Void> in
                ShellCommand.shared.run("/bin/cp", ["-R", extraDroppedFilePath, "\(lazyImageMountPath)/"], "#COPYEXTRA#", 2).map({ _ in })
            }.flatMap { _ -> Observable<Void> in
                if viewController!.debugLog {
                    Logger("=======patching done========")
                }
                ////////////////////////////ejecting processes////////////////////////progress:9%
                if Path == "" {
                    return Eject(cdrState)
                } else {
                    return Eject(cdrState, Path)
                }
            }.subscribe(onNext: { _ in
                viewController!.didReceiveProcessName("#FINISH#")
                viewController!.didReceiveThreadExitMessage()
                appDelegate!.ProcessEnded()
            })
        }
    }
}
