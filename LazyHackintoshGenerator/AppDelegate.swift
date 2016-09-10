import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MenuControlProtocol {
	
	@IBOutlet weak var about: NSMenuItem!
	@IBOutlet weak var debugging: NSMenuItem!
	@IBOutlet weak var quit: NSMenuItem!
	@IBOutlet weak var update: NSMenuItem!
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
	
	@IBAction func DebugMenuPressed(sender: NSMenuItem) {
		if sender.title == "#Debug On#".localized(){
			sender.title = "#Debug Off#".localized()
		}else {
			sender.title = "#Debug On#".localized()
		}
	}
	
	func getDebugStatus() ->Bool{
        if debugging.title == "#Debug On#".localized(){
            return false
        }else {
            return true
        }
	}
    func ProcessStarted(){
        for item in [about,debugging,quit,update] {
        item.enabled = false
        }
    }
    func ProcessEnded(){
        for item in [about,debugging,quit,update] {
            item.enabled = true
        }
    }
}

