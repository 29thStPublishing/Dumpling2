//
//  Helper.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 05/01/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit

//let baseURL: String = "https://magnet-dev.29.io/"
let baseURL: String = "https://api.29.io/"
var clientKey: String = "jwzLDfjKQD64oHvQyGEZnmximHaJqp"

let ISSUE_DOWNLOAD_COMPLETE: String = "issueDownloadComplete"
let ARTICLES_DOWNLOAD_COMPLETE: String = "articlesDownloadComplete"
let DOWNLOAD_COMPLETE: String = "downloadComplete" //Volume + Issues + Article + Volume assets + Issue assets + Article assets downloaded
let ALL_DOWNLOADS_COMPLETE: String = "allDownloadsComplete" //all volumes or articles through the VolumeHandler or ArticleHandler

class Helper {
    
    //Date from string of format MM/dd/yyyy
    class func publishedDateFrom(string: String) -> NSDate {
        var dummyDate = NSDate()
        
        var calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        var unitFlags : NSCalendarUnit = NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitDay
        
        let comps = calendar?.components(unitFlags, fromDate: dummyDate)
        comps?.hour = 0
        comps?.minute = 0
        comps?.second = 0

        var parts = string.componentsSeparatedByString("/")
        
        if parts.count == 3 {
            comps?.month = parts[0].toInt()!
            comps?.day = parts[1].toInt()!
            comps?.year = parts[2].toInt()!
        }
        
        var date = calendar?.dateFromComponents(comps!)
        return date!
    }

    //Date from string of ISO format with milliseconds e.g. 2015-08-11T00:58:11.059998+00:00 (length = 32 chars)
    class func publishedDateFromISO(string: String?) -> NSDate {
        if !isNilOrEmpty(string) {
            var dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            var posix = NSLocale(localeIdentifier: "en_US_POSIX")
            dateFormatter.locale = posix
        
            if let date = dateFormatter.dateFromString(string!) {
                return date
            }
            
            if let date = Helper.publishedDateFromISO2(string) as NSDate? {
                return date
            }
        }
        return NSDate()
    }
    
    //Date from string of ISO format e.g. 2015-08-11T00:20:07+00:00 (length = 25 chars)
    class func publishedDateFromISO2(string: String?) -> NSDate {
        if !isNilOrEmpty(string) {
            var dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            var posix = NSLocale(localeIdentifier: "en_US_POSIX")
            dateFormatter.locale = posix
            
            if let date = dateFormatter.dateFromString(string!) {
                return date
            }
            
            if let date = Helper.publishedDateFromISO(string) as NSDate? {
                return date
            }
        }
        return NSDate()
    }
    
    class func isiPhone() -> Bool {
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            return false
        }
        return true
    }
    
    class func isRetinaDevice() -> Bool {
        let mainScreen = UIScreen.mainScreen()
        if mainScreen.respondsToSelector(Selector("displayLinkWithTarget:selector:")) && mainScreen.scale >= 2.0 {
            return true
        }
        
        return false
    }
    
    //JSON to string
    class func stringFromJSON(object: AnyObject) -> String? {
        
        if NSJSONSerialization.isValidJSONObject(object) {
            if let data = NSJSONSerialization.dataWithJSONObject(object, options: nil, error: nil) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
            }
        }
        
        return nil
    }
    
    //String to JSON
    class func jsonFromString(string: String) -> AnyObject? {
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
            if let jsonData: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil) {
                return jsonData
            }
        }
        return nil
    }
    
    class func isNilOrEmpty(string: String?) -> Bool {
        if let str = string {
            if str.isEmpty {
                //Not nil but empty
                return true
            }
        }
        else {
            //Nil, return false
            return true
        }
        //Not nil and not empty
        return false
    }
    
    //Unpack a zip file
    class func unpackZipFile(filePath: NSString) {
        var zipArchive = ZipArchive()
        
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var cacheDir: NSString = docPaths[0] as! NSString
        
        if zipArchive.UnzipOpenFile(filePath as String) {
            var result = zipArchive.UnzipFileTo(cacheDir as String, overWrite: true)
            if !result {
                //problem
                return
            }
            
            zipArchive.UnzipCloseFile()
        }
        
        if filePath.hasPrefix(cacheDir as String) {
            //remove zip file if it was in cache dir
            //planning ahead - this won't be called right now
            NSFileManager.defaultManager().removeItemAtPath(filePath as String, error: nil)
        }
    }
}