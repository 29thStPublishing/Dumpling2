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
let MEDIA_DOWNLOADED: String = "mediaDownloaded" //fired for each media object download completed
let IMAGE_DOWNLOADED: String = "imageDownloaded" //fired for each image download

public extension UIImage {
    public var hasContent: Bool {
        return cgImage != nil || ciImage != nil
    }
}

open class Helper {
    
    static var isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let posix = Locale(identifier: "en_US_POSIX")
        formatter.locale = posix
        return formatter
    }()
    
    static var isoDateFormatter2: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let posix = Locale(identifier: "en_US_POSIX")
        formatter.locale = posix
        return formatter
    }()
    
    //Date from string of format MM/dd/yyyy
    class func publishedDateFrom(_ string: String) -> Date {
        let dummyDate = Date()
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let unitFlags : NSCalendar.Unit = [NSCalendar.Unit.year, NSCalendar.Unit.month, NSCalendar.Unit.day]
        
        var comps = (calendar as NSCalendar?)?.components(unitFlags, from: dummyDate)
        comps?.hour = 0
        comps?.minute = 0
        comps?.second = 0

        var parts = string.components(separatedBy: "/")
        
        if parts.count == 3 {
            comps?.month = Int(parts[0])!
            comps?.day = Int(parts[1])!
            comps?.year = Int(parts[2])!
        }
        
        let date = calendar.date(from: comps!)
        return date!
    }

    //Date from string of ISO format with milliseconds e.g. 2015-08-11T00:58:11.059998+00:00 (length = 32 chars)
    class func publishedDateFromISO(_ string: String?) -> Date {
        if !isNilOrEmpty(string) {
            
            if let date = isoDateFormatter.date(from: string!) {
                return date
            }
            
            if let date = Helper.publishedDateFromISO2(string) as Date? {
                return date
            }
        }
        return Date()
    }
    
    //Date from string of ISO format e.g. 2015-08-11T00:20:07+00:00 (length = 25 chars)
    class func publishedDateFromISO2(_ string: String?) -> Date {
        if !isNilOrEmpty(string) {
            
            if let date = isoDateFormatter2.date(from: string!) {
                return date
            }
            
            /*if let date = Helper.publishedDateFromISO(string) as NSDate? {
                return date
            }*/
        }
        return Date()
    }
    
    class func isiPhone() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return false
        }
        return true
    }
    
    class func isRetinaDevice() -> Bool {
        let mainScreen = UIScreen.main
        if mainScreen.responds(to: #selector(UIScreen.displayLink(withTarget:selector:))) && mainScreen.scale >= 2.0 {
            return true
        }
        return false
    }
    
    //JSON to string
    class func stringFromJSON(_ object: Any) -> String? {
        
        if JSONSerialization.isValidJSONObject(object) {
            if let data = try? JSONSerialization.data(withJSONObject: object, options: []) {
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    return string as String
                }
            }
        }
        
        return nil
    }
    
    //String to JSON
    class func jsonFromString(_ string: String) -> AnyObject? {
        if let data = string.data(using: String.Encoding.utf8) {
            if let jsonData: AnyObject = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as AnyObject? {
                return jsonData
            }
        }
        return nil
    }
    
    class func isNilOrEmpty(_ string: String?) -> Bool {
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
    
    open class func decodeHTMLEntitiesIn(_ string: String) -> String {
        if string.range(of: "&") == nil {
            return string
        }
        let str: NSString = NSString(string: string)
        let decodedStr = str.decodingHTMLEntities()
        return decodedStr!
    }
    
    //Unpack a zip file
    //Issue 46
    /*class func unpackZipFile(filePath: NSString) {
        let zipArchive = ZipArchive()
        
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let cacheDir: NSString = docPaths[0] as NSString
        
        if zipArchive.UnzipOpenFile(filePath as String) {
            let result = zipArchive.UnzipFileTo(cacheDir as String, overWrite: true)
            if !result {
                //problem
                return
            }
            
            zipArchive.UnzipCloseFile()
        }
        
        if filePath.hasPrefix(cacheDir as String) {
            do {
                //remove zip file if it was in cache dir
                //planning ahead - this won't be called right now
                try NSFileManager.defaultManager().removeItemAtPath(filePath as String)
            } catch _ {
            }
        }
    }*/
}
