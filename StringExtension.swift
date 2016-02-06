//
//  StringExtension.swift
//  LazyHackintoshGenerator
//
//  Created by ئ‍ارسلان ئابلىكىم on 2/6/16.
//  Copyright © 2016 PCBETA. All rights reserved.
//

import Foundation
extension String {
    func localized(lang:String) -> String {
        
        let path = NSBundle.mainBundle().pathForResource(lang, ofType: "lproj")
        let bundle = NSBundle(path: path!)
        
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
}