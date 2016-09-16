import Cocoa
protocol FileDropZoneProtocol: class {
    func didReceiveInstaller(_ filePath:String)
    func didReceiveExtra(_ filePath:String)
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
        register(forDraggedTypes: [NSFilenamesPboardType, NSURLPboardType, NSPasteboardTypeTIFF])
        icn!.size = NSMakeSize(CGFloat(100), CGFloat(100))
        self.image = icn
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if checkExtension(sender) == true {
            self.fileTypeIsOk = true
            return .copy
        } else {
            self.fileTypeIsOk = false
            return NSDragOperation()
        }
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if self.fileTypeIsOk {
            return .copy
        } else {
            return NSDragOperation()
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
            if let imagePath = board[0] as? String {
                self.droppedFilePath = imagePath
                return true
            }
        }
        return false
    }
    
    func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        preconditionFailure("This method must be overridden")
    }
}
class InstallerDrop: FileDropZone {
    
    let fileTypes = ["dmg","app"]
    override var icn:NSImage? {
        return NSImage(named:"image")!
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo?) {
        if self.fileTypeIsOk && self.droppedFilePath != ""{
            viewDelegate!.didReceiveInstaller(self.droppedFilePath)
            let icn = NSImage(named:"icon-osx")
            icn?.size = NSMakeSize(CGFloat(100), CGFloat(100))
            self.image = icn
        }
    }
    
    override func mouseDown(with theEvent : NSEvent) {
        let clickCount = theEvent.clickCount
        if clickCount > 1 {
            DispatchQueue.main.async(execute: {
                let myFiledialog = NSOpenPanel()
                
                myFiledialog.prompt = "Open"
                myFiledialog.worksWhenModal = true
                myFiledialog.allowsMultipleSelection = false
                myFiledialog.resolvesAliases = true
                myFiledialog.title = "#Image Title#".localized()
                myFiledialog.message = "#Image Msg#".localized()
                myFiledialog.allowedFileTypes = ["dmg","app"]
                myFiledialog.runModal()
                
                if let URL = myFiledialog.url{
                    let Path = URL.path
                    if Path != ""{
                        self.viewDelegate!.didReceiveInstaller(Path)
                        let icn = NSImage(named:"icon-osx")
                        icn?.size = NSMakeSize(CGFloat(100), CGFloat(100))
                        self.image = icn
                    }
                }
            })
        }
    }
    
    override func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        if let board = drag.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray,
            let path = board[0] as? String {
            let url = URL(fileURLWithPath: path)
            let suffix = url.pathExtension
            for ext in self.fileTypes {
                if ext.lowercased() == suffix {
                    return true
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
    
    override func draggingEnded(_ sender: NSDraggingInfo?) {
        if self.droppedFilePath != "" && self.fileTypeIsOk{
            viewDelegate!.didReceiveExtra(self.droppedFilePath)
            let icn = NSImage(named:"Chameleon")
            icn?.size = NSMakeSize(CGFloat(100), CGFloat(100))
            self.image = icn
        }
    }
    
    override func mouseDown(with theEvent : NSEvent) {
        let clickCount = theEvent.clickCount
        if clickCount > 1 {
            DispatchQueue.main.async(execute: {
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
                
                if let URL = myFiledialog.url{
                    let Path = URL.path
                    if Path != "" && URL.lastPathComponent.caseInsensitiveCompare("extra") == ComparisonResult.orderedSame{
                        self.viewDelegate!.didReceiveExtra(Path)
                        let icn = NSImage(named:"icon-osx")
                        icn?.size = NSMakeSize(CGFloat(100), CGFloat(100))
                        self.image = icn
                    }
                    
                }
                
            })
        }
    }
    
    override func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        if let board = drag.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray,
            let path = board[0] as? String {
            let url = URL(fileURLWithPath: path)
            let suffix = url.lastPathComponent
            var isDirectory: ObjCBool = ObjCBool(false)
            FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            if isDirectory.boolValue && suffix.caseInsensitiveCompare("extra") == ComparisonResult.orderedSame{
                return true
            }
        }
        return false
    }
}
