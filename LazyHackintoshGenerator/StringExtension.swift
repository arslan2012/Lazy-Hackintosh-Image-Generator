import Foundation
extension String {
    func localized() -> String {
        return NSLocalizedString(self,comment:self)
    }
    func SysVerBiggerThan(_ version:String) -> Bool{
        return version.components(separatedBy: ".")
            .map {
                Int.init($0) ?? 0
            }
            .lexicographicallyPrecedes(
                self.components(separatedBy: ".")
                    .map {
                        Int.init($0) ?? 0
            })
    }
    func SysBuildVerBiggerThan(_ compare:String) -> Bool{
        var thisVer: [Int] = [],compareVer: [Int] = []
        let thisVerChars = Array(characters),compareVerChars = Array(compare.characters)
        
        var previousIndex = 0
        for (index,char) in thisVerChars.enumerated(){
            if !("0"..."9" ~= char) {
                thisVer.append(Int(String(thisVerChars[previousIndex..<index]))!)
                thisVer.append(Int(NSString(string: String(thisVerChars[index..<index+1])).character(at: 0)))
                previousIndex = index+1
            }
        }
        if previousIndex != thisVerChars.count {
            thisVer.append(Int(String(thisVerChars[previousIndex..<thisVerChars.count]))!)
        }
        
        previousIndex = 0
        for (index,char) in compareVerChars.enumerated(){
            if !("0"..."9" ~= char) {
                compareVer.append(Int(String(compareVerChars[previousIndex..<index]))!)
                compareVer.append(Int(NSString(string: String(compareVerChars[index..<index+1])).character(at: 0)))
                previousIndex = index+1
            }
        }
        if previousIndex != compareVerChars.count {
            compareVer.append(Int(String(compareVerChars[previousIndex..<thisVerChars.count]))!)
        }
        return compareVer.lexicographicallyPrecedes(thisVer)
    }
    func appendLineToURL(_ fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL)
    }
    
    func appendToURL(_ fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.appendToURL(fileURL)
    }
}

extension Data {
    func appendToURL(_ fileURL: URL) throws {
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
func Logger(_ log:String){
    do{
        try log.appendLineToURL(URL(fileURLWithPath:"\(NSHomeDirectory())/Desktop/Lazy log.txt"))
    }catch{}
}
