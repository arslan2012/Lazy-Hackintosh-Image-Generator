import Cocoa

class ViewController: NSViewController, NSWindowDelegate,BatchProcessAPIProtocol,FileDropZoneProtocol {
    @IBOutlet weak var fileNameField: NSTextField!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var extraFolderNameField: NSTextField!
    @IBOutlet weak var progressLable: NSTextField!
    @IBOutlet weak var start: NSButton!
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
    @IBOutlet weak var OSInstaller: NSButton!
    var buttons:[NSButton] = [],debugLog = false, Path = "",OSInstallerPath = "",InstallerPath = "",extraFolderPath = ""
    
    lazy var api : BatchProcessAPI = BatchProcessAPI()
    
    override func viewDidLoad() {
        delegate = self
        if Command("/usr/bin/xcode-select", ["-p"], "", 0) == 0{
            CLT.isHidden=true
            OSInstaller.isHidden=true
        }
        super.viewDidLoad()
        extra.viewDelegate = self
        Installer.viewDelegate = self
        progress.isHidden = true
        progressLable.isHidden = true
        CustomSize.isHidden = true
        SizeUnit.isHidden = true
        XCPMPatch.state = NSControl.StateValue.off
        cdr.state = NSControl.StateValue.off
        exitButton.isHidden = true
        buttons = [LapicPatch,XCPMPatch,cdr,SizeCustomize,dropKernel,Output,OSInstaller,CLT]
        for button in buttons{
            button.attributedTitle = NSAttributedString(string: (button.title), attributes: [ NSAttributedStringKey.foregroundColor : NSColor.white])
        }
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.delegate = self
        self.view.window!.title = "#Title#".localized()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = CGColor(red: 83/255, green: 87/255, blue: 96/255, alpha: 1);
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        exit(0)
    }
    @IBAction func StartProcessing(_ sender: NSButton) {
        if !(URL(fileURLWithPath:InstallerPath) as NSURL).checkResourceIsReachableAndReturnError(nil){
            let a = NSAlert()
            a.messageText = "#Input is void#".localized()
            a.runModal()
        }else {
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            debugLog = appDelegate.getDebugStatus()
            start.isHidden = true
            CLT.isHidden = true
            progress.isHidden = false
            progressLable.isHidden = false
            progress.startAnimation(self)
            var UsingCustomSize = false
            if SizeCustomize.state == NSControl.StateValue.on && Double(CustomSize.stringValue) != nil {
                if Double(CustomSize.stringValue)! <= 0 || Double(CustomSize.stringValue)! > 100 {
                    let a = NSAlert()
                    a.messageText = "#WRONGSIZE#".localized()
                    a.runModal()
                    exit(0)
                }else{
                    UsingCustomSize = true
                }
            }
            let button = view.window?.standardWindowButton(NSWindow.ButtonType.closeButton)
            button?.isEnabled = false
            for button in buttons{
                button.isEnabled = false
            }
            ////////////////////////////mounting processes////////////////////////
            MountDisks(self.InstallerPath)
            /////////////////////////////////////////////////////////////////////
            api.startGenerating(
                SizeVal: UsingCustomSize ? CustomSize.stringValue : "7.15",
                LapicPatchState: LapicPatch.state == NSControl.StateValue.on,
                XCPMPatchState: XCPMPatch.state == NSControl.StateValue.on,
                cdrState: cdr.state == NSControl.StateValue.on,
                dropKernelState: dropKernel.state == NSControl.StateValue.on,
                extraDroppedFilePath: extraFolderPath,
                Path: Path,
                OSInstallerPath: OSInstallerPath)
        }
    }
    
