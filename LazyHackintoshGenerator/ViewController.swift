import Cocoa

class ViewController: NSViewController, NSWindowDelegate, BatchProcessAPIProtocol, FileDropZoneProtocol {
    @IBOutlet weak var fileNameField: NSTextField!
    @IBOutlet weak var dropKernel: NSButton!
    @IBOutlet weak var Output: NSButton!
    @IBOutlet weak var start: NSButton!
    @IBOutlet weak var extraFolderNameField: NSTextField!
    @IBOutlet weak var SizeCustomize: NSButton!
    @IBOutlet weak var CLT: NSButton! {
        didSet {
            CLT.isHidden = true
        }
    }
    @IBOutlet weak var OSInstaller: NSButton! {
        didSet {
            OSInstaller.isHidden = true
        }
    }
    @IBOutlet weak var progress: NSProgressIndicator! {
        didSet {
            progress.isHidden = true
        }
    }
    @IBOutlet weak var progressLable: NSTextField! {
        didSet {
            progressLable.isHidden = true
        }
    }
    @IBOutlet weak var cdr: NSButton! {
        didSet {
            cdr.state = NSControl.StateValue.off
        }
    }
    @IBOutlet weak var Installer: FileDropZone! {
        didSet {
            Installer.viewDelegate = self
        }
    }
    @IBOutlet weak var extra: FileDropZone! {
        didSet {
            extra.viewDelegate = self
        }
    }
    @IBOutlet weak var CustomSize: NSTextField! {
        didSet {
            CustomSize.isHidden = true
        }
    }
    @IBOutlet weak var SizeUnit: NSTextField! {
        didSet {
            SizeUnit.isHidden = true
        }
    }
    @IBOutlet weak var exitButton: NSButton! {
        didSet {
            exitButton.isHidden = true
        }
    }
    var buttons: [NSButton] = [], Path = "", OSInstallerPath = "", InstallerPath = "", extraFolderPath = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        viewController = self
        ShellCommand.shared.run("/usr/bin/xcode-select", ["-p"], "", 0, "")
                .subscribe(onNext: { exitCode in
                    if exitCode != 0 {
                        self.CLT.isHidden = false
                        self.OSInstaller.isHidden = false
                    }
                })
        buttons = [cdr, SizeCustomize, dropKernel, Output, OSInstaller]
        for button in buttons {
            button.attributedTitle = NSAttributedString(string: (button.title), attributes: [NSAttributedString.Key.foregroundColor: NSColor.white])
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.delegate = self
        self.view.window!.title = "#Title#".localized()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = CGColor(red: 83 / 255, green: 87 / 255, blue: 96 / 255, alpha: 1);
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        exit(0)
    }

    @IBAction func StartProcessing(_ sender: NSButton) {
        let size = CustomSize.doubleValue
        if InstallerPath == "" || !(URL(fileURLWithPath: InstallerPath) as NSURL).checkResourceIsReachableAndReturnError(nil) {
            let a = NSAlert()
            a.messageText = "#Input is void#".localized()
            a.runModal()
        } else if SizeCustomize.state == NSControl.StateValue.on && !(1...100 ~= size) {
            let a = NSAlert()
            a.messageText = "#WRONGSIZE#".localized()
            a.runModal()
        } else {
            start.isHidden = true
            CLT.isHidden = true
            progress.isHidden = false
            progressLable.isHidden = false
            progress.startAnimation(self)
            let closeButton = view.window?.standardWindowButton(NSWindow.ButtonType.closeButton)
            closeButton?.isEnabled = false
            for button in buttons {
                button.isEnabled = false
            }
            workFlow(
                    InstallerPath: InstallerPath,
                    SizeVal: SizeCustomize.state == NSControl.StateValue.on ? CustomSize.stringValue : "7.15",
                    cdrState: cdr.state == NSControl.StateValue.on,
                    dropKernelState: dropKernel.state == NSControl.StateValue.on,
                    extraDroppedFilePath: extraFolderPath,
                    Path: Path,
                    OSInstallerPath: OSInstallerPath
            )
        }
    }

