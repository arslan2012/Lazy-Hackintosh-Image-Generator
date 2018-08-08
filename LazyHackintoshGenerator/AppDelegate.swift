import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MenuControlProtocol {

    @IBOutlet weak var about: NSMenuItem!
    @IBOutlet weak var debugging: NSMenuItem!
    @IBOutlet weak var quit: NSMenuItem!
    @IBOutlet weak var update: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            let enumerator = try FileManager.default.contentsOfDirectory(atPath: "/tmp/tech.arslan2012.lazy")
            for element in enumerator {
                Command("/usr/bin/hdiutil", ["detach", "/tmp/tech.arslan2012.lazy/\(element)", "-force"], "#CleanDir#", 0)
            }
        } catch {
        }
        Command("/bin/rm", ["-rf", "/tmp/tech.arslan2012.lazy"], "#CleanDir#", 0)
        Command("/bin/mkdir", ["/tmp/tech.arslan2012.lazy"], "#CleanDir#", 0)
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
        InstallESDMountPath = "/tmp/tech.arslan2012.lazy/ESDMount"
        baseSystemFilePath = ""
        SystemVersion = ""
        SystemBuildVersion = ""
        for item in [about, debugging, quit, update] {
            item?.isEnabled = true
        }
    }
}

