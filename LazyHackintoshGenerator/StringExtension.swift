import Foundation
extension String {
    func localized() -> String {
		return NSLocalizedString(self,comment:self)
    }
    func SysVerBiggerThan(version:String) -> Bool{
        return version.componentsSeparatedByString(".")
            .map {
                Int.init($0) ?? 0
            }
            .lexicographicalCompare(
                self.componentsSeparatedByString(".")
                    .map {
                        Int.init($0) ?? 0
                })
    }
    func SysBuildVerBiggerThan(compare:String) -> Bool{
        var thisVer: [Int] = []
        let thisVerChars = Array(characters)
        thisVer.append(Int(String(thisVerChars[0..<2]))!)
        thisVer.append(Int(NSString(string: String(thisVerChars[2..<3])).characterAtIndex(0)))
        thisVer.append(Int(String(thisVerChars[3..<(thisVerChars.count-1)]))!)
        
        var compareVer: [Int] = []
        let compareVerChars = Array(compare.characters)
        compareVer.append(Int(String(compareVerChars[0..<2]))!)
        compareVer.append(Int(NSString(string: String(compareVerChars[2..<3])).characterAtIndex(0)))
        compareVer.append(Int(String(compareVerChars[3..<(compareVerChars.count-1)]))!)
        return compareVer.lexicographicalCompare(thisVer)
    }
	func appendLineToURL(fileURL: NSURL) throws {
		try self.stringByAppendingString("\n").appendToURL(fileURL)
	}
	
	func appendToURL(fileURL: NSURL) throws {
		let data = self.dataUsingEncoding(NSUTF8StringEncoding)!
		try data.appendToURL(fileURL)
	}
}

extension NSData {
	func appendToURL(fileURL: NSURL) throws {
		if let fileHandle = try? NSFileHandle(forWritingToURL: fileURL) {
			defer {
				fileHandle.closeFile()
			}
			fileHandle.seekToEndOfFile()
			fileHandle.writeData(self)
		}
		else {
			try writeToURL(fileURL, options: .DataWritingAtomic)
		}
	}
}