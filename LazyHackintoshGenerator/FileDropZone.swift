import Cocoa
protocol FileDropZoneProtocol: class {
    func didReceiveInstaller(_ filePath:String)
    func didReceiveExtra(_ filePath:String)
}
class FileDropZone: NSImageView {
    weak var viewDelegate: FileDropZoneProtocol?
    let icnSize = NSMakeSize(CGFloat(100), CGFloat(100))
    var icn:NSImage? {
        return nil
    }
    var fileTypes:[String] {
        return []
    }
    var isDirectories:Bool {
        return false
    }
    var droppedFilePath = ""
    var fileTypeIsOk = false
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        register(forDraggedTypes: [NSFilenamesPboardType, NSURLPboardType, NSPasteboardTypeTIFF])
        icn!.size = self.icnSize
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
        if let board = drag.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray,
            let path = board[0] as? String {
            let url = URL(fileURLWithPath: path)
            if self.isDirectories {
                let suffix = url.lastPathComponent
                var isDirectory: ObjCBool = ObjCBool(false)
                FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
                for ext in self.fileTypes {
                    if isDirectory.boolValue && suffix.caseInsensitiveCompare(ext) == ComparisonResult.orderedSame{
                        return true
                    }
                }
            }else {
                let suffix = url.pathExtension
                for ext in self.fileTypes {
                    if ext.lowercased() == suffix {
                        return true
                    }
                }
            }
        }
        return false
    }
}
class InstallerDrop: FileDropZone {
    override var icn:NSImage? {
        return NSImage(named:"image")!
    }
    override var fileTypes:[String] {
        return ["dmg","app"]
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo?) {
        if self.fileTypeIsOk && self.droppedFilePath != ""{
            viewDelegate!.didReceiveInstaller(self.droppedFilePath)
            let icn = NSImage(named:"icon-osx")
            icn?.size = self.icnSize
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
                        icn?.size = self.icnSize
                        self.image = icn
                    }
                }
            })
        }
    }
}
class ExtraDrop : FileDropZone{
    override var icn:NSImage? {
        return NSImage(named:"drive")!
    }
    override var fileTypes:[String] {
        return ["extra"]
    }
    override var isDirectories:Bool {
        return true
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo?) {
        if self.droppedFilePath != "" && self.fileTypeIsOk{
            viewDelegate!.didReceiveExtra(self.droppedFilePath)
            let icn = NSImage(named:"Chameleon")
            icn?.size = self.icnSize
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
                        let icn = NSImage(named:"Chameleon")
                        icn?.size = self.icnSize
                        self.image = icn
                    }
                    
                }
                
            })
        }
    }
}
