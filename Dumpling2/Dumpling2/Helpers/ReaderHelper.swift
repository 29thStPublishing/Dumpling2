//
//  ReaderHelper.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 22/04/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit

/** Class which helps store and retrieve user reading status */
public class ReaderHelper: NSObject {

    /**
    Save current active volume
    
    - parameter volumeId: Global id of the volume which is currently being viewed. If nil, will remove saved volume
    */
    public class func saveVolume(volumeId: String?) {
        if volumeId == nil {
            NSUserDefaults.standardUserDefaults().removeObjectForKey("CurrentVolume")
            return
        }
        NSUserDefaults.standardUserDefaults().setValue(volumeId, forKey: "CurrentVolume")
    }
    
    /**
    Save current active issue
    
    - parameter issueId: Global id of the issue which is currently being viewed. If nil, will remove saved issue
    */
    public class func saveIssue(issueId: String?) {
        if issueId == nil {
            NSUserDefaults.standardUserDefaults().removeObjectForKey("CurrentIssue")
            return
        }
        NSUserDefaults.standardUserDefaults().setValue(issueId, forKey: "CurrentIssue")
    }
    
    /**
    Save current active article
    
    - parameter articleId: Global id of the article which is currently being viewed. If nil, will remove saved article
    */
    public class func saveArticle(articleId: String?) {
        if articleId == nil {
            NSUserDefaults.standardUserDefaults().removeObjectForKey("CurrentArticle")
            return
        }
        NSUserDefaults.standardUserDefaults().setValue(articleId, forKey: "CurrentArticle")
    }
    
    /**
    Save asset being viewed
    
    - parameter assetId: Global id of the asset which is currently being viewed. If nil, will remove saved asset
    */
    public class func saveAsset(assetId: String?) {
        if assetId == nil {
            NSUserDefaults.standardUserDefaults().removeObjectForKey("CurrentAsset")
            return
        }
        NSUserDefaults.standardUserDefaults().setValue(assetId, forKey: "CurrentAsset")
    }
    
    /**
    Save reading status for current article
    
    - parameter articleId: Global id of the article currently being read
    
    - parameter readingPercentage: Current position of user in the article in percentage
    */
    public class func saveReadingPercentageFor(articleId: String, readingPercentage: Float) {
        let articleKey = "ArticlePercent-" + articleId
        var percentValue = readingPercentage
        if (percentValue < 0) {
            percentValue = 0.0
        }
        NSUserDefaults.standardUserDefaults().setValue(NSString(format: "%.2f", percentValue), forKey: articleKey)
    }
    
    /**
    Get current active volume
    
    :return: global id of active volume or nil
    */
    public class func retrieveCurrentVolume() -> String? {
        if let volumeId: String = NSUserDefaults.standardUserDefaults().valueForKey("CurrentVolume") as? String {
            return volumeId
        }
        return nil
    }
    
    /**
    Get current active issue
    
    :return: global id of active issue or nil
    */
    public class func retrieveCurrentIssue() -> String? {
        if let issueId: String = NSUserDefaults.standardUserDefaults().valueForKey("CurrentIssue") as? String {
            return issueId
        }
        return nil
    }
    
    /**
    Get current active article
    
    :return: global id of active article or nil
    */
    public class func retrieveCurrentArticle() -> String? {
        if let articleId: String = NSUserDefaults.standardUserDefaults().valueForKey("CurrentArticle") as? String {
            return articleId
        }
        return nil
    }
    
    /**
    Get current active asset
    
    :return: global id of active asset or nil
    */
    public class func retrieveCurrentAsset() -> String? {
        if let assetId: String = NSUserDefaults.standardUserDefaults().valueForKey("CurrentAsset") as? String {
            return assetId
        }
        return nil
    }
    
    /**
    Get last saved reading percentage for given article
    
    - parameter articleId: Global id of article for which reading percentage is to be retrieved
    
    :return: progress of given article's reading in percentage
    */
    public class func getReadingPercentageFor(articleId: String) -> Float {
        let articleKey = "ArticlePercent-" + articleId
        if let percentValue: String = NSUserDefaults.standardUserDefaults().valueForKey(articleKey) as? String {
            let percentage = NSString(string: percentValue).floatValue
            return percentage
        }
        return 0.0
    }
    
    /* Cannot use iCloud here because we need to import CloudKit and every client app
     * will have a different container to use 
     */
    
    //MARK: Dictionary for storing to iCloud
    
    /**
    Get all saved values for current issue, article, asset and reading percent for an article
    
    :return: a dictionary containing saved values for current issue, article, asset and reading percentage for an article
    */
    public class func getDictionaryForCloud() -> Dictionary<String, AnyObject> {
        //Get CurrentIssue, CurrentArticle, CurrentAsset, Reading% from NSUserDefaults and save to iCloud
        var values = Dictionary<String, AnyObject>()
        
        if let volumeId = retrieveCurrentVolume() {
            values["CurrentVolume"] = volumeId
        }
        
        if let issueId = retrieveCurrentIssue() {
            values["CurrentIssue"] = issueId
        }
        
        if let articleId = retrieveCurrentArticle() {
            values["CurrentArticle"] = articleId
            let key = "ArticlePercent-" + articleId
            values[key] = NSString(format: "%.2f", getReadingPercentageFor(articleId))
        }
        
        if let assetId = retrieveCurrentAsset() {
            values["CurrentAsset"] = assetId
        }
        return values
    }
    
    //MARK: Save from dictionary to user defaults
    
    /**
    This method saves specific values from a key for current issue, current article, current asset and article reading percentage back to user defaults (for using while app is active)
    
    :brief: Saves current reading status to User defaults
    
    - parameter savedValues: a dictionary containing saved values for current issue, article, asset and reading percentage for an article
    */
    public class func saveDictionaryToUserDefaults(savedValues: Dictionary<String, AnyObject>) {
        //If CurrentVolume, CurrentIssue, CurrentArticle, CurrentAsset, Reading% are on iCloud, retrieve and save to user defaults
        if let volumeId: String = savedValues["CurrentVolume"] as? String {
            saveVolume(volumeId)
        }
        if let issueId: String = savedValues["CurrentIssue"] as? String {
            saveIssue(issueId)
        }
        if let articleId: String = savedValues["CurrentArticle"] as? String {
            saveArticle(articleId)
            let key = "ArticlePercent-" + articleId
            if let percent: String = savedValues[key] as? String {
                saveReadingPercentageFor(articleId, readingPercentage: NSString(string: percent).floatValue)
            }
        }
        if let assetId: String = savedValues["CurrentAsset"] as? String {
            saveAsset(assetId)
        }
    }
}