    @IBAction func SizeClicked(_ sender: NSButton) {
        if SizeCustomize.state == NSControl.StateValue.on {
            CustomSize.isHidden = false
            SizeUnit.isHidden = false
            SizeCustomize.title = ""
            SizeCustomize.state = NSControl.StateValue.on
        } else {
            CustomSize.isHidden = true
            SizeUnit.isHidden = true
            SizeCustomize.attributedTitle = NSAttributedString(string: "#Custom Size#".localized(), attributes: [NSAttributedString.Key.foregroundColor: NSColor.white])
            SizeCustomize.state = NSControl.StateValue.off
        }
    }

    @IBAction func CustomOutputClicked(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            DispatchQueue.main.async {
                let myFiledialog = NSSavePanel()

                myFiledialog.prompt = "Open"
                myFiledialog.worksWhenModal = true
                myFiledialog.title = "#Output Title#".localized()
                myFiledialog.message = "#Output Msg#".localized()
                myFiledialog.allowedFileTypes = ["dmg"]
                myFiledialog.begin { (result) -> Void in
                    if result.rawValue == NSFileHandlingPanelOKButton {
                        if let URL = myFiledialog.url {
                            let Path = URL.path
                            if Path != "" {
                                self.Path = Path
                            } else {
                                sender.state = NSControl.StateValue.off
                            }
                        }
                    } else {
                        sender.state = NSControl.StateValue.off
                    }
                }

            }
        } else {
            self.Path = ""
        }
    }

    @IBAction func OSInstallerClicked(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            DispatchQueue.main.async {
                let myFiledialog = NSOpenPanel()

                myFiledialog.prompt = "Open"
                myFiledialog.worksWhenModal = true
                myFiledialog.title = "#OSInstaller Title#".localized()
                myFiledialog.message = "#OSInstaller Msg#".localized()
                myFiledialog.begin { (result) -> Void in
                    if result.rawValue == NSFileHandlingPanelOKButton {
                        if let URL = myFiledialog.url {
                            let Path = URL.path
                            if Path != "" && URL.lastPathComponent.caseInsensitiveCompare("OSInstaller") == ComparisonResult.orderedSame {
                                self.OSInstallerPath = Path
                            } else {
                                sender.state = NSControl.StateValue.off
                            }
                        }
                    } else {
                        sender.state = NSControl.StateValue.off
                    }
                }

            }
        } else {
            OSInstallerPath = ""
        }
    }

    @IBAction func CLTButtonPressed(_ sender: NSButton) {
        ShellCommand.shared.run("/bin/sh", ["-c", "xcode-select --install"], "", 0).subscribe(onNext: { exitCode in
            if exitCode != 0 {
                let a = NSAlert()
                a.messageText = "#CLTFAILED#".localized()
                a.runModal()
            }
        })
    }

    @IBAction func exitButtonPressed(_ sender: NSButton) {
        exit(0)
    }

    func didReceiveProcessName(_ results: String) {
        DispatchQueue.main.async {
            self.progressLable.stringValue = results.localized()
        }
    }

    func didReceiveProgress(_ results: Double) {
        DispatchQueue.main.async {
            self.progress.increment(by: results)
        }
    }

    func didReceiveErrorMessage(_ results: String) {
        DispatchQueue.main.async {
            let a = NSAlert()
            a.messageText = results.localized()
            a.runModal()
            exit(0)
        }
    }

    func didReceiveThreadExitMessage() {
        DispatchQueue.main.async {
            self.progress.doubleValue = 100
            self.progress.stopAnimation(self)
            self.fileNameField.stringValue = ""
            self.exitButton.isHidden = false
            let button = self.view.window?.standardWindowButton(NSWindow.ButtonType.closeButton)
            button?.isEnabled = true
        }
    }

    func didReceiveInstaller(_ filePath: String) {
        self.InstallerPath = filePath
        self.fileNameField.stringValue = NSURL(fileURLWithPath: filePath).lastPathComponent!
    }

    func didReceiveExtra(_ filePath: String) {
        self.extraFolderPath = filePath
        self.extraFolderNameField.stringValue = NSURL(fileURLWithPath: filePath).lastPathComponent!
    }
}

