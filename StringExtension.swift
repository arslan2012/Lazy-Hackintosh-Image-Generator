//
//  StringExtension.swift
//  LazyHackintoshGenerator
//
//  Created by ئ‍ارسلان ئابلىكىم on 2/6/16.
//  Copyright © 2016 PCBETA. All rights reserved.
//

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
}