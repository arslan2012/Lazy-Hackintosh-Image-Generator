import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MenuControlProtocol {

    @IBOutlet weak var about: NSMenuItem!
    @IBOutlet weak var debugging: NSMenuItem!
    @IBOutlet weak var quit: NSMenuItem!
    @IBOutlet weak var update: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
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
        for item in [about, debugging, quit, update] {
            item?.isEnabled = true
        }
    }
}

