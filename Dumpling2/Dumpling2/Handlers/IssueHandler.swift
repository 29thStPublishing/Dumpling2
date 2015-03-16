//
//  IssueHandler.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
import NewsstandKit

public class IssueHandler: NSObject {
    
    var defaultFolder: NSString!
    //var apiKey: NSString!
    
    // MARK: Initializers
    
    public override convenience init() {
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var cacheDir: NSString = docPaths[0] as NSString
        
        self.init(folder: cacheDir)
    }
    
    public init(folder: NSString){
        self.defaultFolder = folder
        
        RLMRealm.setDefaultRealmPath("\(self.defaultFolder)/default.realm")
    }
    
    public init(folder: NSString, apikey: NSString) {
        self.defaultFolder = folder
        apiKey = apikey
        
        RLMRealm.setDefaultRealmPath(self.defaultFolder)
        
        //Call this if the schema version has changed - pass new schema version as integer
        //IssueHandler.checkAndMigrateData(2)
    }
    
    //Find current schema version (if needed)
    public class func getCurrentSchemaVersion() -> UInt {
        var currentSchemaVersion: UInt = RLMRealm.schemaVersionAtPath(RLMRealm.defaultRealmPath(), error: nil)
        
        if currentSchemaVersion < 0 {
            return 0
        }
        
        return currentSchemaVersion
    }

    //Check and migrate Realm data if needed
    //Do I need to make this public
    class func checkAndMigrateData(schemaVersion: UInt) {
        
        var currentSchemaVersion: UInt = getCurrentSchemaVersion()
        
        if currentSchemaVersion < schemaVersion {
            RLMRealm.setSchemaVersion(schemaVersion, forRealmAtPath: RLMRealm.defaultRealmPath(),
                withMigrationBlock: { migration, oldSchemaVersion in
                    
                    //Enumerate through the models and migrate data as needed
                    /*migration.enumerateObjects(MyClass.className()) { oldObject, newObject in
                        // Make the necessary changes for migration
                        if oldSchemaVersion < 1 {
                            //Use old object and new object
                        }
                    }*/
                }
            )
        }
    }
    
    // MARK: Use zip
    
    //Add issue details from an extracted zip file to Realm database
    public func addIssueZip(appleId: NSString) {
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
        var error: NSError?
        
        //Get the contents of latest.json from the folder
        var jsonPath = "\(self.defaultFolder)/\(appleId)/latest.json"
        
        var fullJSON = NSString(contentsOfFile: jsonPath, encoding: NSUTF8StringEncoding, error: &error)
        
        if fullJSON == nil {
            return
        }
        
        if let issueDict: NSDictionary = Helper.jsonFromString(fullJSON!) as? NSDictionary {
            //if there is an issue with this issue id, remove all its content first (articles, assets)
            //Moved ^ to updateIssueMetadata method
            //now write the issue content into the database
            self.updateIssueMetadata(issueDict, globalId: issueDict.valueForKey("global_id") as String)
        }
    }
    
    
    //Get issue details from Realm database for a specific global id
    public func getIssue(issueId: NSString) -> Issue? {
        
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = '%@'", issueId)
        var issues = Issue.objectsWithPredicate(predicate)
        
        if issues.count > 0 {
            return issues.firstObject() as? Issue
        }
        
        return nil
    }

    // MARK: Use API
    