    @IBAction func XCPMClicked(_ sender: NSButton) {
        if XCPMPatch.state == NSControl.StateValue.on {
            dropKernel.state = NSControl.StateValue.on
        }
    }
    @IBAction func LapicClicked(_ sender: NSButton) {
        if LapicPatch.state == NSControl.StateValue.on {
            dropKernel.state = NSControl.StateValue.on
        }
    }
    @IBAction func dropKernelClicked(_ sender: NSButton) {
        if dropKernel.state == NSControl.StateValue.off {
            XCPMPatch.state = NSControl.StateValue.off
            LapicPatch.state = NSControl.StateValue.off
        }
    }
    @IBAction func SizeClicked(_ sender: NSButton) {
        if SizeCustomize.state == NSControl.StateValue.on {
            CustomSize.isHidden = false
            SizeUnit.isHidden = false
            SizeCustomize.title = ""
            SizeCustomize.state = NSControl.StateValue.on
        }else {
            CustomSize.isHidden = true
            SizeUnit.isHidden = true
            SizeCustomize.attributedTitle = NSAttributedString(string: "#Custom Size#".localized(), attributes: [ NSAttributedStringKey.foregroundColor : NSColor.white])
            SizeCustomize.state = NSControl.StateValue.off
        }
    }
    @IBAction func CustomOutputClicked(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            DispatchQueue.main.async{
                let myFiledialog = NSSavePanel()
                
                myFiledialog.prompt = "Open"
                myFiledialog.worksWhenModal = true
                myFiledialog.title = "#Output Title#".localized()
                myFiledialog.message = "#Output Msg#".localized()
                myFiledialog.allowedFileTypes = ["dmg"]
                myFiledialog.begin{ (result) -> Void in
                    if result.rawValue == NSFileHandlingPanelOKButton {
                        if let URL = myFiledialog.url{
                            let Path = URL.path
                            if Path != ""{
                                self.Path = Path
                            }else{
                                sender.state = NSControl.StateValue.off
                            }
                        }
                    }else{
                        sender.state = NSControl.StateValue.off
                    }
                }
                
            }
        }else{
            self.Path = ""
        }
    }
    @IBAction func OSInstallerClicked(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            DispatchQueue.main.async{
                let myFiledialog = NSOpenPanel()
                
                myFiledialog.prompt = "Open"
                myFiledialog.worksWhenModal = true
                myFiledialog.title = "#OSInstaller Title#".localized()
                myFiledialog.message = "#OSInstaller Msg#".localized()
                myFiledialog.begin{ (result) -> Void in
                    if result.rawValue == NSFileHandlingPanelOKButton {
                        if let URL = myFiledialog.url{
                            let Path = URL.path
                            if Path != "" && URL.lastPathComponent.caseInsensitiveCompare("OSInstaller") == ComparisonResult.orderedSame{
                                self.OSInstallerPath = Path
                            }else{
                                sender.state = NSControl.StateValue.off
                            }
                        }
                    }else{
                        sender.state = NSControl.StateValue.off
                    }
                }
                
            }
        }else {
            OSInstallerPath = ""
        }
    }
    @IBAction func CLTButtonPressed(_ sender: NSButton) {
        Command("/bin/sh", ["-c","xcode-select --install"], "", 0)
    }
    @IBAction func exitButtonPressed(_ sender: NSButton) {
        exit(0)
    }
    func didReceiveProcessName(_ results: String){
        DispatchQueue.main.async{
            self.progressLable.stringValue = results.localized()
        }
    }
    func didReceiveProgress(_ results: Double){
        DispatchQueue.main.async{
            self.progress.increment(by: results)
        }
    }
    func didReceiveErrorMessage(_ results: String){
        DispatchQueue.main.async{
            let a = NSAlert()
            a.messageText = results.localized()
            a.runModal()
            exit(0)
        }
    }
    func didReceiveThreadExitMessage(){
        DispatchQueue.main.async{
            self.progress.stopAnimation(self)
            self.fileNameField.stringValue = ""
            self.exitButton.isHidden = false
            let button = self.view.window?.standardWindowButton(NSWindow.ButtonType.closeButton)
            button?.isEnabled = true
        }
    }
    func didReceiveInstaller(_ filePath:String){
        self.InstallerPath =  filePath
        self.fileNameField.stringValue = NSURL(fileURLWithPath: filePath).lastPathComponent!
    }
    func didReceiveExtra(_ filePath:String){
        self.extraFolderPath = filePath
        self.extraFolderNameField.stringValue = NSURL(fileURLWithPath: filePath).lastPathComponent!
    }
}

