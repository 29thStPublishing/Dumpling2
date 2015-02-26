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
public class Issue: RLMObject {
    dynamic public var globalId = ""
    dynamic var appleId = ""
    dynamic public var title = ""
    dynamic public var issueDesc = "" //description
    dynamic public var assetFolder = ""
    dynamic public var coverImageId = "" //globalId of asset
    dynamic public var iconImageURL = ""
    dynamic public var publishedDate = NSDate()
    dynamic public var lastUpdateDate = ""
    dynamic public var displayDate = ""
    dynamic public var metadata = ""
    //dynamic var magazine = Magazine()
    
    override public class func primaryKey() -> String {
        return "globalId"
    }
    
    //Get details for a specific key from custom meta of an issue
    public func getValue(key: NSString) -> AnyObject? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = '%@'", self.globalId)
        var issues = Issue.objectsWithPredicate(predicate)
        
        if issues.count > 0 {
            var issue: Issue =  issues.firstObject() as Issue
            var metadata: AnyObject? = Helper.jsonFromString(issue.metadata)
            if let metadataDict = metadata as? NSDictionary {
                return metadataDict.valueForKey(key)
            }
        }
        
        return nil
    }
}
