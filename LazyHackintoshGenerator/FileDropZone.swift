import Cocoa
protocol FileDropZoneProtocol: class {
    func didReceiveInstaller(filePath:String)
    func didReceiveExtra(filePath:String)
}
class FileDropZone: NSImageView {
    weak var viewDelegate: FileDropZoneProtocol?
    var icn:NSImage? {
        return nil
    }
    var droppedFilePath = ""
    var fileTypeIsOk = false
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([NSFilenamesPboardType, NSURLPboardType, NSPasteboardTypeTIFF])
        icn!.size = NSMakeSize(CGFloat(100), CGFloat(100))
        self.image = icn
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
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
        preconditionFailure("This method must be overridden")
    }
}
class InstallerDrop: FileDropZone {
    
    let fileTypes = ["dmg","app"]
    override var icn:NSImage? {
        return NSImage(named:"image")!
    }
    
    override func draggingEnded(sender: NSDraggingInfo?) {
        if self.fileTypeIsOk && self.droppedFilePath != ""{
            viewDelegate!.didReceiveInstaller(self.droppedFilePath)
            let icn = NSImage(named:"icon-osx")
            icn?.size = NSMakeSize(CGFloat(100), CGFloat(100))
            self.image = icn
        }
    }
    
    override func mouseDown(theEvent : NSEvent) {
        let clickCount = theEvent.clickCount
        if clickCount > 1 {
            dispatch_async(dispatch_get_main_queue(),
                           {
                            let myFiledialog = NSOpenPanel()
                            
                            myFiledialog.prompt = "Open"
                            myFiledialog.worksWhenModal = true
                            myFiledialog.allowsMultipleSelection = false
                            myFiledialog.resolvesAliases = true
                            myFiledialog.title = "#Image Title#".localized()
                            myFiledialog.message = "#Image Msg#".localized()
                            myFiledialog.allowedFileTypes = ["dmg","app"]
                            myFiledialog.runModal()
                            
                            if let URL = myFiledialog.URL{
                                if let Path = URL.path{
                                    if Path != ""{
                                        self.viewDelegate!.didReceiveInstaller(Path)
                                        let icn = NSImage(named:"icon-osx")
                                        icn?.size = NSMakeSize(CGFloat(100), CGFloat(100))
                                        self.image = icn
                                    }
                                }
                            }
                            
            })
        }
    }
    
    override func checkExtension(drag: NSDraggingInfo) -> Bool {
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
class ExtraDrop : FileDropZone{
    override var icn:NSImage? {
        return NSImage(named:"drive")!
    }
    
    override func draggingEnded(sender: NSDraggingInfo?) {
        if self.droppedFilePath != "" && self.fileTypeIsOk{
            viewDelegate!.didReceiveExtra(self.droppedFilePath)
            let icn = NSImage(named:"Chameleon")
            icn?.size = NSMakeSize(CGFloat(100), CGFloat(100))
            self.image = icn
        }
    }
    
    override func mouseDown(theEvent : NSEvent) {
        let clickCount = theEvent.clickCount
        if clickCount > 1 {
            dispatch_async(dispatch_get_main_queue(),
                           {
                            let myFiledialog = NSOpenPanel()
                            
                            myFiledialog.prompt = "Open"
                            myFiledialog.worksWhenModal = true
                            myFiledialog.allowsMultipleSelection = true
                            myFiledialog.canChooseDirectories = true
                            myFiledialog.canChooseFiles = false
                            myFiledialog.resolvesAliases = true
                            myFiledialog.title = "#Extra Title#".localized()
                            myFiledialog.message = "#Extra Msg#".localized()
                            myFiledialog.allowedFileTypes = ["extra"]
                            myFiledialog.runModal()
                            
                            if let URL = myFiledialog.URL{
                                if let Path = URL.path{
                                    if Path != "" && URL.lastPathComponent!.caseInsensitiveCompare("extra") == NSComparisonResult.OrderedSame{
                                        self.viewDelegate!.didReceiveExtra(Path)
                                        let icn = NSImage(named:"icon-osx")
                                        icn?.size = NSMakeSize(CGFloat(100), CGFloat(100))
                                        self.image = icn
                                    }
                                }
                            }
                            
            })
        }
    }
    
    override func checkExtension(drag: NSDraggingInfo) -> Bool {
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