//
//  LoggingPrint.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 21/12/15.
//  Copyright © 2015 29th Street. All rights reserved.
//

import Foundation

/**
 Prints the filename, function name, line number and textual representation of `object` and a newline character into
 the standard output if the build setting for "Other Swift Flags" defines `-D DEBUG`.
 The current thread is a prefix on the output. <UI> for the main thread, <BG> for anything else.
 Only the first parameter needs to be passed to this funtion.
 The textual representation is obtained from the `object` using its protocol conformances, in the following
 order of preference: `CustomDebugStringConvertible` and `CustomStringConvertible`. Do not overload this function for
 your type. Instead, adopt one of the protocols mentioned above.
 :param: object   The object whose textual representation will be printed. If this is an expression, it is lazily evaluated.
 :param: file     The name of the file, defaults to the current file without the ".swift" extension.
 :param: function The name of the function, defaults to the function within which the call is made.
 :param: line     The line number, defaults to the line number within the file that the call is made.
 */

func lLog<T>(@autoclosure object: () -> T, _ file: String = #file, function: String = #function, _ line: Int = #line) {
    //If LLOG is present and != 1, return - no logging
    let environmentVars = NSProcessInfo.processInfo().environment
    if let logging = environmentVars["LLOG"] {
        if logging != "1" {
            return
        }
    }
    #if DEBUG
        let value = object()
        let stringRepresentation: String
        
        if let value = value as? CustomDebugStringConvertible {
            stringRepresentation = value.debugDescription
        } else if let value = value as? CustomStringConvertible {
            stringRepresentation = value.description
        } else {
            fatalError("lLog only works for values that conform to CustomDebugStringConvertible or CustomStringConvertible")
        }
        
        let fileURL = NSURL(string: file)?.lastPathComponent ?? "Unknown file"
        let queue = NSThread.isMainThread() ? "UI" : "BG"
        
        print("\(NSDate())::##DUMPLING##<\(queue)> \(fileURL) \(function)[\(line)]: " + stringRepresentation)
    #endif
}