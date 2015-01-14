//
//  IssueHandler.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
import Realm

class IssueHandler: NSObject {
    
    var defaultFolder: NSString!
    
    override convenience init() {
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var cacheDir: NSString = docPaths[0] as NSString
        
        self.init(folder: cacheDir)
    }
    
    init(folder: NSString){
        self.defaultFolder = folder
    }

    //Add issue details from an extracted zip file to Realm database
    func addIssueToRealm(appleId: NSString) {
        /* Step 1 - import zip file */
        
        var appPath = NSBundle.mainBundle().bundlePath
        var defaultZipPath = "\(appPath)/\(appleId).zip"
        var newZipDir = "\(self.defaultFolder)/\(appleId)"
        
        var isDir: ObjCBool = false
        if NSFileManager.defaultManager().fileExistsAtPath(newZipDir, isDirectory: &isDir) {
            if isDir {
                //Issue directory already exists. Do nothing
            }
        }
        else {
            //Issue not copied yet. Unzip and copy
            Helper.unpackZipFile(defaultZipPath)
        }
        
        //Start reading the content of the zip file
        let realm = RLMRealm.defaultRealm()
        
        var predicate = NSString(format: "appleId = '%@'", appleId)
        let issues = Issue.objectsWhere(predicate)
        
        var error: NSError?
        
        //Get the contents of latest.json from the folder
        var jsonPath = "\(self.defaultFolder)/\(appleId)/latest.json"
        
        var fullJSON = NSString(contentsOfFile: jsonPath, encoding: NSUTF8StringEncoding, error: &error)
        
        if fullJSON == nil {
            return
        }
        
        if let issueDict: NSDictionary = Helper.jsonFromString(fullJSON!) as? NSDictionary {
            //if there is an issue with this issue id, remove all its content first (articles, assets)
            if issues.count > 0 {
                var currentIssue: Issue! = issues.firstObject() as Issue
                Article.deleteArticlesFor(currentIssue.globalId)
            }
            
            //now write the issue content into the database
            self.updateIssueMetadata(issueDict, globalId: issueDict.valueForKey("global_id") as String)
        }
    }
    
    
    //Get issue details from Realm database for a specific global id
    func getIssueFromRealm(issueId: NSString) -> Issue? {
        
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = '%@'", issueId)
        var issues = Issue.objectsWithPredicate(predicate)
        
        if issues.count > 0 {
            return issues.firstObject() as? Issue
        }
        
        return nil
    }

    
    // MARK: Add/Update Issues, Assets and Articles
    
    //Add or create issue details
    func updateIssueMetadata(issue: NSDictionary, globalId: String) -> Int {
        let realm = RLMRealm.defaultRealm()
        
        var results = Issue.objectsWhere("globalId = '\(globalId)'")
        var currentIssue: Issue!
        
        realm.beginWriteTransaction()
        if results.count > 0 {
            //older issue
            currentIssue = results.firstObject() as Issue
        }
        else {
            //Create a new issue
            currentIssue = Issue()
            if let metadata: AnyObject! = issue.objectForKey("metadata") {
                if metadata.isKindOfClass(NSDictionary) {
                    currentIssue.metadata = Helper.stringFromJSON(metadata)!
                }
                else {
                    currentIssue.metadata = metadata as String
                }
            }
            currentIssue.globalId = issue.valueForKey("global_id") as String
        }
        
        currentIssue.title = issue.valueForKey("title") as String
        currentIssue.issueDesc = issue.valueForKey("description") as String
        currentIssue.lastUpdateDate = issue.valueForKey("last_updated") as String
        currentIssue.displayDate = issue.valueForKey("display_date") as String
        currentIssue.publishedDate = Helper.publishedDateFrom(issue.valueForKey("publish_date") as String)
        currentIssue.appleId = issue.valueForKey("apple_id") as String
        currentIssue.assetFolder = "\(self.defaultFolder)/\(currentIssue.appleId)"
        
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
            realm.beginWriteTransaction()
            currentIssue.coverImageId = firstAsset.globalId
            realm.addOrUpdateObject(currentIssue)
            realm.commitWriteTransaction()
        }
        
        //Now add all articles into the database
        var articles = issue.objectForKey("articles") as NSArray
        for (index, articleDict) in enumerate(articles) {
            //Insert article for issueId x with placement y
            Article.createArticle(articleDict as NSDictionary, issue: currentIssue, placement: index+1)
        }
        
        return 0
    }
    
}