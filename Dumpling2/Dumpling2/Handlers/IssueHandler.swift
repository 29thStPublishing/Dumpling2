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
    Initializes the IssueHandler with the given folder. This is where the database and assets will be saved. The method expects to find a key `ClientKey` in the project's Info.plist with your client key. If none is found, the method returns a nil
    
    :brief: Initializer object
    
    - parameter folder: The folder where the database and downloaded assets should be saved
    */
    public init?(folder: NSString){
        super.init()
        
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            let folderPath = folder.stringByReplacingOccurrencesOfString(docsDir as String, withString: "/Documents")
            self.defaultFolder = folderPath
        }
        else {
            self.defaultFolder = folder
        }
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        self.checkAndMigrateData(8)
        
        let mainBundle = NSBundle.mainBundle()
        if let key: String = mainBundle.objectForInfoDictionaryKey("ClientKey") as? String {
            clientKey = key
        }
        else {
            return nil
        }
    }
    
    /**
    Initializes the IssueHandler with the Documents directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
    :brief: Initializer object
    
    - parameter clientkey: Client API key to be used for making calls to the Magnet API
    */
    public init(clientkey: NSString) {
        super.init()
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        self.defaultFolder = "/Documents" //docsDir
        clientKey = clientKey as String
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(docsDir)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        
        self.checkAndMigrateData(8)
    }
    
    
    
    /**
    Initializes the IssueHandler with a custom directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
    :brief: Initializer object
    
    - parameter folder: The folder where the database and downloaded assets should be saved
    
    - parameter clientkey: Client API key to be used for making calls to the Magnet API
    */
    public init(folder: NSString, clientkey: NSString) {
        super.init()
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            let folderPath = folder.stringByReplacingOccurrencesOfString(docsDir as String, withString: "/Documents")
            self.defaultFolder = folderPath
        }
        else {
            self.defaultFolder = folder
        }
        clientKey = clientkey as String
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        
        self.checkAndMigrateData(8)
        
    }
    
    public init(folder: NSString, clientkey: NSString, migration: Bool) {
        super.init()
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            let folderPath = folder.stringByReplacingOccurrencesOfString(docsDir as String, withString: "/Documents")
            self.defaultFolder = folderPath
        }
        else {
            self.defaultFolder = folder
        }
        clientKey = clientkey as String
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        
        if migration {
            self.checkAndMigrateData(8)
        }
        
    }
    
    //Check and migrate Realm data if needed
    private func checkAndMigrateData(schemaVersion: UInt64) {
        
        let config = RLMRealmConfiguration.defaultConfiguration()
        config.schemaVersion = schemaVersion
        
        let migrationBlock: (RLMMigration, UInt64) -> Void = { (migration, oldSchemeVersion) in
            //0 to 1 - adding coverImageiPadId and coverImageiPadLndId to Issue
            if oldSchemeVersion < 1 {
                migration.enumerateObjects(Issue.className()) { oldObject, newObject in
                    let coverId = oldObject!["coverImageId"] as! String
                    if let coveriPadId = newObject!["coverImageiPadId"] as? String {
                        if coveriPadId.isEmpty {
                            newObject!["coverImageiPadId"] = coverId
                            newObject!["coverImageiPadLndId"] = coverId
                        }
                    }
                    else {
                        newObject!["coverImageiPadId"] = coverId
                        newObject!["coverImageiPadLndId"] = coverId
                    }
                }
            }
            //1 to 2 - upgrade to Realm 0.92
            //2 to 3 - upgrade to Realm 0.94/.95
            //3 to 4 - upgrade to Realm 0.98.2 (required/optional properties)
            if oldSchemeVersion < 4 {
                let classes = [Article.className(), Issue.className(), Asset.className(), Magazine.className(), Volume.className(), Purchase.className()]
                for cls in classes {
                    migration.enumerateObjects(cls) { oldObject, newObject in
                        for prop in oldObject!.objectSchema.properties {
                            if let newProp = newObject!.objectSchema[prop.name] {
                                // Property does still exist
                                if prop.optional && !newProp.optional {
                                    // Property was optional, but is now required
                                    newObject![prop.name] = oldObject![prop.name]
                                }
                            }
                        }
                    }
                }
            }
            //authorBio added to articles
            if oldSchemeVersion < 5 {
                migration.enumerateObjects(Article.className()) { oldObject, newObject in
                }
            }
            //Relation added
            if oldSchemeVersion < 6 {
            }
            
            //URL params added to Asset class
            if oldSchemeVersion < 7 {
                migration.enumerateObjects(Asset.className()) { oldObject, newObject in
                }
            }
            //placement added to Relation class
            if oldSchemeVersion < 8 {
                migration.enumerateObjects(Relation.className()) { oldObject, newObject in
                }
            }
        }
        config.migrationBlock = migrationBlock
        RLMRealmConfiguration.setDefaultConfiguration(config)
        
        do {
            let _ = try RLMRealm(configuration: RLMRealmConfiguration.defaultConfiguration())
        } catch {
            self.cleanupRealm()
            self.createRealmAgain(schemaVersion)
        }
    }
    
    private func cleanupRealm() {
        var folderPath = ""
        if defaultFolder == "/Documents" {
            var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let docsDir: String = docPaths[0] as String
            folderPath = docsDir
        }
        else {
            folderPath = self.defaultFolder as String
        }
        do {
            let files: NSArray = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(folderPath) as NSArray
            let realmFiles = files.filteredArrayUsingPredicate(NSPredicate(format: "self BEGINSWITH %@", "default.realm"))
            
            //Delete all files with the given names
            for fileName: String in realmFiles as! [String] {
                try NSFileManager.defaultManager().removeItemAtPath("\(folderPath)/\(fileName)")
            }
        } catch{
            NSLog("REALM:: Deleting failed")
        }
    }
    
    private func createRealmAgain(schemaVersion: UInt64) {
        var folderPath = self.defaultFolder
        if folderPath == "/Documents" {
            var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            folderPath = "\(docsDir)/default.realm"
        }
        else {
            folderPath = "\(folderPath)/default.realm"
        }
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.schemaVersion = schemaVersion
        realmConfiguration.path = folderPath as String
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
    }
        
    // MARK: Use zip
    
    //Issue 46 
    /**
    The method uses an Apple id, gets a zip file from the project Bundle with the name appleId.zip, extracts its contents and adds the issue, articles and assets to the database
    
    :brief: Add issue details from an extracted zip file to the database
    
    - parameter appleId: The SKU/Apple id for the issue. The method looks for a zip with the same name in the Bundle
    */
    /*public func addIssueZip(appleId: NSString) {
        
        let appPath = NSBundle.mainBundle().bundlePath
        let defaultZipPath = "\(appPath)/\(appleId).zip"
        let newZipDir = "\(self.defaultFolder)/\(appleId)"
        
        var folderPath: String
        if self.defaultFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            folderPath = newZipDir.stringByReplacingOccurrencesOfString("/Documents", withString: docsDir as String)
        }
        else {
            folderPath = newZipDir
        }
        
        var isDir: ObjCBool = false
        if NSFileManager.defaultManager().fileExistsAtPath(folderPath, isDirectory: &isDir) {
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
        if self.defaultFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            jsonPath = jsonPath.stringByReplacingOccurrencesOfString("/Documents", withString: docsDir as String)
        }
        
        var fullJSON: NSString?
        do {
            fullJSON = try NSString(contentsOfFile: jsonPath, encoding: NSUTF8StringEncoding)
        } catch let error1 as NSError {
            error = error1
            NSLog("Error: \(error?.localizedDescription)")
            fullJSON = nil
        }
        
        if fullJSON == nil {
            return
        }
        
        if let issueDict: NSDictionary = Helper.jsonFromString(fullJSON! as String) as? NSDictionary {
            //if there is an issue with this issue id, remove all its content first (articles, assets)
            //Moved ^ to updateIssueMetadata method
            //now write the issue content into the database
            self.updateIssueMetadata(issueDict, globalId: issueDict.valueForKey("global_id") as! String)
        }
    }*/

    // MARK: Use API
    
    /**
    The method uses the global id of an issue, gets its content from the Magnet API and adds it to the database
    
    :brief: Get Issue details from API and add to database
    
    - parameter appleId: The SKU/Apple id for the issue. The method looks for a zip with the same name in the Bundle
    */
    public func addIssueFromAPI(issueId: String, volumeId: String?, withArticles: Bool) {
        
        let requestURL = "\(baseURL)issues/\(issueId)"
        
        if volumeId == nil {
            //Independent issue - have an entry with the issueId key
            
            self.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: issueId)
        }
        else if let volId = volumeId {
            //Issue of a volume. Add the issue as one of the downloads for the volume
            self.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: volId)
        }
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.valueForKey("issues") as! NSArray
                if let issueDetails: NSDictionary = allIssues.firstObject as? NSDictionary {
                    //Update issue now
                    self.updateIssueFromAPI(issueDetails, globalId: issueDetails.objectForKey("id") as! String, volumeId: volumeId, withArticles: withArticles)
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                //Mark issue download as failed
                self.updateStatusDictionary(volumeId, issueId: issueId, url: "\(baseURL)issues/\(issueId)", status: 2)
            }
        }
    }
    
    /**
    The method gets all issues from the Magnet API for the client key and adds them to the database
    */
    
    public func addAllIssues() {
        self.addAllIssues(nil)
    }
    
    public func addAllIssues(timestamp: String?) {
        
        var requestURL = "\(baseURL)issues/published"
        
        if let timeSince = timestamp {
            requestURL += "/since/\(timeSince)"
        }
        
        requestURL += "?limit=20"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.valueForKey("issues") as! NSArray
                if allIssues.count > 0 {
                    for (_, issueDict) in allIssues.enumerate() {
                        let issueId = issueDict.valueForKey("id") as! String
                        self.addIssueFromAPI(issueId, volumeId: nil, withArticles: true)
                    }
                }
                else {
                    //No issues, send allDownloadsComplete notif
                    NSNotificationCenter.defaultCenter().postNotificationName(ALL_DOWNLOADS_COMPLETE, object: nil, userInfo: ["articles" : ""])
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                //Error
                NSNotificationCenter.defaultCenter().postNotificationName(ALL_DOWNLOADS_COMPLETE, object: nil, userInfo: ["articles" : ""])
            }
        }
    }
    
    /**
     The method gets all issues from the Magnet API for the client key and adds them to the database without articles
     */
    public func addOnlyIssuesWithoutArticles() {
        self.addOnlyIssuesWithoutArticles(nil, page: nil)
    }
    
    /**
     The method gets all issues from the Magnet API for the client key and adds them to the database without articles. Page starts at 0
     */
    public func addOnlyIssuesWithoutArticles(page: Int) {
        self.addOnlyIssuesWithoutArticles(nil, page: page + 1)
    }
    
    public func addOnlyIssuesWithoutArticles(timestamp: String?, page: Int?) {
        let relations = Relation.allObjects()
        if relations.count == 0 {
            Relation.addAllArticles()
            Relation.addAllAssets()
        }
        
        var requestURL = "\(baseURL)issues/published"
        
        if let timeSince = timestamp {
            requestURL += "/since/\(timeSince)"
        }
        
        requestURL += "?limit=20"
        
        if let pageNum = page where pageNum > 0 {
            requestURL += "&page=\(pageNum)"
        }
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.valueForKey("issues") as! NSArray
                if allIssues.count > 0 {
                    for (_, issueDict) in allIssues.enumerate() {
                        let issueId = issueDict.valueForKey("id") as! String
                        self.addIssueFromAPI(issueId, volumeId: nil, withArticles: false)
                    }
                }
                else {
                    //No issues, send allDownloadsComplete notif
                    NSNotificationCenter.defaultCenter().postNotificationName(ALL_DOWNLOADS_COMPLETE, object: nil, userInfo: ["articles" : ""])
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                //Error
                NSNotificationCenter.defaultCenter().postNotificationName(ALL_DOWNLOADS_COMPLETE, object: nil, userInfo: ["articles" : ""])
            }
        }
    }
    
    /**
    The method gets preview issues from the Magnet API for the client key and adds them to the database
    */
    public func addPreviewIssues() {
        self.addPreviewIssues(nil, page: nil)
    }
    
    /**
     The method gets preview issues from the Magnet API for the client key and adds them to the database. Page starts at 0
     */
    public func addPreviewIssues(page: Int) {
        self.addPreviewIssues(nil, page: page + 1)
    }
    
    public func addPreviewIssues(timestamp: String?, page: Int?) {
        let relations = Relation.allObjects()
        if relations.count == 0 {
            Relation.addAllArticles()
            Relation.addAllAssets()
        }
        
        var requestURL = "\(baseURL)issues/preview"
        
        if let timeSince = timestamp {
            requestURL += "/since/\(timeSince)"
        }
        
        requestURL += "?limit=20"
        if let pageNum = page where pageNum > 0 {
            requestURL += "&page=\(pageNum)"
        }
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.valueForKey("issues") as! NSArray
                if allIssues.count > 0 {
                    for (_, issueDict) in allIssues.enumerate() {
                        let issueId = issueDict.valueForKey("id") as! String
                        self.addIssueFromAPI(issueId, volumeId: nil, withArticles: false)
                    }
                }
                else {
                    //No issues, send allDownloadsComplete notif
                    NSNotificationCenter.defaultCenter().postNotificationName(ALL_DOWNLOADS_COMPLETE, object: nil, userInfo: ["articles" : ""])
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                //Error
                NSNotificationCenter.defaultCenter().postNotificationName(ALL_DOWNLOADS_COMPLETE, object: nil, userInfo: ["articles" : ""])
            }
        }
    }
    
    // MARK: Add/Update Issues, Assets and Articles
    
    //Add or create issue details (zip structure)
    func updateIssueMetadata(issue: NSDictionary, globalId: String) -> Int {
        let realm = RLMRealm.defaultRealm()
        
        let results = Issue.objectsWhere("globalId = '\(globalId)'")
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
        currentIssue.assetFolder = "\(self.defaultFolder)" ///\(currentIssue.appleId)"
        
        realm.addOrUpdateObject(currentIssue)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving issue: \(error)")
        }
        //realm.commitWriteTransaction()

        //Add all assets of the issue (which do not have an associated article)
        let orderedArray = issue.objectForKey("images")?.objectForKey("ordered") as! NSArray
        if orderedArray.count > 0 {
            for (index, assetDict) in orderedArray.enumerate() {
                //create asset
                Asset.createAsset(assetDict as! NSDictionary, issue: currentIssue, articleId: "", placement: index+1)
            }
        }
        
        //define cover image for issue
        if let firstAsset = Asset.getFirstAssetFor(currentIssue.globalId, articleId: "", volumeId: currentIssue.volumeId) {
            realm.beginWriteTransaction()
            currentIssue.coverImageId = firstAsset.globalId
            realm.addOrUpdateObject(currentIssue)
            do {
                try realm.commitWriteTransaction()
            } catch let error {
                NSLog("Error saving issue details: \(error)")
            }
            //realm.commitWriteTransaction()
        }
        
        //Now add all articles into the database
        let articles = issue.objectForKey("articles") as! NSArray
        for (index, articleDict) in articles.enumerate() {
            //Insert article for issueId x with placement y
            Article.createArticle(articleDict as! NSDictionary, issue: currentIssue, placement: index+1)
        }
        
        return 0
    }
    
    //Add or create issue details (from API)
    func updateIssueFromAPI(issue: NSDictionary, globalId: String, volumeId: String?, withArticles: Bool) -> Int {
        let realm = RLMRealm.defaultRealm()
        let results = Issue.objectsWhere("globalId = '\(globalId)'")
        var currentIssue: Issue!
        
        if results.count > 0 {
            //older issue
            currentIssue = results.firstObject() as! Issue
        }
        else {
            //Create a new issue
            currentIssue = Issue()
            currentIssue.globalId = globalId
        }
        
        realm.beginWriteTransaction()
        currentIssue.title = issue.valueForKey("title") as! String
        currentIssue.issueDesc = issue.valueForKey("description") as! String
        
        if let volId = volumeId {
            currentIssue.volumeId = volId
        }
        
        let meta = issue.valueForKey("meta") as! NSDictionary
        let updatedInfo = meta.valueForKey("updated") as! NSDictionary
        let published = meta.valueForKey("published") as! NSNumber
        
        if updatedInfo.count > 0 {
            currentIssue.lastUpdateDate = updatedInfo.valueForKey("date") as! String
        }
        currentIssue.displayDate = meta.valueForKey("displayDate") as! String
        currentIssue.publishedDate = Helper.publishedDateFromISO(meta.valueForKey("publishedDate") as? String)
        currentIssue.appleId = issue.valueForKey("sku") as! String
        
        currentIssue.assetFolder = "\(self.defaultFolder)" ///\(currentIssue.appleId)"
        
        var folderPath: String
        if self.defaultFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            folderPath = currentIssue.assetFolder.stringByReplacingOccurrencesOfString("/Documents", withString: docsDir as String)
        }
        else {
            folderPath = currentIssue.assetFolder
        }
        
        var isDir: ObjCBool = false
        if NSFileManager.defaultManager().fileExistsAtPath(folderPath, isDirectory: &isDir) {
            if isDir {
                //Folder already exists. Do nothing
            }
        }
        else {
            do {
                //Folder doesn't exist, create folder where assets will be downloaded
                try NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
        }
        
        let assetId = issue.valueForKey("coverPhone") as! String
        if !assetId.isEmpty {
            currentIssue.coverImageId = assetId
        }
        if let iPadId = issue.valueForKey("coverTablet") as? String {
            currentIssue.coverImageiPadId = iPadId
        }
        if let iPadId = issue.valueForKey("coverTabletLandscape") as? String {
            currentIssue.coverImageiPadLndId = iPadId
        }
        
        let articles = issue.objectForKey("articles") as! NSArray
        
        if let metadata: AnyObject = issue.objectForKey("customMeta") {
            if metadata.isKindOfClass(NSDictionary) {
                let metadataDict = NSMutableDictionary(dictionary: metadata as! NSDictionary)
                metadataDict.setObject("\(articles.count)", forKey: "articles") //count of articles
                metadataDict.setObject(published, forKey: "published")
                
                currentIssue.metadata = Helper.stringFromJSON(metadataDict)!
            }
            else {
                currentIssue.metadata = metadata as! String
            }
        }
        
        realm.addOrUpdateObject(currentIssue)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving issue details: \(error)")
        }
        //realm.commitWriteTransaction()
        
        //Add all assets of the issue (which do not have an associated article)
        //Commented out - this will be handled by the client app - download assets when you want to
        let issueMedia = issue.objectForKey("media") as! NSArray
        if issueMedia.count > 0 {
            for _ in issueMedia {
                //Download images and create Asset object for issue
                //Add asset to Issue dictionary

                /*let assetId = assetDict.valueForKey("id") as! NSString
                self.updateStatusDictionary(volumeId, issueId: globalId, url: "\(baseURL)media/\(assetId)", status: 0)
                Asset.downloadAndCreateAsset(assetId, issue: currentIssue, articleId: "", placement: index+1, delegate: self)*/
            }
        }
        
        //add all articles into the database
        //Download and add articles ONLY if asked to
        if withArticles {
            if articles.count > 0 {
                var articleList = ""
                for (index, articleDict) in articles.enumerate() {
                    //Insert article
                    //Add article and its assets to Issue dictionary
                    let articleId = articleDict.valueForKey("id") as! String
                    Relation.createRelation(currentIssue.globalId, articleId: articleId, assetId: nil, placement: index + 1)
                    
                    if let existingArticle = Article.getArticle(articleId, appleId: nil) {
                        var lastUpdatedDate = NSDate()
                        if let updateDate: String = existingArticle.getValue("updateDate") as? String {
                            lastUpdatedDate = Helper.publishedDateFromISO(updateDate)
                        }
                        var newUpdateDate = NSDate()
                        if let updated = articleDict.valueForKey("updated") as? NSDictionary {
                            if let date = updated.valueForKey("date") as? String {
                                newUpdateDate = Helper.publishedDateFromISO(date)
                            }
                        }
                        if newUpdateDate.compare(lastUpdatedDate) == NSComparisonResult.OrderedDescending {
                            //Have to update article
                            articleList += articleId
                            if index < (articles.count - 1) {
                                articleList += ","
                            }
                            self.updateStatusDictionary(volumeId, issueId: globalId, url: "\(baseURL)articles/\(articleId)", status: 0)
                        }
                        else {
                            existingArticle.downloadArticleAssets(self)
                        }
                    }
                    else {
                        //Have to update article
                        articleList += articleId
                        if index < (articles.count - 1) {
                            articleList += ","
                        }
                        self.updateStatusDictionary(volumeId, issueId: globalId, url: "\(baseURL)articles/\(articleId)", status: 0)
                    }
                }
                if articleList.hasSuffix(",") {
                    articleList = articleList.substringToIndex(articleList.endIndex.predecessor())
                }
                if !articleList.isEmpty {
                    Article.createArticlesForIds(articleList, issue: currentIssue, delegate: self)
                }
            }
            
        }
        
        //Mark issue URL as done
        self.updateStatusDictionary(volumeId, issueId: globalId, url: "\(baseURL)issues/\(globalId)", status: 1)
        
        return 0
    }
    
    /**
    The method is for testing only. It prints the available issues for a client api key
    */
    public func listIssues() {
        
        let requestURL = "\(baseURL)issues"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.valueForKey("issues") as! NSArray
                print("ISSUES: \(allIssues)")
            }
            else if let err = error {
                print("Error: " + err.description)
            }
            
        }
    }
    
    /**
    The method searches for an issue with a specific Apple ID. If the issue is not available in the database, the issue will be downloaded from the Magnet API and added to the DB
    
    :brief: Search for an issue with an apple id
    
    - parameter appleId: The SKU/Apple id for the issue
    
    :return: Issue object or nil if the issue is not in the database or on the server
    */
    public func searchIssueFor(appleId: String) -> Issue? {
        
        let issue = Issue.getIssueFor(appleId)
        
        if issue == nil {
            
            let requestURL = "\(baseURL)issues/sku/\(appleId)"
            
            let networkManager = LRNetworkManager.sharedInstance
            
            networkManager.requestData("GET", urlString: requestURL) {
                (data:AnyObject?, error:NSError?) -> () in
                if data != nil {
                    let response: NSDictionary = data as! NSDictionary
                    let allIssues: NSArray = response.valueForKey("issues") as! NSArray
                    let issueDetails: NSDictionary = allIssues.firstObject as! NSDictionary
                    //Update issue now
                    let issueVolumes = issueDetails.objectForKey("volumes") as! NSArray
                    var volumeId: String?
                    if issueVolumes.count > 0 {
                        let volumeDict: NSDictionary = issueVolumes.firstObject as! NSDictionary
                        volumeId = volumeDict.valueForKey("id") as? String
                    }
                    self.updateIssueFromAPI(issueDetails, globalId: issueDetails.objectForKey("id") as! String, volumeId: volumeId, withArticles: true)
                }
                else if let err = error {
                    print("Error: " + err.description)
                }
            }
        }
        
        return issue
    }
    
    /**
    Get issue details from database for a specific global id
    
    - parameter issueId: global id of the issue
    
    :return: Issue object or nil if the issue is not in the database
    */
    public func getIssue(issueId: NSString) -> Issue? {
        
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = %@", issueId)
        let issues = Issue.objectsWithPredicate(predicate)
        
        if issues.count > 0 {
            return issues.firstObject() as? Issue
        }
        
        return nil
    }
    
    /**
     Downloads all the articles for a given issue
     
     - parameter issueId: global id of the issue
     */
    public func downloadArticlesFor(issueId: String) {
        _ = RLMRealm.defaultRealm()
        
        if let issue = Issue.getIssue(issueId) {
            issue.downloadIssueArticles()
        }
    }
    
    /**
     Downloads all assets for a given issue (only issue assets)
     
     - parameter issueId: global id of the issue
     */
    public func downloadAssetsFor(issueId: String) {
        _ = RLMRealm.defaultRealm()
        
        if let issue = Issue.getIssue(issueId) {
            issue.downloadIssueAssets()
        }
    }
    
    /**
     Downloads all assets for a given issue including article assets
     
     - parameter issueId: global id of the issue
     */
    public func downloadAllAssetsFor(issueId: String) {
        _ = RLMRealm.defaultRealm()
        
        if let issue = Issue.getIssue(issueId) {
            issue.downloadAllAssets()
        }
    }
    
    //MARK: Publish issue on Newsstand
    
    /**
    Add an issue on Newsstand
    
    - parameter issueId: global id of the issue
    */
    public func addIssueOnNewsstand(issueId: String) {
        
        if let issue = self.getIssue(issueId) {
            let library = NKLibrary.sharedLibrary()
            
            if let issueAppleId = issue.appleId as String? {
                let existingIssue = library!.issueWithName(issueAppleId) as NKIssue?
                if existingIssue == nil {
                    //Insert issue to Newsstand
                    library!.addIssueWithName(issueAppleId, date: issue.publishedDate)
                }
            }
            
            //Update issue cover icon
            self.updateIssueCoverIcon()
        }
    }
    
    //Update Newsstand icon
    func updateIssueCoverIcon() {
        let issues = NKLibrary.sharedLibrary()!.issues
        
        //Find newest issue
        var newestIssue: NKIssue? = nil
        for issue in issues {
            let issueDate = issue.date
            if newestIssue == nil {
                newestIssue = issue 
            }
            else if newestIssue?.date.compare(issueDate) == NSComparisonResult.OrderedAscending {
                newestIssue = issue 
            }
        }
        
        //Get cover image of isse
        if let issue = newestIssue {
            let savedIssue = Issue.getIssueFor(issue.name)
            if savedIssue != nil {
                if let coverImageId = savedIssue?.coverImageId {
                    let asset = Asset.getAsset(coverImageId)
                    if let coverImgURL = asset?.getAssetPath() {
                        let coverImg = UIImage(contentsOfFile: coverImgURL)
                        if #available(iOS 9.0, *) {
                            UIApplication.sharedApplication().setNewsstandIconImage(coverImg)
                        } else {
                            // Fallback on earlier versions
                        }
                        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                    }
                }
                
            }
        }
    }
    
    //MARK: Downloads tracking
    
    //status = 0 for not started, 1 for complete, 2 for error, 3 for no change
    func updateStatusDictionary(volumeId: String?, issueId: String, url: String, status: Int) {
        let dictionaryLock = NSLock()
        dictionaryLock.lock()

        var issueStatus: NSMutableDictionary = NSMutableDictionary()
        if !Helper.isNilOrEmpty(volumeId) {
            if let volId = volumeId {
                if let dict = self.activeDownloads.valueForKey(volId) as? NSDictionary {
                    issueStatus = NSMutableDictionary(dictionary: dict)
                    issueStatus.setValue(NSNumber(integer: status), forKey: url)
                }
                else {
                    issueStatus.setValue(NSNumber(bool: false), forKey: url)
                }
                self.activeDownloads.setValue(issueStatus, forKey: volId)
            }
        }
        else {
            //Volume id is empty. This is an independent issue
            if let dict = self.activeDownloads.valueForKey(issueId) as? NSDictionary {
                issueStatus = NSMutableDictionary(dictionary: dict)
                issueStatus.setValue(NSNumber(integer: status), forKey: url)
            }
            else {
                issueStatus.setValue(NSNumber(bool: false), forKey: url)
            }
            self.activeDownloads.setValue(issueStatus, forKey: issueId)
        }
        
        dictionaryLock.unlock()
        
        //Check if all values 1 or 2 for the dictionary, send out a notification
        let stats = issueStatus.allValues
        let keys: [String] = issueStatus.allKeys as! [String]
        var predicate = NSPredicate(format: "SELF contains[c] %@", "/articles/")
        let articleKeys = (keys as NSArray).filteredArrayUsingPredicate(predicate)
        
        //NOTIF FOR ONE ARTICLE OF ISSUE
        if status == 1 && url.rangeOfString("/articles/") != nil {
            let replaceUrl = "\(baseURL)articles/"
            let articleId = url.stringByReplacingOccurrencesOfString(replaceUrl, withString: "")
            lLog("Pushing ARTICLES_DOWNLOAD_COMPLETE for I:\(issueId) and A: \(articleId)")
            NSNotificationCenter.defaultCenter().postNotificationName(ARTICLES_DOWNLOAD_COMPLETE, object: nil, userInfo: NSDictionary(objects: [issueId, articleId], forKeys: ["issue", "article"]) as! [String : String])
        }
        
        var values: NSArray = issueStatus.objectsForKeys(articleKeys, notFoundMarker: NSNumber(integer: 0))
        if values.count > 0 && values.containsObject(NSNumber(integer: 0)) { //All articles not downloaded yet
        }
        else {
            //All articles downloaded (with or without errors) - send notif only if status of an article was updated
            if url.rangeOfString("/articles/") != nil {
                let replaceUrl = "\(baseURL)articles/"
                let articleId = url.stringByReplacingOccurrencesOfString(replaceUrl, withString: "")
                if  status == 3 && articleId == issueId { }
                else {
                    //Notif only if article was updated, not otherwise
                    lLog("Pushing all ARTICLES_DOWNLOAD_COMPLETE for I:\(issueId)")
                    NSNotificationCenter.defaultCenter().postNotificationName(ARTICLES_DOWNLOAD_COMPLETE, object: nil, userInfo: NSDictionary(objects: [issueId], forKeys: ["issue"]) as! [String : String])
                }
            }
        }
        
        if status == 1 && url.rangeOfString("/media/") != nil {
            let replaceUrl = "\(baseURL)media/"
            let mediaId = url.stringByReplacingOccurrencesOfString(replaceUrl, withString: "")
            
            if !Helper.isNilOrEmpty(issueId) {
                lLog("Pushing MEDIA_DOWNLOADED for I:\(issueId) and M:\(mediaId)")
                NSNotificationCenter.defaultCenter().postNotificationName(MEDIA_DOWNLOADED, object: nil, userInfo: NSDictionary(objects: [issueId, mediaId], forKeys: ["issue", "media"]) as! [String : String])
            }
            else if !Helper.isNilOrEmpty(volumeId) {
                lLog("Pushing MEDIA_DOWNLOADED for V:\(volumeId!) and M:\(mediaId)")
                NSNotificationCenter.defaultCenter().postNotificationName(MEDIA_DOWNLOADED, object: nil, userInfo: NSDictionary(objects: [volumeId!, mediaId], forKeys: ["volume", "media"]) as! [String : String])
            }
            else {
                lLog("Pushing MEDIA_DOWNLOADED for M:\(mediaId)")
                NSNotificationCenter.defaultCenter().postNotificationName(MEDIA_DOWNLOADED, object: nil, userInfo: NSDictionary(objects: [mediaId], forKeys: ["media"]) as! [String : String])
            }
        }
        
        predicate = NSPredicate(format: "SELF contains[c] %@", "/issues/")
        let issueKeys = (keys as NSArray).filteredArrayUsingPredicate(predicate)
        
        values = issueStatus.objectsForKeys(issueKeys, notFoundMarker: NSNumber(integer: 0))
        if values.count > 0 && values.containsObject(NSNumber(integer: 0)) { //All issues not downloaded yet
        }
        else {
            //All issues downloaded (with or without errors) - there might be multiple for a volume
            var userInfoDict: NSDictionary
            if !Helper.isNilOrEmpty(volumeId) {
                let volId = volumeId
                userInfoDict = NSDictionary(object: volId!, forKey: "volume")
            }
            else {
                userInfoDict = NSDictionary(object: issueId, forKey: "issue")
            }
            
            //Send notification just once - not everytime there's a download
            if url.rangeOfString("/issues/") != nil {
                lLog("Pushing ISSUE_DOWNLOAD_COMPLETE for \(userInfoDict)")
                NSNotificationCenter.defaultCenter().postNotificationName(ISSUE_DOWNLOAD_COMPLETE, object: nil, userInfo: userInfoDict as! [String : String])
            }
        }
        
        if stats.count > 1 && (stats as NSArray).containsObject(NSNumber(integer: 0)) { //Found a 0 - download of issue not complete
        }
        else {
            //Issue or volume download complete (with or without errors)
            var userInfoDict: NSDictionary
            if !Helper.isNilOrEmpty(volumeId) {
                let volId = volumeId
                userInfoDict = NSDictionary(object: volId!, forKey: "volume")
            }
            else {
                userInfoDict = NSDictionary(object: issueId, forKey: "issue")
            }
            
            lLog("Pushing DOWNLOAD_COMPLETE for \(userInfoDict)")
            NSNotificationCenter.defaultCenter().postNotificationName(DOWNLOAD_COMPLETE, object: nil, userInfo: userInfoDict as! [String : String])
            
            //Check for all volumes/articles
            let allValues: NSArray = self.activeDownloads.allValues //Returns an array of dictionaries
            var allDone = true
            for statusDict: NSDictionary in allValues as! [NSDictionary] {
                let statusValues: NSArray = statusDict.allValues
                if statusValues.count > 0 && statusValues.containsObject(NSNumber(integer: 0)) {
                    //Found a 0 - download not complete
                    allDone = false
                    break
                }
            }
            if allDone && allValues.count > 1 {
                //All downloads complete - send notification
                let objects: [AnyObject] = self.activeDownloads.allKeys as [AnyObject]
                var key = "articles"
                if !Helper.isNilOrEmpty(volumeId) {
                    key = "volumes"
                }
                
                let userInfoDict = NSDictionary(object: objects, forKey: key)
                lLog("Pushing ALL_DOWNLOADS_COMPLETE for \(userInfoDict)")
                NSNotificationCenter.defaultCenter().postNotificationName(ALL_DOWNLOADS_COMPLETE, object: nil, userInfo: userInfoDict as! Dictionary<String, [AnyObject]>)
            }
        }
    }
    
    /**
    Find download % progress for an issue or volume. The method requires either a volume's global id or an issue's global id. The issue's global id should be used only if it is an independent issue (i.e. not belonging to any volume)
    
    - parameter issueId: Global id of an issue
    
    - parameter volumeId: Global id of a volume
    
    :return: Download progress (in percentage) for the issue or volume
    */
    public func findDownloadProgress(volumeId: String?, issueId: String?) -> Int {
        if let volId = volumeId {
            let volumeStatus: NSMutableDictionary = NSMutableDictionary(dictionary: self.activeDownloads.valueForKey(volId) as! NSDictionary)
            let values = volumeStatus.allValues
            var occurrences = 0
            for value in values {
                occurrences += (value.integerValue != 0) ? 1 : 0
            }
            
            let percent = occurrences * 100 / values.count
            return percent
        }
        if let issueGlobalId = issueId {
            let issueStatus: NSMutableDictionary = NSMutableDictionary(dictionary: self.activeDownloads.valueForKey(issueGlobalId) as! NSDictionary)
            let values = issueStatus.allValues
            var occurrences = 0
            for value in values {
                occurrences += (value.integerValue != 0) ? 1 : 0
            }
            
            let percent = occurrences * 100 / values.count
            return percent
        }
        
        return 0
    }
    
    public func findAllDownloads(issueId: String) -> NSDictionary {
        let issueStatus: NSMutableDictionary = NSMutableDictionary(dictionary: self.activeDownloads.valueForKey(issueId) as! NSDictionary)
        return issueStatus
    }
    
    /**
    Get issue/volume ids whose download not complete yet
    
    :return: array with issue/volume ids whose download is not complete
    */
    public func getActiveDownloads() -> NSArray? {
        //Return issueId whose download is not complete yet
        let globalIds = NSMutableArray(array: self.activeDownloads.allKeys)
        for (globalid, urls) in self.activeDownloads {
            let stats = urls.allValues //get all URLs status for the issueId
        
            if stats.count > 1 && (stats as NSArray).containsObject(NSNumber(integer: 0)) { //Found a 0 - download of issue not complete
            }
            else {
                //Issue download complete - remove from array to be returned
                globalIds.removeObject(globalid)
            }
        }
        
        return globalIds
    }
    
}