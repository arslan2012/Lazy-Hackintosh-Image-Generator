import Cocoa

class ViewController: NSViewController, NSWindowDelegate,BatchProcessAPIProtocol {
	@IBOutlet weak var filePath: NSTextField!
	@IBOutlet weak var progress: NSProgressIndicator!
	@IBOutlet weak var extraPath: NSTextField!
	@IBOutlet weak var progressLable: NSTextField!
	@IBOutlet weak var start: NSButton!
	@IBOutlet weak var MBRPatch: NSButton!
	@IBOutlet weak var LapicPatch: NSButton!
	@IBOutlet weak var XCPMPatch: NSButton!
	@IBOutlet weak var cdr: NSButton!
	@IBOutlet weak var extra: OtherFileDrop!
	@IBOutlet weak var SizeCustomize: NSButton!
	@IBOutlet weak var CustomSize: NSTextField!
	@IBOutlet weak var SizeUnit: NSTextField!
	@IBOutlet weak var exitButton: NSButton!
	@IBOutlet weak var dropKernel: NSButton!
	@IBOutlet weak var CLT: NSButton!
	lazy var debugLog: Bool = false
	lazy var api : BatchProcessAPI = BatchProcessAPI(viewDelegate: self)
	
	override func viewDidLoad() {
        if self.api.shellCommand("/usr/bin/xcode-select", arg: ["-p"], label: "", progress: 0) != 0{
            MBRPatch.enabled=false
            MBRPatch.state = NSOffState
        }else{
            CLT.hidden=true
        }
		super.viewDidLoad()
		progress.hidden = true
		progressLable.hidden = true
		CustomSize.hidden = true
		SizeUnit.hidden = true
		XCPMPatch.state = NSOffState
		cdr.state = NSOffState
		exitButton.hidden = true
		
		for button in [MBRPatch,LapicPatch,XCPMPatch,cdr,SizeCustomize,dropKernel]{
			button.attributedTitle = NSAttributedString(string: button.title, attributes: [ NSForegroundColorAttributeName : NSColor.whiteColor()])
		}
	}
	override func viewDidAppear() {
		super.viewDidAppear()
		self.view.window?.delegate = self
		self.view.window!.title = "#Title#".localized()
		self.view.wantsLayer = true
		self.view.layer?.backgroundColor = CGColorCreateGenericRGB(83/255, 87/255, 96/255, 1);
	}
	
	override var representedObject: AnyObject? {
		didSet {
			// Update the view, if already loaded.
		}
	}
	func windowShouldClose(sender: AnyObject) -> Bool {
		exit(0)
	}
	@IBAction func StartProcessing(sender: NSButton) {
		if !NSURL(fileURLWithPath:filePath.stringValue).checkResourceIsReachableAndReturnError(nil){
			let a = NSAlert()
			a.messageText = "#Input is void#".localized()
			a.runModal()
		}else {
			let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
			debugLog = appDelegate.getDebugStatus()
			start.hidden = true
            CLT.hidden = true
			progress.hidden = false
			progressLable.hidden = false
			progress.startAnimation(self)
			var UsingCustomSize = false
			if SizeCustomize.state == NSOnState {
				if Double(CustomSize.stringValue) <= 0 || Double(CustomSize.stringValue) > 100 {
					let a = NSAlert()
					a.messageText = "#WRONGSIZE#".localized()
					a.runModal()
					exit(0)
				}else{
					UsingCustomSize = true
				}
			}
			var SizeVal = "7.15"
			if UsingCustomSize {
				SizeVal = CustomSize.stringValue
			}
            let button = view.window?.standardWindowButton(NSWindowButton.CloseButton)
            button?.enabled = false
			let MBRPatchState = (MBRPatch.state == NSOnState) ? true : false
            let LapicPatchState = (LapicPatch.state == NSOnState) ? true : false
			let XCPMPatchState = (XCPMPatch.state == NSOnState) ? true : false
			let cdrState = (cdr.state == NSOnState) ? true : false
			let dropKernelState = (dropKernel.state == NSOnState) ? true : false
			MBRPatch.enabled=false
			XCPMPatch.enabled=false
			cdr.enabled=false
			SizeCustomize.enabled=false
			CustomSize.enabled=false
			dropKernel.enabled=false
            LapicPatch.enabled=false
            api.startGenerating(filePath.stringValue,SizeVal: SizeVal,MBRPatchState: MBRPatchState,LapicPatchState:LapicPatchState,XCPMPatchState: XCPMPatchState,cdrState: cdrState,dropKernelState:dropKernelState,extraDroppedFilePath: extra.droppedFilePath)
		}
	}
	@IBAction func XCPMClicked(sender: NSButton) {
		if XCPMPatch.state == NSOnState {
				dropKernel.state = NSOnState
		}
	}
	@IBAction func LapicClicked(sender: NSButton) {
        if LapicPatch.state == NSOnState {
            dropKernel.state = NSOnState
        }
	}
	@IBAction func dropKernelClicked(sender: NSButton) {
		if dropKernel.state == NSOffState {
			XCPMPatch.state = NSOffState
            LapicPatch.state = NSOffState
		}
	}
	@IBAction func SizeClicked(sender: NSButton) {
		if SizeCustomize.state == NSOnState {
			CustomSize.hidden = false
			SizeUnit.hidden = false
            SizeCustomize.title = ""
            SizeCustomize.state = NSOnState
		}else {
			CustomSize.hidden = true
			SizeUnit.hidden = true
            SizeCustomize.attributedTitle = NSAttributedString(string: "#Custom Size#".localized(), attributes: [ NSForegroundColorAttributeName : NSColor.whiteColor()])
            SizeCustomize.state = NSOffState
		}
	}
	@IBAction func CLTButtonPressed(sender: NSButton) {
        self.api.shellCommand("/bin/sh", arg: ["-c","xcode-select --install"], label: "", progress: 0)
	}
	@IBAction func exitButtonPressed(sender: NSButton) {
		exit(0)
	}
	func didReceiveProcessName(results: String){
        dispatch_async(dispatch_get_main_queue(),{
                self.progressLable.stringValue = results.localized()
        })
	}
	func didReceiveProgress(results: Double){
		dispatch_async(dispatch_get_main_queue(),{
			self.progress.incrementBy(results)
		})
	}
	func didReceiveErrorMessage(results: String){
		let a = NSAlert()
		a.messageText = results.localized()
		a.runModal()
		exit(0)
	}
	func didReceiveThreadExitMessage(){
        dispatch_async(dispatch_get_main_queue(),{
		self.progress.stopAnimation(self)
		self.filePath.stringValue = ""
		self.exitButton.hidden = false
        let button = self.view.window?.standardWindowButton(NSWindowButton.CloseButton)
        button?.enabled = true
        })
	}
}

