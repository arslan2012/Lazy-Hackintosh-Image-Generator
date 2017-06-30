import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MenuControlProtocol {

    @IBOutlet weak var about: NSMenuItem!
    @IBOutlet weak var debugging: NSMenuItem!
    @IBOutlet weak var quit: NSMenuItem!
    @IBOutlet weak var update: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            let enumerator = try FileManager.default.contentsOfDirectory(atPath: "/tmp/com.pcbeta.lazy")
            for element in enumerator {
                Command("/usr/bin/hdiutil", ["detach", "/tmp/com.pcbeta.lazy/\(element)", "-force"], "#CleanDir#", 0)
            }
        } catch {
        }
        Command("/bin/rm", ["-rf", "/tmp/com.pcbeta.lazy"], "#CleanDir#", 0)
        Command("/bin/mkdir", ["/tmp/com.pcbeta.lazy"], "#CleanDir#", 0)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
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
        InstallESDMountPath = "/tmp/com.pcbeta.lazy/ESDMount"
        baseSystemFilePath = ""
        SystemVersion = ""
        SystemBuildVersion = ""
        for item in [about, debugging, quit, update] {
            item?.isEnabled = true
        }
    }
}

