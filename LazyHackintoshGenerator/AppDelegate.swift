import Cocoa
import RxSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MenuControlProtocol {

    @IBOutlet weak var about: NSMenuItem!
    @IBOutlet weak var debugging: NSMenuItem!
    @IBOutlet weak var quit: NSMenuItem!
    @IBOutlet weak var update: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            let enumerator = try FileManager.default.contentsOfDirectory(atPath: tempFolderPath)
            Observable.from(enumerator).flatMap { element in
                ShellCommand.shared.run("/usr/bin/hdiutil", ["detach", "\(tempFolderPath)/\(element)", "-force"], "#CleanDir#", 0)
            }.subscribe()
        } catch {
        }
    }

    @IBAction func DebugMenuPressed(_ sender: NSMenuItem) {
        if sender.title == "#Debug On#".localized() {
            debugLog = true
            sender.title = "#Debug Off#".localized()
        } else {
            debugLog = false
            sender.title = "#Debug On#".localized()
        }
    }

    func ProcessStarted() {
        for item in [about, debugging, quit, update] {
            item?.isEnabled = false
        }
    }

    func ProcessEnded() {
        InstallESDMountPath = "\(tempFolderPath)/ESDMount"
        baseSystemFilePath = ""
        SystemVersion = ""
        SystemBuildVersion = ""
        for item in [about, debugging, quit, update] {
            item?.isEnabled = true
        }
    }
}

