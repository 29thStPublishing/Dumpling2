//
//  IssueHandler.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
import NewsstandKit

/** Starter class which adds issues to the database */
public class IssueHandler: NSObject {
    
    var defaultFolder: NSString!
    var activeDownloads: NSMutableDictionary!
    //activeDownloads is a dictionary of issueIds (keys). Each issueId has a dictionary.
    //Each entry in the dictionary has the key = request url, value = completion_status (true, false)
    
    // MARK: Initializers
    
    /**
    @brief Initializer object
    
    @discussion Initializes the IssueHandler with the Documents directory. This is where the database and assets will be saved
    */
    /*public convenience override init() {
        //super.init()
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir: NSString = docPaths[0] as! NSString
        
        self.defaultFolder = docsDir
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(self.defaultFolder)/default.realm"
        RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
        var mainBundle = NSBundle.mainBundle()
        if let key: String = mainBundle.objectForInfoDictionaryKey("APIKey") as? String {
            apiKey = key
        }
        else {
            return nil
        }
    }*/
    
    /**
    @brief Initializer object
    
    @discussion Initializes the IssueHandler with the given folder. This is where the database and assets will be saved
    
    @param folder The folder where the database and downloaded assets should be saved
    */
    public init?(folder: NSString){
        super.init()
        self.defaultFolder = folder
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(self.defaultFolder)/default.realm"
        RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
        var mainBundle = NSBundle.mainBundle()
        if let key: String = mainBundle.objectForInfoDictionaryKey("APIKey") as? String {
            apiKey = key
        }
        else {
            return nil
        }
    }
    
    /**
    @brief Initializer object
    
    @discussion Initializes the IssueHandler with the Documents directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
    @param apikey Client API key to be used for making calls to the Magnet API
    */
    public init(apikey: NSString) {
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir: NSString = docPaths[0] as! NSString
        
        self.defaultFolder = docsDir
        apiKey = apikey as String
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(self.defaultFolder)/default.realm"
        RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
        //Call this if the schema version has changed - pass new schema version as integer
        //IssueHandler.checkAndMigrateData(2)
    }
    
    /**
    @brief Initializer object
    
    @discussion Initializes the IssueHandler with a custom directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
    @param folder The folder where the database and downloaded assets should be saved
    
    @apikey Client API key to be used for making calls to the Magnet API
    */
    public init(folder: NSString, apikey: NSString) {
        self.defaultFolder = folder
        apiKey = apikey as String
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(self.defaultFolder)/default.realm"
        RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
        //Call this if the schema version has changed - pass new schema version as integer
        //IssueHandler.checkAndMigrateData(2)
    }
    
    /**
    @brief Find current schema version
    
    @return the current schema version for the database
    */
    public class func getCurrentSchemaVersion() -> UInt {
        var currentSchemaVersion: UInt = RLMRealm.schemaVersionAtPath(RLMRealm.defaultRealmPath(), error: nil)
        
        if currentSchemaVersion < 0 {
            return 0
        }
        
        return currentSchemaVersion
    }

    //Check and migrate Realm data if needed
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
    
    /**
    @brief Add issue details from an extracted zip file to the database
    
    @description The method uses an Apple id, gets a zip file from the project Bundle with the name appleId.zip, extracts its contents and adds the issue, articles and assets to the database
    
    @param appleId The SKU/Apple id for the issue. The method looks for a zip with the same name in the Bundle
    */
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
        
