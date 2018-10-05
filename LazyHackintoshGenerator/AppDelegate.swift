import Cocoa
import RxSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MenuControlProtocol {

    @IBOutlet weak var about: NSMenuItem!
    @IBOutlet weak var debugging: NSMenuItem!
    @IBOutlet weak var quit: NSMenuItem!
    @IBOutlet weak var update: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        appDelegate = self
        do {
            let enumerator = try FileManager.default.contentsOfDirectory(atPath: "/tmp/tech.arslan2012.lazy")
            Observable.from(enumerator).flatMap{element in
                ShellCommand.shared.run("/usr/bin/hdiutil", ["detach", "/tmp/tech.arslan2012.lazy/\(element)", "-force"], "#CleanDir#", 0)
                }.subscribe()
        } catch {
        }
    }

    @IBAction func DebugMenuPressed(_ sender: NSMenuItem) {
        if sender.title == "#Debug On#".localized() {
            sender.title = "#Debug Off#".localized()
        } else {
            sender.title = "#Debug On#".localized()
        }
    }

    func getDebugStatus() -> Bool {
        if debugging.title == "#Debug Off#".localized() {
            return true
        } else {
            return false
        }
    }

    func ProcessStarted() {
        for item in [about, debugging, quit, update] {
            item?.isEnabled = false
        }
    }

    func ProcessEnded() {
        InstallESDMountPath = "/tmp/tech.arslan2012.lazy/ESDMount"
        baseSystemFilePath = ""
        SystemVersion = ""
        SystemBuildVersion = ""
        for item in [about, debugging, quit, update] {
            item?.isEnabled = true
        }
    }
}

