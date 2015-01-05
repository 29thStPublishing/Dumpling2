//
//  Helper.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 05/01/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit

class Helper {

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
}