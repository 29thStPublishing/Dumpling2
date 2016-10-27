//
//  ReaderHelper.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 22/04/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit

/** Class which helps store and retrieve user reading status */
open class ReaderHelper: NSObject {

    /**
    Save current active volume
    
    - parameter volumeId: Global id of the volume which is currently being viewed. If nil, will remove saved volume
    */
    open class func saveVolume(_ volumeId: String?) {
        if volumeId == nil {
            UserDefaults.standard.removeObject(forKey: "CurrentVolume")
            return
        }
        UserDefaults.standard.setValue(volumeId, forKey: "CurrentVolume")
    }
    
    /**
    Save current active issue
    
    - parameter issueId: Global id of the issue which is currently being viewed. If nil, will remove saved issue
    */
    open class func saveIssue(_ issueId: String?) {
        if issueId == nil {
            UserDefaults.standard.removeObject(forKey: "CurrentIssue")
            return
        }
        UserDefaults.standard.setValue(issueId, forKey: "CurrentIssue")
    }
    
    /**
    Save current active article
    
    - parameter articleId: Global id of the article which is currently being viewed. If nil, will remove saved article
    */
    open class func saveArticle(_ articleId: String?) {
        if articleId == nil {
            UserDefaults.standard.removeObject(forKey: "CurrentArticle")
            return
        }
        UserDefaults.standard.setValue(articleId, forKey: "CurrentArticle")
    }
    
    /**
    Save asset being viewed
    
    - parameter assetId: Global id of the asset which is currently being viewed. If nil, will remove saved asset
    */
    open class func saveAsset(_ assetId: String?) {
        if assetId == nil {
            UserDefaults.standard.removeObject(forKey: "CurrentAsset")
            return
        }
        UserDefaults.standard.setValue(assetId, forKey: "CurrentAsset")
    }
    
    /**
    Save reading status for current article
    
    - parameter articleId: Global id of the article currently being read
    
    - parameter readingPercentage: Current position of user in the article in percentage
    */
    open class func saveReadingPercentageFor(_ articleId: String, readingPercentage: Float) {
        let articleKey = "ArticlePercent-" + articleId
        var percentValue = readingPercentage
        if (percentValue < 0) {
            percentValue = 0.0
        }
        UserDefaults.standard.setValue(NSString(format: "%.2f", percentValue), forKey: articleKey)
    }
    
    /**
    Get current active volume
    
    :return: global id of active volume or nil
    */
    open class func retrieveCurrentVolume() -> String? {
        if let volumeId: String = UserDefaults.standard.value(forKey: "CurrentVolume") as? String {
            return volumeId
        }
        return nil
    }
    
    /**
    Get current active issue
    
    :return: global id of active issue or nil
    */
    open class func retrieveCurrentIssue() -> String? {
        if let issueId: String = UserDefaults.standard.value(forKey: "CurrentIssue") as? String {
            return issueId
        }
        return nil
    }
    
    /**
    Get current active article
    
    :return: global id of active article or nil
    */
    open class func retrieveCurrentArticle() -> String? {
        if let articleId: String = UserDefaults.standard.value(forKey: "CurrentArticle") as? String {
            return articleId
        }
        return nil
    }
    
    /**
    Get current active asset
    
    :return: global id of active asset or nil
    */
    open class func retrieveCurrentAsset() -> String? {
        if let assetId: String = UserDefaults.standard.value(forKey: "CurrentAsset") as? String {
            return assetId
        }
        return nil
    }
    
    /**
    Get last saved reading percentage for given article
    
    - parameter articleId: Global id of article for which reading percentage is to be retrieved
    
    :return: progress of given article's reading in percentage
    */
    open class func getReadingPercentageFor(_ articleId: String) -> Float {
        let articleKey = "ArticlePercent-" + articleId
        if let percentValue: String = UserDefaults.standard.value(forKey: articleKey) as? String {
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
    open class func getDictionaryForCloud() -> Dictionary<String, AnyObject> {
        //Get CurrentIssue, CurrentArticle, CurrentAsset, Reading% from NSUserDefaults and save to iCloud
        var values = Dictionary<String, AnyObject>()
        
        if let volumeId = retrieveCurrentVolume() {
            values["CurrentVolume"] = volumeId as AnyObject?
        }
        
        if let issueId = retrieveCurrentIssue() {
            values["CurrentIssue"] = issueId as AnyObject?
        }
        
        if let articleId = retrieveCurrentArticle() {
            values["CurrentArticle"] = articleId as AnyObject?
            let key = "ArticlePercent-" + articleId
            values[key] = NSString(format: "%.2f", getReadingPercentageFor(articleId))
        }
        
        if let assetId = retrieveCurrentAsset() {
            values["CurrentAsset"] = assetId as AnyObject?
        }
        return values
    }
    
    //MARK: Save from dictionary to user defaults
    
    /**
    This method saves specific values from a key for current issue, current article, current asset and article reading percentage back to user defaults (for using while app is active)
    
    :brief: Saves current reading status to User defaults
    
    - parameter savedValues: a dictionary containing saved values for current issue, article, asset and reading percentage for an article
    */
    open class func saveDictionaryToUserDefaults(_ savedValues: Dictionary<String, AnyObject>) {
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
