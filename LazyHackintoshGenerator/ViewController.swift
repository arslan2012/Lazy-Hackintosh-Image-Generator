import Cocoa

class ViewController: NSViewController, NSWindowDelegate,BatchProcessAPIProtocol,FileDropZoneProtocol {
    @IBOutlet weak var filePath: NSTextField!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var extraPath: NSTextField!
    @IBOutlet weak var progressLable: NSTextField!
    @IBOutlet weak var start: NSButton!
    @IBOutlet weak var MBRPatch: NSButton!
    @IBOutlet weak var LapicPatch: NSButton!
    @IBOutlet weak var XCPMPatch: NSButton!
    @IBOutlet weak var cdr: NSButton!
    @IBOutlet weak var Installer: FileDropZone!
    @IBOutlet weak var extra: FileDropZone!
    @IBOutlet weak var SizeCustomize: NSButton!
    @IBOutlet weak var CustomSize: NSTextField!
    @IBOutlet weak var SizeUnit: NSTextField!
    @IBOutlet weak var exitButton: NSButton!
    @IBOutlet weak var dropKernel: NSButton!
    @IBOutlet weak var CLT: NSButton!
    @IBOutlet weak var Output: NSButton!
    @IBOutlet weak var Disk: NSButton!
	@IBOutlet weak var OSInstaller: NSButton!
    var debugLog: Bool = false, Path = "", MountPath = "",OSInstallerPath = ""

    lazy var api : BatchProcessAPI = BatchProcessAPI(viewDelegate: self,AppDelegate: NSApplication.sharedApplication().delegate as! MenuControlProtocol)
    
    override func viewDidLoad() {
        if shellCommand.sharedInstance.Command(self,"/usr/bin/xcode-select", ["-p"], "", 0) != 0{
            MBRPatch.enabled=false
            MBRPatch.state = NSOffState
        }else{
            CLT.hidden=true
            OSInstaller.hidden=true
        }
        super.viewDidLoad()
        extra.viewDelegate = self
        Installer.viewDelegate = self
        progress.hidden = true
        progressLable.hidden = true
        CustomSize.hidden = true
        SizeUnit.hidden = true
        XCPMPatch.state = NSOffState
        cdr.state = NSOffState
        exitButton.hidden = true
        
        for button in [MBRPatch,LapicPatch,XCPMPatch,cdr,SizeCustomize,dropKernel,Output,Disk,OSInstaller]{
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
            let MBRPatchState = (MBRPatch.state == NSOnState)
            let LapicPatchState = (LapicPatch.state == NSOnState)
            let XCPMPatchState = (XCPMPatch.state == NSOnState)
            let cdrState = (cdr.state == NSOnState)
            let dropKernelState = (dropKernel.state == NSOnState)
            for button in [MBRPatch,XCPMPatch,cdr,SizeCustomize,CustomSize,dropKernel,LapicPatch,Disk,Output,OSInstaller,CLT]{
                button.enabled = false
            }
            api.startGenerating(filePath.stringValue,SizeVal,MBRPatchState,LapicPatchState,XCPMPatchState,cdrState,dropKernelState,extraPath.stringValue,Path,MountPath,OSInstallerPath)
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
    @IBAction func CustomOutputClicked(sender: NSButton) {
        if sender.state == NSOnState {
            dispatch_async(dispatch_get_main_queue(),
                           {
                            let myFiledialog = NSSavePanel()
                            
                            myFiledialog.prompt = "Open"
                            myFiledialog.worksWhenModal = true
                            myFiledialog.title = "#Output Title#".localized()
                            myFiledialog.message = "#Output Msg#".localized()
                            myFiledialog.allowedFileTypes = ["dmg"]
                            myFiledialog.beginWithCompletionHandler{ (result: Int) -> Void in
                                if result == NSFileHandlingPanelOKButton {
                                    if let URL = myFiledialog.URL{
                                        if let Path = URL.path{
                                            if Path != ""{
                                                self.Path = Path
                                                self.Disk.enabled = false
                                            }else{
                                                sender.state = NSOffState
                                            }
                                        }
                                    }
                                }else{
                                    sender.state = NSOffState
                                }
                            }
                            
            })
        }else{
            self.Path = ""
            self.Disk.enabled = true
        }
    }
    @IBAction func WriteDiskClicked(sender: NSButton) {
        if sender.state == NSOnState {
            dispatch_async(dispatch_get_main_queue(),
                           {
                            let myFiledialog = NSOpenPanel()
                            
                            myFiledialog.prompt = "Open"
                            myFiledialog.worksWhenModal = true
                            myFiledialog.canChooseDirectories = true
                            myFiledialog.title = "#Output Title#".localized()
                            myFiledialog.message = "#Output Msg#".localized()
                            myFiledialog.allowedFileTypes = [kUTTypeVolume as String]
                            myFiledialog.directoryURL = NSURL(fileURLWithPath: "/Volumes/")
                            myFiledialog.beginWithCompletionHandler{ (result: Int) -> Void in
                                if result == NSFileHandlingPanelOKButton {
                                    if let URL = myFiledialog.URL{
                                        if let Path = URL.path{
                                            if Path != "" && Path.hasPrefix("/Volumes"){
                                                self.MountPath = Path
                                                self.SizeCustomize.enabled = false
                                                self.Output.enabled = false
                                                self.cdr.enabled = false
                                            }else{
                                                sender.state = NSOffState
                                            }
                                        }
                                    }
                                }else{
                                    sender.state = NSOffState
                                }
                            }
                            
            })
        }else {
            MountPath = ""
            SizeCustomize.enabled = true
            Output.enabled = true
            cdr.enabled = true
        }
    }
	@IBAction func OSInstallerClicked(sender: NSButton) {
        if sender.state == NSOnState {
            dispatch_async(dispatch_get_main_queue(),
                           {
                            let myFiledialog = NSOpenPanel()
                            
                            myFiledialog.prompt = "Open"
                            myFiledialog.worksWhenModal = true
                            myFiledialog.title = "#OSInstaller Title#".localized()
                            myFiledialog.message = "#OSInstaller Msg#".localized()
                            myFiledialog.beginWithCompletionHandler{ (result: Int) -> Void in
                                if result == NSFileHandlingPanelOKButton {
                                    if let URL = myFiledialog.URL{
                                        if let Path = URL.path{
                                            if Path != "" && URL.lastPathComponent!.caseInsensitiveCompare("OSInstaller") == NSComparisonResult.OrderedSame{
                                                self.OSInstallerPath = Path
                                            }else{
                                                sender.state = NSOffState
                                            }
                                        }
                                    }
                                }else{
                                    sender.state = NSOffState
                                }
                            }
                            
            })
        }else {
            OSInstallerPath = ""
        }
	}
    @IBAction func CLTButtonPressed(sender: NSButton) {
        shellCommand.sharedInstance.Command(self,"/bin/sh", ["-c","xcode-select --install"], "", 0)
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
        dispatch_async(dispatch_get_main_queue(),{
            let a = NSAlert()
            a.messageText = results.localized()
            a.runModal()
            exit(0)
        })
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
    func didReceiveInstaller(filePath:String){
        self.filePath.stringValue = filePath
    }
    func didReceiveExtra(filePath:String){
        self.extraPath.stringValue = filePath
    }
}

