import Cocoa
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    default:
        return !(rhs < lhs)
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


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
    
    lazy var api : BatchProcessAPI = BatchProcessAPI(viewDelegate: self,AppDelegate: NSApplication.shared().delegate as! MenuControlProtocol)
    
    override func viewDidLoad() {
        if shellCommand.sharedInstance.Command(self,"/usr/bin/xcode-select", ["-p"], "", 0) != 0{
            MBRPatch.isEnabled=false
            MBRPatch.state = NSOffState
        }else{
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
        XCPMPatch.state = NSOffState
        cdr.state = NSOffState
        exitButton.isHidden = true
        
        for button in [MBRPatch,LapicPatch,XCPMPatch,cdr,SizeCustomize,dropKernel,Output,Disk,OSInstaller]{
            button?.attributedTitle = NSAttributedString(string: (button?.title)!, attributes: [ NSForegroundColorAttributeName : NSColor.white])
        }
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.delegate = self
        self.view.window!.title = "#Title#".localized()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = CGColor(red: 83/255, green: 87/255, blue: 96/255, alpha: 1);
    }
    func windowShouldClose(_ sender: Any) -> Bool {
        exit(0)
    }
    @IBAction func StartProcessing(_ sender: NSButton) {
        if !(URL(fileURLWithPath:filePath.stringValue) as NSURL).checkResourceIsReachableAndReturnError(nil){
            let a = NSAlert()
            a.messageText = "#Input is void#".localized()
            a.runModal()
        }else {
            let appDelegate = NSApplication.shared().delegate as! AppDelegate
            debugLog = appDelegate.getDebugStatus()
            start.isHidden = true
            CLT.isHidden = true
            progress.isHidden = false
            progressLable.isHidden = false
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
            let button = view.window?.standardWindowButton(NSWindowButton.closeButton)
            button?.isEnabled = false
            for button in [MBRPatch,XCPMPatch,cdr,SizeCustomize,dropKernel,LapicPatch,Disk,Output,OSInstaller,CLT] as [NSButton]{
                button.isEnabled = false
            }
            api.startGenerating(
                filePath.stringValue,
                SizeVal: UsingCustomSize ? CustomSize.stringValue : "7.15",
                MBRPatchState: MBRPatch.state == NSOnState,
                LapicPatchState: LapicPatch.state == NSOnState,
                XCPMPatchState: XCPMPatch.state == NSOnState,
                cdrState: cdr.state == NSOnState,
                dropKernelState: dropKernel.state == NSOnState,
                extraDroppedFilePath: extraPath.stringValue,
                Path: Path,
                MountPath: MountPath,
                OSInstallerPath: OSInstallerPath)
        }
    }
    
    @IBAction func XCPMClicked(_ sender: NSButton) {
        if XCPMPatch.state == NSOnState {
            dropKernel.state = NSOnState
        }
    }
    @IBAction func LapicClicked(_ sender: NSButton) {
        if LapicPatch.state == NSOnState {
            dropKernel.state = NSOnState
        }
    }
    @IBAction func dropKernelClicked(_ sender: NSButton) {
        if dropKernel.state == NSOffState {
            XCPMPatch.state = NSOffState
            LapicPatch.state = NSOffState
        }
    }
    @IBAction func SizeClicked(_ sender: NSButton) {
        if SizeCustomize.state == NSOnState {
            CustomSize.isHidden = false
            SizeUnit.isHidden = false
            SizeCustomize.title = ""
            SizeCustomize.state = NSOnState
        }else {
            CustomSize.isHidden = true
            SizeUnit.isHidden = true
            SizeCustomize.attributedTitle = NSAttributedString(string: "#Custom Size#".localized(), attributes: [ NSForegroundColorAttributeName : NSColor.white])
            SizeCustomize.state = NSOffState
        }
    }
    @IBAction func CustomOutputClicked(_ sender: NSButton) {
        if sender.state == NSOnState {
            DispatchQueue.main.async{
                let myFiledialog = NSSavePanel()
                
                myFiledialog.prompt = "Open"
                myFiledialog.worksWhenModal = true
                myFiledialog.title = "#Output Title#".localized()
                myFiledialog.message = "#Output Msg#".localized()
                myFiledialog.allowedFileTypes = ["dmg"]
                myFiledialog.begin{ (result: Int) -> Void in
                    if result == NSFileHandlingPanelOKButton {
                        if let URL = myFiledialog.url{
                            let Path = URL.path
                            if Path != ""{
                                self.Path = Path
                                self.Disk.isEnabled = false
                            }else{
                                sender.state = NSOffState
                            }
                        }
                    }else{
                        sender.state = NSOffState
                    }
                }
                
            }
        }else{
            self.Path = ""
            self.Disk.isEnabled = true
        }
    }
    @IBAction func WriteDiskClicked(_ sender: NSButton) {
        if sender.state == NSOnState {
            DispatchQueue.main.async{
                let myFiledialog = NSOpenPanel()
                
                myFiledialog.prompt = "Open"
                myFiledialog.worksWhenModal = true
                myFiledialog.canChooseDirectories = true
                myFiledialog.title = "#Output Title#".localized()
                myFiledialog.message = "#Output Msg#".localized()
                myFiledialog.allowedFileTypes = [kUTTypeVolume as String]
                myFiledialog.directoryURL = URL(fileURLWithPath: "/Volumes/")
                myFiledialog.begin{ (result: Int) -> Void in
                    if result == NSFileHandlingPanelOKButton {
                        if let URL = myFiledialog.url{
                            let Path = URL.path
                            if Path != "" && Path.hasPrefix("/Volumes"){
                                self.MountPath = Path
                                self.SizeCustomize.isEnabled = false
                                self.Output.isEnabled = false
                                self.cdr.isEnabled = false
                            }else{
                                sender.state = NSOffState
                            }
                        }
                    }else{
                        sender.state = NSOffState
                    }
                }
                
            }
        }else {
            MountPath = ""
            SizeCustomize.isEnabled = true
            Output.isEnabled = true
            cdr.isEnabled = true
        }
    }
    @IBAction func OSInstallerClicked(_ sender: NSButton) {
        if sender.state == NSOnState {
            DispatchQueue.main.async{
                let myFiledialog = NSOpenPanel()
                
                myFiledialog.prompt = "Open"
                myFiledialog.worksWhenModal = true
                myFiledialog.title = "#OSInstaller Title#".localized()
                myFiledialog.message = "#OSInstaller Msg#".localized()
                myFiledialog.begin{ (result: Int) -> Void in
                    if result == NSFileHandlingPanelOKButton {
                        if let URL = myFiledialog.url{
                            let Path = URL.path
                            if Path != "" && URL.lastPathComponent.caseInsensitiveCompare("OSInstaller") == ComparisonResult.orderedSame{
                                self.OSInstallerPath = Path
                            }else{
                                sender.state = NSOffState
                            }
                        }
                    }else{
                        sender.state = NSOffState
                    }
                }
                
            }
        }else {
            OSInstallerPath = ""
        }
    }
    @IBAction func CLTButtonPressed(_ sender: NSButton) {
        shellCommand.sharedInstance.Command(self,"/bin/sh", ["-c","xcode-select --install"], "", 0)
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
            self.filePath.stringValue = ""
            self.exitButton.isHidden = false
            let button = self.view.window?.standardWindowButton(NSWindowButton.closeButton)
            button?.isEnabled = true
        }
    }
    func didReceiveInstaller(_ filePath:String){
        self.filePath.stringValue = filePath
    }
    func didReceiveExtra(_ filePath:String){
        self.extraPath.stringValue = filePath
    }
}