    //Get Issue details from API and add to database
    public func addIssueFromAPI(issueId: String) {
        let manager = AFHTTPRequestOperationManager()
        let authorization = "method=apikey,token=\(apiKey)"
        manager.requestSerializer.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        let requestURL = "\(baseURL)issues/\(issueId)"
        
        manager.GET(requestURL,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in

                var response: NSDictionary = responseObject as NSDictionary
                var allIssues: NSArray = response.valueForKey("issues") as NSArray
                let issueDetails: NSDictionary = allIssues.firstObject as NSDictionary
                //Update issue now
                self.updateIssueFromAPI(issueDetails, globalId: issueDetails.objectForKey("id") as String)
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                
                println("Error: " + error.localizedDescription)
        })
    }
    
    // MARK: Add/Update Issues, Assets and Articles
    
    //Add or create issue details (zip structure)
    func updateIssueMetadata(issue: NSDictionary, globalId: String) -> Int {
        let realm = RLMRealm.defaultRealm()
        
        var results = Issue.objectsWhere("globalId = '\(globalId)'")
        var currentIssue: Issue!
        
        realm.beginWriteTransaction()
        if results.count > 0 {
            //older issue
            currentIssue = results.firstObject() as Issue
            //Delete all articles and assets if the issue already exists. Then add again
            Article.deleteArticlesFor(currentIssue.globalId)
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
    
    //Add or create issue details (from API)
    func updateIssueFromAPI(issue: NSDictionary, globalId: String) -> Int {
        let realm = RLMRealm.defaultRealm()
        
        var results = Issue.objectsWhere("globalId = '\(globalId)'")
        var currentIssue: Issue!
        
        if results.count > 0 {
            //older issue
            currentIssue = results.firstObject() as Issue
            //Delete all articles and assets if the issue already exists. Then add again
            Article.deleteArticlesFor(currentIssue.globalId)
        }
        else {
            //Create a new issue
            currentIssue = Issue()
            currentIssue.globalId = globalId
        }
        
        realm.beginWriteTransaction()
        currentIssue.title = issue.valueForKey("title") as String
        currentIssue.issueDesc = issue.valueForKey("description") as String
        
        var meta = issue.valueForKey("meta") as NSDictionary
        var updatedInfo = meta.valueForKey("updated") as NSDictionary
        
        if updatedInfo.count > 0 {
            currentIssue.lastUpdateDate = updatedInfo.valueForKey("date") as String
        }
        currentIssue.displayDate = meta.valueForKey("displayDate") as String
        currentIssue.publishedDate = Helper.publishedDateFromISO(meta.valueForKey("created") as String)
        currentIssue.appleId = issue.valueForKey("sku") as String
        
        //SKU SHOULD NEVER be blank. Right now it is blank. So using globalId
        //currentIssue.assetFolder = "\(self.defaultFolder)/\(currentIssue.globalId)"
        currentIssue.assetFolder = "\(self.defaultFolder)/\(currentIssue.appleId)"
        
        var isDir: ObjCBool = false
        if NSFileManager.defaultManager().fileExistsAtPath(currentIssue.assetFolder, isDirectory: &isDir) {
            if isDir {
                //Folder already exists. Do nothing
            }
        }
        else {
            //Folder doesn't exist, create folder where assets will be downloaded
            NSFileManager.defaultManager().createDirectoryAtPath(currentIssue.assetFolder, withIntermediateDirectories: true, attributes: nil, error: nil)
        }
        
        var assetId = issue.valueForKey("coverPhone") as String
        if !assetId.isEmpty {
            currentIssue.coverImageId = assetId
        }
        
        if let metadata: AnyObject = issue.objectForKey("customMeta") {
            if metadata.isKindOfClass(NSDictionary) {
                currentIssue.metadata = Helper.stringFromJSON(metadata)!
            }
            else {
                currentIssue.metadata = metadata as String
            }
        }
        
        realm.addOrUpdateObject(currentIssue)
        realm.commitWriteTransaction()
        
        //Add all assets of the issue (which do not have an associated article)
        var issueMedia = issue.objectForKey("media") as NSArray
        if issueMedia.count > 0 {
            for (index, assetDict) in enumerate(issueMedia) {
                //Download images and create Asset object for issue
                Asset.downloadAndCreateAsset(assetDict.valueForKey("id") as NSString, issue: currentIssue, articleId: "", placement: index+1)
            }
        }
        
        //add all articles into the database
        var articles = issue.objectForKey("articles") as NSArray
        for (index, articleDict) in enumerate(articles) {
            //Insert article
            Article.createArticleForId(articleDict.valueForKey("id") as NSString, issue: currentIssue, placement: index+1)
        }
        
        return 0
    }
    
    //Get all issues - this is just a test function for me
    public func listIssues() {
        let manager = AFHTTPRequestOperationManager()
        
        let authorization = "method=apikey,token=\(apiKey)"
        manager.requestSerializer.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        let requestURL = "\(baseURL)issues"
        
        manager.GET(requestURL,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
                
                var response: NSDictionary = responseObject as NSDictionary
                println("ISSUES: \(response)")
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                
                println("Error: " + error.localizedDescription)
        })
    }
    
    //Search for an issue with an apple id if not available in the database
    //This will get the issue from the server and add to realm
    public func searchIssueFor(appleId: String) -> Issue? {
        
        var issue = Issue.getIssueFor(appleId)
        
        if issue == nil {
            let manager = AFHTTPRequestOperationManager()
            let authorization = "method=apikey,token=\(apiKey)"
            manager.requestSerializer.setValue(authorization, forHTTPHeaderField: "Authorization")
            
            let requestURL = "\(baseURL)issues/sku/\(appleId)"
            
            manager.GET(requestURL,
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
                    
                    var response: NSDictionary = responseObject as NSDictionary
                    var allIssues: NSArray = response.valueForKey("issues") as NSArray
                    let issueDetails: NSDictionary = allIssues.firstObject as NSDictionary
                    //Update issue now
                    self.updateIssueFromAPI(issueDetails, globalId: issueDetails.objectForKey("id") as String)
                },
                failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                    
                    println("Error: " + error.localizedDescription)
            })
        }
        
        return issue
    }
    
    //MARK: Publish issue on Newsstand
    
    public func addIssueOnNewsstand(issueId: String) {
        
        if let issue = self.getIssue(issueId) {
            var library = NKLibrary.sharedLibrary()
            
            var issueAppleId = issue.appleId
            var existingIssue = library.issueWithName(issueAppleId)
            if existingIssue == nil {
                //Insert issue to Newsstand
                library.addIssueWithName(issueAppleId, date: issue.publishedDate)
            }
            
            //Update issue cover icon
        }
    }
    
    //Update Newsstand icon
    func updateIssueCoverIcon() {
        var issues = NKLibrary.sharedLibrary().issues
        
        //Find newest issue
        var newestIssue: NKIssue? = nil
        for issue in issues {
            let issueDate = issue.date!
            if newestIssue == nil {
                newestIssue = issue as? NKIssue
            }
            else if newestIssue?.date.compare(issueDate!) == NSComparisonResult.OrderedAscending {
                newestIssue = issue as? NKIssue
            }
        }
        
        //Get cover image of isse
        if let issue = newestIssue {
            var savedIssue = Issue.getIssueFor(issue.name)
            if savedIssue != nil {
                if let coverImageId = savedIssue?.coverImageId {
                    var asset = Asset.getAsset(coverImageId)
                    if let coverImgURL = asset?.originalURL {
                        var coverImg = UIImage(contentsOfFile: coverImgURL)
                        UIApplication.sharedApplication().setNewsstandIconImage(coverImg)
                        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                    }
                }
                
            }
        }
    }
    
}