        if let issueDict: NSDictionary = Helper.jsonFromString(fullJSON! as String) as? NSDictionary {
            //if there is an issue with this issue id, remove all its content first (articles, assets)
            //Moved ^ to updateIssueMetadata method
            //now write the issue content into the database
            self.updateIssueMetadata(issueDict, globalId: issueDict.valueForKey("global_id") as! String)
        }
    }

    // MARK: Use API
    
    /**
    @brief Get Issue details from API and add to database
    
    @description The method uses the global id of an issue, gets its content from the Magnet API and adds it to the database
    
    @param appleId The SKU/Apple id for the issue. The method looks for a zip with the same name in the Bundle
    */
    public func addIssueFromAPI(issueId: String) {
        
        let requestURL = "\(baseURL)issues/\(issueId)"
        
        self.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: issueId)
        
        var networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                var response: NSDictionary = data as! NSDictionary
                var allIssues: NSArray = response.valueForKey("issues") as! NSArray
                let issueDetails: NSDictionary = allIssues.firstObject as! NSDictionary
                //Update issue now
                self.updateIssueFromAPI(issueDetails, globalId: issueDetails.objectForKey("id") as! String)
            }
            else if let err = error {
                println("Error: " + err.description)
                //Mark issue download as failed
                self.updateStatusDictionary(issueId, url: "\(baseURL)issues/\(issueId)", status: 2)
            }
        }
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
            currentIssue = results.firstObject() as! Issue
            //Delete all articles and assets if the issue already exists. Then add again
            Asset.deleteAssetsForIssue(currentIssue.globalId)
            Article.deleteArticlesFor(currentIssue.globalId)
        }
        else {
            //Create a new issue
            currentIssue = Issue()
            if let metadata: AnyObject! = issue.objectForKey("metadata") {
                if metadata!.isKindOfClass(NSDictionary) {
                    currentIssue.metadata = Helper.stringFromJSON(metadata!)!
                }
                else {
                    currentIssue.metadata = metadata as! String
                }
            }
            currentIssue.globalId = issue.valueForKey("global_id") as! String
        }
        
        currentIssue.title = issue.valueForKey("title") as! String
        currentIssue.issueDesc = issue.valueForKey("description") as! String
        currentIssue.lastUpdateDate = issue.valueForKey("last_updated") as! String
        currentIssue.displayDate = issue.valueForKey("display_date") as! String
        currentIssue.publishedDate = Helper.publishedDateFrom(issue.valueForKey("publish_date") as! String)
        currentIssue.appleId = issue.valueForKey("apple_id") as! String
        currentIssue.assetFolder = "\(self.defaultFolder)/\(currentIssue.appleId)"
        
        realm.addOrUpdateObject(currentIssue)
        realm.commitWriteTransaction()

        //Add all assets of the issue (which do not have an associated article)
        var orderedArray = issue.objectForKey("images")?.objectForKey("ordered") as! NSArray
        if orderedArray.count > 0 {
            for (index, assetDict) in enumerate(orderedArray) {
                //create asset
                Asset.createAsset(assetDict as! NSDictionary, issue: currentIssue, articleId: "", placement: index+1)
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
        var articles = issue.objectForKey("articles") as! NSArray
        for (index, articleDict) in enumerate(articles) {
            //Insert article for issueId x with placement y
            Article.createArticle(articleDict as! NSDictionary, issue: currentIssue, placement: index+1)
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
            currentIssue = results.firstObject() as! Issue
            //Delete all articles and assets if the issue already exists. Then add again
            Asset.deleteAssetsForIssue(currentIssue.globalId)
            Article.deleteArticlesFor(currentIssue.globalId)
        }
        else {
            //Create a new issue
            currentIssue = Issue()
            currentIssue.globalId = globalId
        }
        
        realm.beginWriteTransaction()
        currentIssue.title = issue.valueForKey("title") as! String
        currentIssue.issueDesc = issue.valueForKey("description") as! String
        
        var meta = issue.valueForKey("meta") as! NSDictionary
        var updatedInfo = meta.valueForKey("updated") as! NSDictionary
        
        if updatedInfo.count > 0 {
            currentIssue.lastUpdateDate = updatedInfo.valueForKey("date") as! String
        }
        currentIssue.displayDate = meta.valueForKey("displayDate") as! String
        currentIssue.publishedDate = Helper.publishedDateFromISO(meta.valueForKey("created") as! String)
        currentIssue.appleId = issue.valueForKey("sku") as! String
        
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
        
        var assetId = issue.valueForKey("coverPhone") as! String
        if !assetId.isEmpty {
            currentIssue.coverImageId = assetId
        }
        
        if let metadata: AnyObject = issue.objectForKey("customMeta") {
            if metadata.isKindOfClass(NSDictionary) {
                currentIssue.metadata = Helper.stringFromJSON(metadata)!
            }
            else {
                currentIssue.metadata = metadata as! String
            }
        }
        
        realm.addOrUpdateObject(currentIssue)
        realm.commitWriteTransaction()
        
        //Add all assets of the issue (which do not have an associated article)
        var issueMedia = issue.objectForKey("media") as! NSArray
        if issueMedia.count > 0 {
            for (index, assetDict) in enumerate(issueMedia) {
                //Download images and create Asset object for issue
                //Add asset to Issue dictionary
                let assetid = assetDict.valueForKey("id") as! NSString
                self.updateStatusDictionary(globalId, url: "\(baseURL)media/\(assetId)", status: 0)
                Asset.downloadAndCreateAsset(assetId, issue: currentIssue, articleId: "", placement: index+1, delegate: self)
            }
        }
        
        //add all articles into the database
        var articles = issue.objectForKey("articles") as! NSArray
        for (index, articleDict) in enumerate(articles) {
            //Insert article
            //Add article and its assets to Issue dictionary
            let articleId = articleDict.valueForKey("id") as! NSString
            self.updateStatusDictionary(globalId, url: "\(baseURL)articles/\(articleId)", status: 0)
            Article.createArticleForId(articleId, issue: currentIssue, placement: index+1, delegate: self)
        }
        
        //Mark issue URL as done
        self.updateStatusDictionary(globalId, url: "\(baseURL)issues/\(globalId)", status: 1)
        
        //Fire a notification that issue's data is saved
        NSNotificationCenter.defaultCenter().postNotificationName(ISSUE_DOWNLOAD_COMPLETE, object: nil, userInfo: NSDictionary(object: globalId, forKey: "issue") as! [String : String])
        
        return 0
    }
    
    /**
    @brief Print log of all issues
    
    @description The method is for testing only. It prints the available issues for a client api key
    */
    public func listIssues() {
        
        let requestURL = "\(baseURL)issues"
        
        var networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                var response: NSDictionary = data as! NSDictionary
                var allIssues: NSArray = response.valueForKey("issues") as! NSArray
                println("ISSUES: \(allIssues)")
            }
            else if let err = error {
                println("Error: " + err.description)
            }
            
        }
    }
    
    /**
    @brief Search for an issue with an apple id
    
    @description The method searches for an issue with a specific Apple ID. If the issue is not available in the database, the issue will be downloaded from the Magnet API and added to the DB
    
    @param appleId The SKU/Apple id for the issue
    
    @return Issue object or nil if the issue is not in the database or on the server
    */
    public func searchIssueFor(appleId: String) -> Issue? {
        
        var issue = Issue.getIssueFor(appleId)
        
        if issue == nil {
            
            let requestURL = "\(baseURL)issues/sku/\(appleId)"
            
            var networkManager = LRNetworkManager.sharedInstance
            
            networkManager.requestData("GET", urlString: requestURL) {
                (data:AnyObject?, error:NSError?) -> () in
                if data != nil {
                    var response: NSDictionary = data as! NSDictionary
                    var allIssues: NSArray = response.valueForKey("issues") as! NSArray
                    let issueDetails: NSDictionary = allIssues.firstObject as! NSDictionary
                    //Update issue now
                    self.updateIssueFromAPI(issueDetails, globalId: issueDetails.objectForKey("id") as! String)
                }
                else if let err = error {
                    println("Error: " + err.description)
                }
                
            }
        }
        
        return issue
    }
    
    /**
    @brief Get issue details from database for a specific global id
    
    @param issueId global id of the issue
    
    @return Issue object or nil if the issue is not in the database
    */
    public func getIssue(issueId: NSString) -> Issue? {
        
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = %@", issueId)
        var issues = Issue.objectsWithPredicate(predicate)
        
        if issues.count > 0 {
            return issues.firstObject() as? Issue
        }
        
        return nil
    }
    
    //MARK: Publish issue on Newsstand
    
    /**
    @brief Add issue on Newsstand
    
    @param issueId global id of the issue
    */
    public func addIssueOnNewsstand(issueId: String) {
        
        if let issue = self.getIssue(issueId) {
            var library = NKLibrary.sharedLibrary()
            
            if let issueAppleId = issue.appleId as String? {
                let existingIssue = library.issueWithName(issueAppleId) as NKIssue?
                if existingIssue == nil {
                    //Insert issue to Newsstand
                    library.addIssueWithName(issueAppleId, date: issue.publishedDate)
                }
            }
            
            //Update issue cover icon
            self.updateIssueCoverIcon()
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
    
    //MARK: Downloads tracking
    
    //status = 0 for not started, 1 for complete, 2 for error
    func updateStatusDictionary(issueId: String, url: String, status: Int) {
        var dictionaryLock = NSLock()
        dictionaryLock.lock()
        var issueStatus: NSMutableDictionary = NSMutableDictionary(dictionary: self.activeDownloads.valueForKey(issueId) as! NSDictionary)
        issueStatus.setValue(NSNumber(integer: status), forKey: url)
        self.activeDownloads.setValue(issueStatus, forKey: issueId)
        dictionaryLock.unlock()
        
        //Check if all values 1 or 2 for the dictionary, send out a notification
        var stats = issueStatus.allValues
        var keys: [String] = issueStatus.allKeys as! [String]
        var predicate = NSPredicate(format: "SELF contains[c] %@", "/articles/")
        var articleKeys = (keys as NSArray).filteredArrayUsingPredicate(predicate)
        
        var values: NSArray = issueStatus.objectsForKeys(articleKeys, notFoundMarker: NSNumber(integer: 0))
        if values.count > 0 && values.containsObject(NSNumber(integer: 0)) { //All articles not downloaded yet
        }
        else {
            //All articles downloaded (with or without errors)
            NSNotificationCenter.defaultCenter().postNotificationName(ARTICLES_DOWNLOAD_COMPLETE, object: nil, userInfo: NSDictionary(object: issueId, forKey: "issue") as! [String : String])
            
            if stats.count > 1 && (stats as NSArray).containsObject(NSNumber(integer: 0)) { //Found a 0 - download of issue not complete
            }
            else {
                //Issue download complete (with or without errors)
                //MARK: Note - Can send status as well
                NSNotificationCenter.defaultCenter().postNotificationName(DOWNLOAD_COMPLETE, object: nil, userInfo: NSDictionary(object: issueId, forKey: "issue") as! [String : String])
            }
        }
    }
    
    //Find download % progress for an issue
    public func findDownloadProgress(issueId: String) -> Int {
        var issueStatus: NSMutableDictionary = NSMutableDictionary(dictionary: self.activeDownloads.valueForKey(issueId) as! NSDictionary)
        var values = issueStatus.allValues
        var occurrences = 0
        for value in values {
            occurrences += (value.integerValue != 0) ? 1 : 0
        }
        
        let percent = occurrences * 100 / values.count
        return percent
    }
    
    /**
    @brief Get issue ids whose download not complete yet
    
    @return array with issue ids whose download is not complete
    */
    //
    public func getActiveDownloads() -> NSArray? {
        //Return issueId whose download is not complete yet
        var issueIds = NSMutableArray(array: self.activeDownloads.allKeys)
        for (issueid, urls) in self.activeDownloads {
            var stats = urls.allValues //get all URLs status for the issueId
        
            if stats.count > 1 && (stats as NSArray).containsObject(NSNumber(integer: 0)) { //Found a 0 - download of issue not complete
            }
            else {
                //Issue download complete - remove from array to be returned
                issueIds.removeObject(issueid)
            }
        }
        
        return issueIds
    }
    
}