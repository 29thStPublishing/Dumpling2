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
                deleteArticlesFor(currentIssue.appleId)
            }
            
            //now write the issue content into the database
            updateIssueMetadata(issueDict, issueId: currentIssue.appleId)
            
            //TODO: add all articles for this issue
        }
    }
    
    
    //Get issue details from Realm database for a specific issue id
    class func getIssueFromRealm(issueId: NSString) -> Issue {
        let newIssue = Issue()
        return newIssue
    }

    
    // MARK: Add/Update objects
    class func updateIssueMetadata(issue: NSDictionary, issueId: NSString?) {
        let realm = RLMRealm.defaultRealm()
        var currentIssue: Issue!
        
        //Adds or updates issue into database and returns the issueId if operation is successful
        //empty string otherwise
        if (issueId != nil) {
            //From an older issue, update the details of the issue
            currentIssue = Issue.objectsWhere("appleId = \(issueId)").firstObject() as Issue
        }
        else {
            //Create a new issue
            currentIssue = Issue()
            currentIssue.metadata = issue.valueForKey("metadata") as String
        }
        
        currentIssue.title = issue.valueForKey("title") as String
        currentIssue.issueDesc = issue.valueForKey("description") as String
        currentIssue.lastUpdateDate = issue.valueForKey("last_updated") as String
        currentIssue.displayDate = issue.valueForKey("display_date") as String
        currentIssue.publishedDate = Helper.publishedDateFrom(issue.valueForKey("publish_date") as String)
        currentIssue.appleId = issueId!
        
        
        //TODO: Add all assets of the issue (which do not have an associated article)
        
    }
    
    
    // MARK: Remove objects
    
    //Delete articles and assets for a specific issue
    class func deleteArticlesFor(appleId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issue.appleId = %@", appleId)
        var articles = Article.objectsWithPredicate(predicate)
        
        var articleIds = NSMutableArray()
        //go through each article and delete all assets associated with it
        for article in articles {
            let article = article as Article
            articleIds.addObject(article.id)
        }
        
        deleteAssetsForIssue(appleId)
        deleteAssetsForArticles(articleIds)
        
        //Delete articles
        realm.beginWriteTransaction()
        realm.deleteObjects(articles)
        realm.commitWriteTransaction()
    }
    
    
    //Delete all assets for a single article
    class func deleteAssetsFor(articleId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "article.id = %@", articleId)
        var results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
    
    
    //Delete all assets for multiple articles
    class func deleteAssetsForArticles(articles: NSArray) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "article.id IN %@", articles)
        var results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
    
    
    //Delete all assets for a single issue
    class func deleteAssetsForIssue(issueId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issue.appleId = %@", issueId)
        var results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
}