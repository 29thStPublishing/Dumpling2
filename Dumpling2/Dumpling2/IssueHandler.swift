//
//  IssueHandler.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
import Realm

class IssueHandler {

    //Add issue details from an extracted zip file to Realm database
    class func addIssueToRealm(appleId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        var currentIssue: Issue! = Issue.objectsWhere("appleId = \(appleId)").firstObject() as Issue
        
        var error: NSError?
        
        //Get the contents of latest.json from the folder
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var cacheDir: NSString = docPaths[0] as NSString
        var jsonPath = "\(cacheDir)/\(appleId)/latest.json"
        
        var fullJSON = NSString(contentsOfFile: jsonPath, encoding: NSUTF8StringEncoding, error: &error)
        
        if let issueDict: NSDictionary = fullJSON?.objectFromJSONString() as? NSDictionary {
            //if there is an issue with this issue id, remove all its content first (articles, assets)
            if currentIssue != nil {
                Article.deleteArticlesFor(currentIssue.globalId)
            }
            
            //now write the issue content into the database
            updateIssueMetadata(issueDict, globalId: issueDict.valueForKey("global_id") as String)
            
            //TODO: add all articles for this issue
        }
    }
    
    
    //Get issue details from Realm database for a specific issue id
    class func getIssueFromRealm(issueId: NSString) -> Issue {
        let newIssue = Issue()
        return newIssue
    }

    
    // MARK: Add/Update Issues, Assets and Articles
    
    //Add or create issue details
    class func updateIssueMetadata(issue: NSDictionary, globalId: String) -> Int {
        let realm = RLMRealm.defaultRealm()
        
        var results = Issue.objectsWhere("globalId = \(globalId)")
        var currentIssue: Issue!
        
        if results.count > 0 {
            //older issue
            currentIssue = results.firstObject() as Issue
        }
        else {
            //Create a new issue
            currentIssue = Issue()
            currentIssue.metadata = issue.valueForKey("metadata") as String
            currentIssue.globalId = issue.valueForKey("global_id") as String
        }
        
        currentIssue.title = issue.valueForKey("title") as String
        currentIssue.issueDesc = issue.valueForKey("description") as String
        currentIssue.lastUpdateDate = issue.valueForKey("last_updated") as String
        currentIssue.displayDate = issue.valueForKey("display_date") as String
        currentIssue.publishedDate = Helper.publishedDateFrom(issue.valueForKey("publish_date") as String)
        currentIssue.appleId = issue.valueForKey("apple_id") as String
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(currentIssue)
        realm.commitWriteTransaction()

        //Add all assets of the issue (which do not have an associated article)
        var orderedArray = issue.objectForKey("images")?.objectForKey("ordered") as NSArray
        if orderedArray.count > 0 {
            for (index, assetDict) in enumerate(orderedArray) {
                //create asset
                Asset.createAsset(assetDict as NSDictionary, issue: currentIssue, articleId: "", placement: index+1)
            }
        }
        
        //define cover image for issue
        if let firstAsset = Asset.getFirstAssetFor(currentIssue.globalId, articleId: "") {
            currentIssue.coverImageId = firstAsset.globalId
        }
        
        //Now add all articles into the database
        var articles = issue.objectForKey("articles") as NSArray
        for (index, articleDict) in enumerate(articles) {
            //Insert article for issueId x with placement y
            createArticle(articleDict as NSDictionary, issue: currentIssue, placement: index+1)
            
            //Also check here if article is featured or not
        }
        
        return 0
    }
    
    
    //Add article
    class func createArticle(article: NSDictionary, issue: Issue, placement: Int) {
        let realm = RLMRealm.defaultRealm()

        var currentArticle = Article()
        currentArticle.globalId = article.objectForKey("global_id") as String
        currentArticle.title = article.objectForKey("title") as String
        currentArticle.body = article.objectForKey("body") as String
        currentArticle.articleDesc = article.objectForKey("description") as String
        currentArticle.url = article.objectForKey("url") as String
        currentArticle.section = article.objectForKey("section") as String
        currentArticle.authorName = article.objectForKey("author_name") as String
        currentArticle.sourceURL = article.objectForKey("source") as String
        currentArticle.dek = article.objectForKey("dek") as String
        currentArticle.authorURL = article.objectForKey("author_url") as String
        currentArticle.keywords = article.objectForKey("keywords") as String
        currentArticle.commentary = article.objectForKey("commentary") as String
        currentArticle.articleType = article.objectForKey("type") as String
        var metadata: AnyObject! = article.objectForKey("metadata")
        if metadata.isKindOfClass(NSDictionary) {
            currentArticle.metadata = metadata.JSONString()!
        }
        else {
            currentArticle.metadata = metadata as String
        }
        
        currentArticle.issueId = issue.globalId
        currentArticle.placement = placement
        currentArticle.versionStashed = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey) as String
        
        //TODO: Featured or not
        
        //Insert article images
        if let orderedArray = article.objectForKey("images")?.objectForKey("ordered") as? NSArray {
            if orderedArray.count > 0 {
                for (index, imageDict) in enumerate(orderedArray) {
                    Asset.createAsset(imageDict as NSDictionary, issue: issue, articleId: currentArticle.globalId, placement: index+1)
                }
            }
        }
        
        //TODO: Set thumbnail for article
        var firstAsset = Asset.getFirstAssetFor(issue.globalId, articleId: currentArticle.globalId)
        
        //Insert article sound files
        if let orderedArray = article.objectForKey("sound_files")?.objectForKey("ordered") as? NSArray {
            if orderedArray.count > 0 {
                for (index, soundDict) in enumerate(orderedArray) {
                    Asset.createAsset(soundDict as NSDictionary, issue: issue, articleId: currentArticle.globalId, sound: true, placement: index+1)
                }
            }
        }
    }
    
}