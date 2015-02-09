//
//  Issue.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
//import Realm

//Issue object
class Issue: RLMObject {
    dynamic var globalId = ""
    dynamic var appleId = ""
    dynamic var title = ""
    dynamic var issueDesc = "" //description
    dynamic var assetFolder = ""
    dynamic var coverImageId = "" //globalId of asset
    dynamic var iconImageURL = ""
    dynamic var publishedDate = NSDate()
    dynamic var lastUpdateDate = ""
    dynamic var displayDate = ""
    dynamic var metadata = ""
    dynamic var magazine = Magazine()
    
    override class func primaryKey() -> String {
        return "globalId"
    }
}
