//
//  Logger.swift
//  naruhodo
//
//  Created by FUJIKI TAKESHI on 2014/11/06.
//  Copyright (c) 2014年 Takeshi Fujiki. All rights reserved.
//

import Foundation

class Logger{
    class func log(message: String,
        function: String = #function,
        file: String = #file,
        line: Int = #line) {
            var filename = file
            if let match = filename.rangeOfString("[^/]*$", options: .RegularExpressionSearch) {
                filename = filename.substringWithRange(match)
            }
            print("\(NSDate().timeIntervalSince1970):\(filename):L\(line):\(function) \"\(message)\"")
    }
}
