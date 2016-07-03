import Foundation
extension String {
    func localized() -> String {
		return NSLocalizedString(self,comment:self)
    }
	func versionToInt() -> [Int] {
		return self.componentsSeparatedByString(".")
			.map {
				Int.init($0) ?? 0
		}
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