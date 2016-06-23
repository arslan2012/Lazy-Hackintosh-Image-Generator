//
//  AppDelegate.swift
//  LazyHackintoshGenerator
//
//  Created by ئ‍ارسلان ئابلىكىم on 2/5/16.
//  Copyright © 2016 PCBETA. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	
	lazy var debugStatus = false
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
	
	@IBAction func DebugMenuPressed(sender: NSMenuItem) {
		if sender.title == "#Debug On#".localized(){
			sender.title = "#Debug Off#".localized()
			debugStatus = true
		}else {
			sender.title = "#Debug On#".localized()
			debugStatus = false
		}
	}
	
	func getDebugStatus() ->Bool{
		return debugStatus
	}
	
}

