import Cocoa

class FileDropZone: NSImageView {
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
    }
    
    let fileTypes = ["dmg","app"]
    var fileTypeIsOk = false
    var droppedFilePath = ""
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([NSFilenamesPboardType, NSURLPboardType, NSPasteboardTypeTIFF])
		let icn = NSImage(named:"image")
		icn?.size = NSMakeSize(CGFloat(100), CGFloat(100))
		self.image = icn
    }
    
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        if checkExtension(sender) == true {
            self.fileTypeIsOk = true
            return .Copy
        } else {
            self.fileTypeIsOk = false
            return .None
        }
    }
    
    override func draggingUpdated(sender: NSDraggingInfo) -> NSDragOperation {
        if self.fileTypeIsOk {
            return .Copy
        } else {
            return .None
        }
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        if let board = sender.draggingPasteboard().propertyListForType("NSFilenamesPboardType") as? NSArray {
            if let imagePath = board[0] as? String {
                self.droppedFilePath = imagePath
                return true
            }
        }
        return false
    }
    override func draggingEnded(sender: NSDraggingInfo?) {
        if self.fileTypeIsOk && self.droppedFilePath != ""{
            let view = self.superview!.nextResponder! as! ViewController
            view.filePath.stringValue = self.droppedFilePath
				let icn = NSImage(named:"icon-osx")
				icn?.size = NSMakeSize(CGFloat(100), CGFloat(100))
				self.image = icn
        }
    }
    
    func checkExtension(drag: NSDraggingInfo) -> Bool {
        if let board = drag.draggingPasteboard().propertyListForType("NSFilenamesPboardType") as? NSArray,
            let path = board[0] as? String {
                let url = NSURL(fileURLWithPath: path)
                if let suffix = url.pathExtension {
                    for ext in self.fileTypes {
                        if ext.lowercaseString == suffix {
                            return true
                        }
                    }
                }
        }
        return false
    }
    
}
class OtherFileDrop : NSImageView{
    var droppedFilePath = ""
	var fileTypeIsOk = false

    override func draggingEnded(sender: NSDraggingInfo?) {
        if self.droppedFilePath != "" && self.fileTypeIsOk{
			let view = self.superview!.nextResponder! as! ViewController
			view.extraPath.stringValue = self.droppedFilePath
			let icn = NSImage(named:"Chameleon")
			icn?.size = NSMakeSize(CGFloat(100), CGFloat(100))
			self.image = icn
        }
    }
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([NSFilenamesPboardType, NSURLPboardType, NSPasteboardTypeTIFF])
		let icn = NSImage(named:"drive")
		icn?.size = NSMakeSize(CGFloat(100), CGFloat(100))
		self.image = icn
    }
    
	override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
		if checkExtension(sender) == true {
			self.fileTypeIsOk = true
			return .Copy
		} else {
			self.fileTypeIsOk = false
			return .None
		}
	}
	
	override func draggingUpdated(sender: NSDraggingInfo) -> NSDragOperation {
		if self.fileTypeIsOk {
			return .Copy
		} else {
			return .None
		}
	}
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        if let board = sender.draggingPasteboard().propertyListForType("NSFilenamesPboardType") as? NSArray {
            if let imagePath = board[0] as? String {
                self.droppedFilePath = imagePath
                return true
            }
        }
        return false
    }
	
	func checkExtension(drag: NSDraggingInfo) -> Bool {
		if let board = drag.draggingPasteboard().propertyListForType("NSFilenamesPboardType") as? NSArray,
			let path = board[0] as? String {
			let url = NSURL(fileURLWithPath: path)
			if let suffix = url.lastPathComponent {
				var isDirectory: ObjCBool = ObjCBool(false)
				NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDirectory)
					if isDirectory && suffix.caseInsensitiveCompare("extra") == NSComparisonResult.OrderedSame{
						return true
					}
			}
		}
		return false
	}
}