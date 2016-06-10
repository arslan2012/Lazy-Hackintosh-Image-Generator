//
//  ViewController.swift
//  LazyHackintoshGenerator
//
//  Created by ئ‍ارسلان ئابلىكىم on 2/5/16.
//  Copyright © 2016 PCBETA. All rights reserved.
//

import Cocoa

class ViewController: NSViewController,BatchProcessAPIProtocol {
    @IBOutlet weak var filePath: NSTextField!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var progressLable: NSTextField!
    @IBOutlet weak var kernel: OtherFileDrop!
    @IBOutlet weak var start: NSButton!
    @IBOutlet weak var MBRPatch: NSButton!
    @IBOutlet weak var XCPMPatch: NSButton!
    @IBOutlet weak var cdr: NSButton!
    @IBOutlet weak var extra: OtherFileDrop!
    @IBOutlet weak var SizeCustomize: NSButton!
    @IBOutlet weak var CustomSize: NSTextField!
    @IBOutlet weak var SizeUnit: NSTextField!
	@IBOutlet weak var exitButton: NSButton!
    var language: String?
	lazy var api : BatchProcessAPI = BatchProcessAPI(delegate: self)
    let concurrentInsertingQueue = dispatch_queue_create("kext inserting", DISPATCH_QUEUE_CONCURRENT)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        language = NSLocale.preferredLanguages()[0]
        if self.language != "zh-Hans" || self.language != "en" || self.language != "ja" {
            self.language = "en"
        }
        progress.hidden = true
        progressLable.hidden = true
        CustomSize.hidden = true
        SizeUnit.hidden = true
        XCPMPatch.state = NSOffState
        cdr.state = NSOffState
		exitButton.hidden = true
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window!.title = "#TITLE#".localized(self.language!)
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    @IBAction func StartProcessing(sender: NSButton) {
        if NSURL(fileURLWithPath:filePath.stringValue).checkResourceIsReachableAndReturnError(nil){
			start.hidden = true
			progress.hidden = false
			progressLable.hidden = false
			progress.startAnimation(self)
			var UsingCustomSize = false
			if SizeCustomize.state == NSOnState {
				if Double(CustomSize.stringValue) <= 0 || Double(CustomSize.stringValue) > 100 {
					let a = NSAlert()
					a.messageText = "#WRONGSIZE#".localized(self.language!)
					a.runModal()
					exit(0)
				}else{
					UsingCustomSize = true
				}
			}
			var SizeVal = "7.65"
			if UsingCustomSize {
				SizeVal = CustomSize.stringValue
			}
			let MBRPatchState = (MBRPatch.state == NSOnState) ? true : false
			let XCPMPatchState = (XCPMPatch.state == NSOnState) ? true : false
			let cdrState = (cdr.state == NSOnState) ? true : false
			api.startGenerating(filePath.stringValue,SizeVal: SizeVal,MBRPatchState: MBRPatchState,XCPMPatchState: XCPMPatchState,cdrState: cdrState,kernelDroppedFilePath: kernel.droppedFilePath,extraDroppedFilePath: extra.droppedFilePath)
			
			progress.stopAnimation(self)
			filePath.stringValue = ""
			exitButton.hidden = false
        }else{
            let a = NSAlert()
            a.messageText = "#INPUTVOID#".localized(self.language!)
            a.runModal()
        }
        //        do {
        //            try NSURL(fileURLWithPath:filePath.stringValue).checkResourceIsReachableAndReturnError(nil)
        //        }catch{
        //                        let a = NSAlert()
        //                        a.messageText = "#INPUTVOID#".localized(self.language!)
        //                        a.runModal()
        //        }
    }
    @IBAction func XCPMClicked(sender: NSButton) {
        if XCPMPatch.state == NSOnState {
            if kernel.droppedFilePath == "" {
                let a = NSAlert()
                a.messageText = "#NOKERNEL#".localized(self.language!)
                a.runModal()
                XCPMPatch.state = NSOffState
            }
        }
    }
    @IBAction func SizeClicked(sender: NSButton) {
        if SizeCustomize.state == NSOnState {
            CustomSize.hidden = false
            SizeUnit.hidden = false
        }else {
            CustomSize.hidden = true
            SizeUnit.hidden = true
        }
    }
	@IBAction func exitButtonPressed(sender: NSButton) {
		exit(0)
	}
	func didReceiveProcessName(results: String){
		dispatch_sync(self.concurrentInsertingQueue,{
			self.progressLable.stringValue = results.localized(self.language!)
		})
	}
	func didReceiveProgress(results: Double){
		dispatch_sync(self.concurrentInsertingQueue,{
			self.progress.incrementBy(results)
		})
	}
	func didReceiveErrorMessage(results: String){
		let a = NSAlert()
		a.messageText = results.localized(self.language!)
		a.runModal()
		exit(0)
	}
}

