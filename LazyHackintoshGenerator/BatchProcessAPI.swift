import Foundation

class BatchProcessAPI {
    var AppDelegate: MenuControlProtocol = NSApplication.shared.delegate as! MenuControlProtocol

    //the main work flow
    func startGenerating(
            SizeVal: String,
            LapicPatchState: Bool,
            XCPMPatchState: Bool,
            cdrState: Bool,
            dropKernelState: Bool,
            extraDroppedFilePath: String,
            Path: String,
            OSInstallerPath: String
    ) {
        DispatchQueue.main.async {
            self.maintainAuth()
            _ = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.maintainAuth), userInfo: nil, repeats: true)
        }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.AppDelegate.ProcessStarted()
            ////////////////////////////cleaning processes////////////////////////progress:3%
            if delegate!.debugLog {
                let options = [
                    SizeVal,
                    LapicPatchState ? "true" : "false",
                    XCPMPatchState ? "true" : "false",
                    cdrState ? "true" : "false",
                    dropKernelState ? "true" : "false",
                    extraDroppedFilePath,
                    Path,
                    OSInstallerPath] as [String]
                Logger("=======Workflow Starting======")
                Logger(options.joined(separator: ","))
            }
            ////////////////////////////creating processes////////////////////////progress:28%
            Create(SizeVal)
            ////////////////////////////copying processes/////////////////////////progress:57%
            Copy()
            ////////////////////////////patching processes////////////////////////progress:6%
            if (SystemVersion.SysVerBiggerThan("10.12.99")) {
                HighSierraMojaveCopyFile()
            } else {
                if OSInstallerPath != "" {
                    Command("/bin/cp", ["-f", OSInstallerPath, "\(lazyImageMountPath)/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller"], "#Patch osinstaller#", 0)
                } else {
                    OSInstaller_Patch(SystemVersion, SystemBuildVersion, "\(lazyImageMountPath.replacingOccurrences(of: " ", with: "\\ "))/System/Library/PrivateFrameworks/OSInstaller.framework/Versions/A/OSInstaller")
                }
                if !SystemBuildVersion.SysBuildVerBiggerThan("16A284a") {
                    OSInstall_mpkg_Patch(SystemVersion, "\(lazyImageMountPath)/System/Installation/Packages/OSInstall.mpkg")
                }
                delegate!.didReceiveProgress(2)
            }
            if dropKernelState {
                Drop_Kernel()
            } else {
                delegate!.didReceiveProgress(1)
            }

            var failedLapic = false
            if LapicPatchState {
                failedLapic = LAPIC_Patch(SystemVersion, "\(lazyImageMountPath)/System/Library/Kernels/kernel")
            }

            if XCPMPatchState {
                XCPM_Patch(SystemVersion, "\(lazyImageMountPath)/System/Library/Kernels/kernel")
            } else {
                delegate!.didReceiveProgress(1)
            }

            Command("/bin/cp", ["-R", extraDroppedFilePath, "\(lazyImageMountPath)/"], "#COPYEXTRA#", 2)
            if delegate!.debugLog {
                Logger("=======patching done========")
            }
            ////////////////////////////ejecting processes////////////////////////progress:9%
            if Path == "" {
                Eject(cdrState)
            } else {
                Eject(cdrState, Path)
            }
            if failedLapic {
                delegate!.didReceiveProcessName("#Failed Lapic#")
            } else {
                delegate!.didReceiveProcessName("#FINISH#")
            }
            delegate!.didReceiveThreadExitMessage()
            self.AppDelegate.ProcessEnded()
        }
    }

    @objc func maintainAuth() {
        STPrivilegedTask.extendAuthorizationRef()
    }

    @objc func asrTimeout(timer: Timer) {
        delegate!.didReceiveErrorMessage("#Asr Timeout#")
    }
}
