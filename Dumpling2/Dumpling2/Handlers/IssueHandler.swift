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
open class IssueHandler: NSObject {
    
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
        
        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            let folderPath = folder.replacingOccurrences(of: docsDir as String, with: "/Documents")
            self.defaultFolder = folderPath as NSString!
        }
        else {
            self.defaultFolder = folder
        }
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.default()
        realmConfiguration.fileURL = NSURL.fileURL(withPath: defaultRealmPath)
        RLMRealmConfiguration.setDefault(realmConfiguration)
        
        self.checkAndMigrateData(5)
        
        let mainBundle = Bundle.main
        if let key: String = mainBundle.object(forInfoDictionaryKey: "ClientKey") as? String {
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
        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        self.defaultFolder = "/Documents" //docsDir
        clientKey = clientKey as String
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(docsDir)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.default()
        realmConfiguration.fileURL = NSURL.fileURL(withPath: defaultRealmPath)
        RLMRealmConfiguration.setDefault(realmConfiguration)
        
        self.checkAndMigrateData(5)
    }
    
    
    
    /**
    Initializes the IssueHandler with a custom directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
    :brief: Initializer object
    
    - parameter folder: The folder where the database and downloaded assets should be saved
    
    - parameter clientkey: Client API key to be used for making calls to the Magnet API
    */
    public init(folder: NSString, clientkey: NSString) {
        super.init()
        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            let folderPath = folder.replacingOccurrences(of: docsDir as String, with: "/Documents")
            self.defaultFolder = folderPath as NSString!
        }
        else {
            self.defaultFolder = folder
        }
        clientKey = clientkey as String
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.default()
        realmConfiguration.fileURL = NSURL.fileURL(withPath: defaultRealmPath)
        RLMRealmConfiguration.setDefault(realmConfiguration)
        
        self.checkAndMigrateData(5)
        
    }
    
    public init(folder: NSString, clientkey: NSString, migration: Bool) {
        super.init()
        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            let folderPath = folder.replacingOccurrences(of: docsDir as String, with: "/Documents")
            self.defaultFolder = folderPath as NSString!
        }
        else {
            self.defaultFolder = folder
        }
        clientKey = clientkey as String
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.default()
        realmConfiguration.fileURL = NSURL.fileURL(withPath: defaultRealmPath)
        RLMRealmConfiguration.setDefault(realmConfiguration)
        
        if migration {
            self.checkAndMigrateData(5)
        }
        
    }
    
    //Check and migrate Realm data if needed
    fileprivate func checkAndMigrateData(_ schemaVersion: UInt64) {
        
        let config = RLMRealmConfiguration.default()
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
                            if let newProp = newObject!.objectSchema[prop.name as! String] {
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
        }
        config.migrationBlock = migrationBlock
        RLMRealmConfiguration.setDefault(config)
        
        do {
            let _ = try RLMRealm(configuration: RLMRealmConfiguration.default())
        } catch {
            self.cleanupRealm()
            self.createRealmAgain(schemaVersion)
        }
    }
    
    fileprivate func cleanupRealm() {
        var folderPath = ""
        if defaultFolder == "/Documents" {
            var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let docsDir: String = docPaths[0] as String
            folderPath = docsDir
        }
        else {
            folderPath = self.defaultFolder as String
        }
        do {
            let files: NSArray = try FileManager.default.contentsOfDirectory(atPath: folderPath) as NSArray
            let realmFiles = files.filtered(using: NSPredicate(format: "self BEGINSWITH %@", "default.realm"))
            
            //Delete all files with the given names
            for fileName: String in realmFiles as! [String] {
                try FileManager.default.removeItem(atPath: "\(folderPath)/\(fileName)")
            }
        } catch{
            NSLog("REALM:: Deleting failed")
        }
    }
    
    fileprivate func createRealmAgain(_ schemaVersion: UInt64) {
        var folderPath = self.defaultFolder
        if folderPath == "/Documents" {
            var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            folderPath = "\(docsDir)/default.realm" as NSString?
        }
        else {
            folderPath = "\(folderPath)/default.realm" as NSString?
        }
        let realmConfiguration = RLMRealmConfiguration.default()
        realmConfiguration.schemaVersion = schemaVersion
        realmConfiguration.fileURL = NSURL.fileURL(withPath: folderPath as! String)
        RLMRealmConfiguration.setDefault(realmConfiguration)
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
    open func addIssueFromAPI(_ issueId: String, volumeId: String?, withArticles: Bool) {        
        let requestURL = "\(baseURL)issues/\(issueId)"
        
        if volumeId == nil {
            //Independent issue - have an entry with the issueId key
            
            //self.updateStatusDictionary(nil, issueId: issueId, url: requestURL, status: 0)
            self.activeDownloads.setObject(NSDictionary(object: NSNumber(value: false as Bool) , forKey: requestURL as NSCopying), forKey: issueId as NSCopying)
        }
        else if let volId = volumeId {
            //Issue of a volume. Add the issue as one of the downloads for the volume
            //self.updateStatusDictionary(volId, issueId: issueId, url: requestURL, status: 0)
            self.activeDownloads.setObject(NSDictionary(object: NSNumber(value: false as Bool) , forKey: requestURL as NSCopying), forKey: volId as NSCopying)
        }
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.value(forKey: "issues") as! NSArray
                if let issueDetails: NSDictionary = allIssues.firstObject as? NSDictionary {
                    //Update issue now
                    self.updateIssueFromAPI(issueDetails, globalId: issueDetails.object(forKey: "id") as! String, volumeId: volumeId, withArticles: withArticles)
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
    open func addAllIssues() {
        
        let requestURL = "\(baseURL)issues/published"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.value(forKey: "issues") as! NSArray
                if allIssues.count > 0 {
                    for (_, issueDict) in allIssues.enumerated() {
                        let issueDictionary = issueDict as! NSDictionary
                        let issueId = issueDictionary.value(forKey: "id") as! String
                        self.addIssueFromAPI(issueId, volumeId: nil, withArticles: true)
                    }
                }
                else {
                    //No issues, send allDownloadsComplete notif
                    NotificationCenter.default.post(name: Notification.Name(rawValue: ALL_DOWNLOADS_COMPLETE), object: nil, userInfo: ["articles" : ""])
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                //Error
                NotificationCenter.default.post(name: Notification.Name(rawValue: ALL_DOWNLOADS_COMPLETE), object: nil, userInfo: ["articles" : ""])
            }
        }
    }
    
    /**
     The method gets all issues from the Magnet API for the client key and adds them to the database without articles
     */
    open func addOnlyIssuesWithoutArticles() {
        
        let requestURL = "\(baseURL)issues/published"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.value(forKey: "issues") as! NSArray
                if allIssues.count > 0 {
                    for (_, issueDict) in allIssues.enumerated() {
                        let issueDictionary = issueDict as! NSDictionary
                        let issueId = issueDictionary.value(forKey: "id") as! String
                        self.addIssueFromAPI(issueId, volumeId: nil, withArticles: false)
                    }
                }
                else {
                    //No issues, send allDownloadsComplete notif
                    NotificationCenter.default.post(name: Notification.Name(rawValue: ALL_DOWNLOADS_COMPLETE), object: nil, userInfo: ["articles" : ""])
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                //Error
                NotificationCenter.default.post(name: Notification.Name(rawValue: ALL_DOWNLOADS_COMPLETE), object: nil, userInfo: ["articles" : ""])
            }
        }
    }
    
    /**
    The method gets preview issues from the Magnet API for the client key and adds them to the database
    */
    open func addPreviewIssues() {
        
        let requestURL = "\(baseURL)issues/preview"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.value(forKey: "issues") as! NSArray
                if allIssues.count > 0 {
                    for (_, issueDict) in allIssues.enumerated() {
                        let issueDictionary = issueDict as! NSDictionary
                        let issueId = issueDictionary.value(forKey: "id") as! String
                        self.addIssueFromAPI(issueId, volumeId: nil, withArticles: true)
                    }
                }
                else {
                    //No issues, send allDownloadsComplete notif
                    NotificationCenter.default.post(name: Notification.Name(rawValue: ALL_DOWNLOADS_COMPLETE), object: nil, userInfo: ["articles" : ""])
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                //Error
                NotificationCenter.default.post(name: Notification.Name(rawValue: ALL_DOWNLOADS_COMPLETE), object: nil, userInfo: ["articles" : ""])
            }
        }
    }
    
    // MARK: Add/Update Issues, Assets and Articles
    
    //Add or create issue details (zip structure)
    func updateIssueMetadata(_ issue: NSDictionary, globalId: String) -> Int {
        let realm = RLMRealm.default()
        
        let results = Issue.objects(where: "globalId = '\(globalId)'")
        var currentIssue: Issue!
        
        realm.beginWriteTransaction()
        if results.count > 0 {
            //older issue
            currentIssue = results.firstObject() as! Issue
            //Delete all articles and assets if the issue already exists. Then add again
            Asset.deleteAssetsForIssue(currentIssue.globalId as NSString)
            Article.deleteArticlesFor(currentIssue.globalId as NSString)
        }
        else {
            //Create a new issue
            currentIssue = Issue()
            if let metadata: AnyObject? = issue.object(forKey: "metadata") as AnyObject?? {
                if metadata is NSDictionary {
                    currentIssue.metadata = Helper.stringFromJSON(metadata!)!
                }
                else {
                    currentIssue.metadata = metadata as! String
                }
            }
            currentIssue.globalId = issue.value(forKey: "global_id") as! String
        }
        
        currentIssue.title = issue.value(forKey: "title") as! String
        currentIssue.issueDesc = issue.value(forKey: "description") as! String
        currentIssue.lastUpdateDate = issue.value(forKey: "last_updated") as! String
        currentIssue.displayDate = issue.value(forKey: "display_date") as! String
        currentIssue.publishedDate = Helper.publishedDateFrom(issue.value(forKey: "publish_date") as! String)
        currentIssue.appleId = issue.value(forKey: "apple_id") as! String
        currentIssue.assetFolder = "\(self.defaultFolder)/\(currentIssue.appleId)"
        
        realm.addOrUpdate(currentIssue)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving issue: \(error)")
        }
        //realm.commitWriteTransaction()

        //Add all assets of the issue (which do not have an associated article)
        let orderedArray = (issue.object(forKey: "images") as AnyObject).object(forKey: "ordered") as! NSArray
        if orderedArray.count > 0 {
            for (index, assetDict) in orderedArray.enumerated() {
                //create asset
                Asset.createAsset(assetDict as! NSDictionary, issue: currentIssue, articleId: "", placement: index+1)
            }
        }
        
        //define cover image for issue
        if let firstAsset = Asset.getFirstAssetFor(currentIssue.globalId, articleId: "", volumeId: currentIssue.volumeId) {
            realm.beginWriteTransaction()
            currentIssue.coverImageId = firstAsset.globalId
            realm.addOrUpdate(currentIssue)
            do {
                try realm.commitWriteTransaction()
            } catch let error {
                NSLog("Error saving issue details: \(error)")
            }
            //realm.commitWriteTransaction()
        }
        
        //Now add all articles into the database
        let articles = issue.object(forKey: "articles") as! NSArray
        for (index, articleDict) in articles.enumerated() {
            //Insert article for issueId x with placement y
            Article.createArticle(articleDict as! NSDictionary, issue: currentIssue, placement: index+1)
        }
        
        return 0
    }
    
    //Add or create issue details (from API)
    func updateIssueFromAPI(_ issue: NSDictionary, globalId: String, volumeId: String?, withArticles: Bool) -> Int {
        let realm = RLMRealm.default()
        let results = Issue.objects(where: "globalId = '\(globalId)'")
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
        currentIssue.title = issue.value(forKey: "title") as! String
        currentIssue.issueDesc = issue.value(forKey: "description") as! String
        
        if let volId = volumeId {
            currentIssue.volumeId = volId
        }
        
        let meta = issue.value(forKey: "meta") as! NSDictionary
        let updatedInfo = meta.value(forKey: "updated") as! NSDictionary
        let published = meta.value(forKey: "published") as! NSNumber
        
        if updatedInfo.count > 0 {
            currentIssue.lastUpdateDate = updatedInfo.value(forKey: "date") as! String
        }
        currentIssue.displayDate = meta.value(forKey: "displayDate") as! String
        currentIssue.publishedDate = Helper.publishedDateFromISO(meta.value(forKey: "created") as? String)
        currentIssue.appleId = issue.value(forKey: "sku") as! String
        
        currentIssue.assetFolder = "\(self.defaultFolder)/\(currentIssue.appleId)"
        
        var folderPath: String
        if self.defaultFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            folderPath = currentIssue.assetFolder.replacingOccurrences(of: "/Documents", with: docsDir as String)
        }
        else {
            folderPath = currentIssue.assetFolder
        }
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: folderPath, isDirectory: &isDir) {
            if isDir.boolValue {
                //Folder already exists. Do nothing
            }
        }
        else {
            do {
                //Folder doesn't exist, create folder where assets will be downloaded
                try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
        }
        
        let assetId = issue.value(forKey: "coverPhone") as! String
        if !assetId.isEmpty {
            currentIssue.coverImageId = assetId
        }
        if let iPadId = issue.value(forKey: "coverTablet") as? String {
            currentIssue.coverImageiPadId = iPadId
        }
        if let iPadId = issue.value(forKey: "coverTabletLandscape") as? String {
            currentIssue.coverImageiPadLndId = iPadId
        }
        
        let articles = issue.object(forKey: "articles") as! NSArray
        
        if let metadata: AnyObject = issue.object(forKey: "customMeta") as AnyObject? {
            if metadata is NSDictionary {
                let metadataDict = NSMutableDictionary(dictionary: metadata as! NSDictionary)
                metadataDict.setObject("\(articles.count)", forKey: "articles" as NSCopying) //count of articles
                metadataDict.setObject(published, forKey: "published" as NSCopying)
                
                currentIssue.metadata = Helper.stringFromJSON(metadataDict)!
            }
            else {
                currentIssue.metadata = metadata as! String
            }
        }
        
        realm.addOrUpdate(currentIssue)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving issue details: \(error)")
        }
        //realm.commitWriteTransaction()
        
        //Add all assets of the issue (which do not have an associated article)
        //Commented out - this will be handled by the client app - download assets when you want to
        let issueMedia = issue.object(forKey: "media") as! NSArray
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
            for (index, articleDict) in articles.enumerated() {
                //Insert article
                //Add article and its assets to Issue dictionary
                let articleId = (articleDict as AnyObject).value(forKey: "id") as! NSString
                self.updateStatusDictionary(volumeId, issueId: globalId, url: "\(baseURL)articles/\(articleId)", status: 0)
                Article.createArticleForId(articleId, issue: currentIssue, placement: index+1, delegate: self)
            }
        }
        
        //Mark issue URL as done
        self.updateStatusDictionary(volumeId, issueId: globalId, url: "\(baseURL)issues/\(globalId)", status: 1)
        
        return 0
    }
    
    /**
    The method is for testing only. It prints the available issues for a client api key
    */
    open func listIssues() {
        
        let requestURL = "\(baseURL)issues"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.value(forKey: "issues") as! NSArray
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
    open func searchIssueFor(_ appleId: String) -> Issue? {
        
        let issue = Issue.getIssueFor(appleId)
        
        if issue == nil {
            
            let requestURL = "\(baseURL)issues/sku/\(appleId)"
            
            let networkManager = LRNetworkManager.sharedInstance
            
            networkManager.requestData("GET", urlString: requestURL) {
                (data:AnyObject?, error:NSError?) -> () in
                if data != nil {
                    let response: NSDictionary = data as! NSDictionary
                    let allIssues: NSArray = response.value(forKey: "issues") as! NSArray
                    let issueDetails: NSDictionary = allIssues.firstObject as! NSDictionary
                    //Update issue now
                    let issueVolumes = issueDetails.object(forKey: "volumes") as! NSArray
                    var volumeId: String?
                    if issueVolumes.count > 0 {
                        let volumeDict: NSDictionary = issueVolumes.firstObject as! NSDictionary
                        volumeId = volumeDict.value(forKey: "id") as? String
                    }
                    self.updateIssueFromAPI(issueDetails, globalId: issueDetails.object(forKey: "id") as! String, volumeId: volumeId, withArticles: true)
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
    open func getIssue(_ issueId: NSString) -> Issue? {
        
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "globalId = %@", issueId)
        let issues = Issue.objects(with: predicate)
        
        if issues.count > 0 {
            return issues.firstObject() as? Issue
        }
        
        return nil
    }
    
    /**
     Downloads all the articles for a given issue
     
     - parameter issueId: global id of the issue
     */
    open func downloadArticlesFor(_ issueId: String) {
        _ = RLMRealm.default()
        
        if let issue = Issue.getIssue(issueId) {
            issue.downloadIssueArticles()
        }
    }
    
    /**
     Downloads all assets for a given issue (only issue assets)
     
     - parameter issueId: global id of the issue
     */
    open func downloadAssetsFor(_ issueId: String) {
        _ = RLMRealm.default()
        
        if let issue = Issue.getIssue(issueId) {
            issue.downloadIssueAssets()
        }
    }
    
    /**
     Downloads all assets for a given issue including article assets
     
     - parameter issueId: global id of the issue
     */
    open func downloadAllAssetsFor(_ issueId: String) {
        _ = RLMRealm.default()
        
        if let issue = Issue.getIssue(issueId) {
            issue.downloadAllAssets()
        }
    }
    
    //MARK: Publish issue on Newsstand
    
    /**
    Add an issue on Newsstand
    
    - parameter issueId: global id of the issue
    */
    open func addIssueOnNewsstand(_ issueId: String) {
        
        if let issue = self.getIssue(issueId as NSString) {
            let library = NKLibrary.shared()
            
            if let issueAppleId = issue.appleId as String? {
                let existingIssue = library!.issue(withName: issueAppleId) as NKIssue?
                if existingIssue == nil {
                    //Insert issue to Newsstand
                    library!.addIssue(withName: issueAppleId, date: issue.publishedDate as Date)
                }
            }
            
            //Update issue cover icon
            self.updateIssueCoverIcon()
        }
    }
    
    //Update Newsstand icon
    func updateIssueCoverIcon() {
        let issues = NKLibrary.shared()!.issues
        
        //Find newest issue
        var newestIssue: NKIssue? = nil
        for issue in issues {
            let issueDate = issue.date
            if newestIssue == nil {
                newestIssue = issue 
            }
            else if newestIssue?.date.compare(issueDate) == ComparisonResult.orderedAscending {
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
                            UIApplication.shared.setNewsstandIconImage(coverImg)
                        } else {
                            // Fallback on earlier versions
                        }
                        UIApplication.shared.applicationIconBadgeNumber = 0
                    }
                }
                
            }
        }
    }
    
    //MARK: Downloads tracking
    
    //status = 0 for not started, 1 for complete, 2 for error
    func updateStatusDictionary(_ volumeId: String?, issueId: String, url: String, status: Int) {
        let dictionaryLock = NSLock()
        dictionaryLock.lock()

        var issueStatus: NSMutableDictionary = NSMutableDictionary()
        if !Helper.isNilOrEmpty(volumeId) {
            if let volId = volumeId {
                if let dict = self.activeDownloads.value(forKey: volId) as? NSDictionary {
                    issueStatus = NSMutableDictionary(dictionary: dict)
                    issueStatus.setValue(NSNumber(value: status as Int), forKey: url)
                }
                else {
                    issueStatus.setValue(NSNumber(value: false as Bool), forKey: url)
                }
                self.activeDownloads.setValue(issueStatus, forKey: volId)
            }
        }
        else {
            //Volume id is empty. This is an independent issue
            if let dict = self.activeDownloads.value(forKey: issueId) as? NSDictionary {
                issueStatus = NSMutableDictionary(dictionary: dict)
                issueStatus.setValue(NSNumber(value: status as Int), forKey: url)
            }
            else {
                issueStatus.setValue(NSNumber(value: false as Bool), forKey: url)
            }
            self.activeDownloads.setValue(issueStatus, forKey: issueId)
        }
        
        dictionaryLock.unlock()
        
        //Check if all values 1 or 2 for the dictionary, send out a notification
        let stats = issueStatus.allValues
        let keys: [String] = issueStatus.allKeys as! [String]
        var predicate = NSPredicate(format: "SELF contains[c] %@", "/articles/")
        let articleKeys = (keys as NSArray).filtered(using: predicate)
        
        //NOTIF FOR ONE ARTICLE OF ISSUE
        if status == 1 && url.range(of: "/articles/") != nil {
            let replaceUrl = "\(baseURL)articles/"
            let articleId = url.replacingOccurrences(of: replaceUrl, with: "")
            lLog("Pushing ARTICLES_DOWNLOAD_COMPLETE for I:\(issueId)")
            NotificationCenter.default.post(name: Notification.Name(rawValue: ARTICLES_DOWNLOAD_COMPLETE), object: nil, userInfo: NSDictionary(objects: [issueId, articleId], forKeys: ["issue" as NSCopying, "article" as NSCopying]) as! [String : String])
        }
        
        var values: NSArray = issueStatus.objects(forKeys: articleKeys, notFoundMarker: NSNumber(value: 0 as Int)) as NSArray
        if values.count > 0 && values.contains(NSNumber(value: 0 as Int)) { //All articles not downloaded yet
        }
        else {
            //All articles downloaded (with or without errors) - send notif only if status of an article was updated
            if url.range(of: "/articles/") != nil {
                //let replaceUrl = "\(baseURL)articles/"
                //let articleId = url.stringByReplacingOccurrencesOfString(replaceUrl, withString: "")
                lLog("Pushing ARTICLES_DOWNLOAD_COMPLETE for I:\(issueId)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: ARTICLES_DOWNLOAD_COMPLETE), object: nil, userInfo: NSDictionary(objects: [issueId], forKeys: ["issue" as NSCopying]) as! [String : String])
            }
        }
        
        if status == 1 && url.range(of: "/media/") != nil {
            let replaceUrl = "\(baseURL)media/"
            let mediaId = url.replacingOccurrences(of: replaceUrl, with: "")
            
            if !Helper.isNilOrEmpty(issueId) {
                lLog("Pushing MEDIA_DOWNLOADED for I:\(issueId) and M:\(mediaId)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: MEDIA_DOWNLOADED), object: nil, userInfo: NSDictionary(objects: [issueId, mediaId], forKeys: ["issue" as NSCopying, "media" as NSCopying]) as! [String : String])
            }
            else if !Helper.isNilOrEmpty(volumeId) {
                lLog("Pushing MEDIA_DOWNLOADED for V:\(volumeId!) and M:\(mediaId)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: MEDIA_DOWNLOADED), object: nil, userInfo: NSDictionary(objects: [volumeId!, mediaId], forKeys: ["volume" as NSCopying, "media" as NSCopying]) as! [String : String])
            }
            else {
                lLog("Pushing MEDIA_DOWNLOADED for M:\(mediaId)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: MEDIA_DOWNLOADED), object: nil, userInfo: NSDictionary(objects: [mediaId], forKeys: ["media" as NSCopying]) as! [String : String])
            }
        }
        
        predicate = NSPredicate(format: "SELF contains[c] %@", "/issues/")
        let issueKeys = (keys as NSArray).filtered(using: predicate)
        
        values = issueStatus.objects(forKeys: issueKeys, notFoundMarker: NSNumber(value: 0 as Int)) as NSArray
        if values.count > 0 && values.contains(NSNumber(value: 0 as Int)) { //All issues not downloaded yet
        }
        else {
            //All issues downloaded (with or without errors) - there might be multiple for a volume
            var userInfoDict: NSDictionary
            if !Helper.isNilOrEmpty(volumeId) {
                let volId = volumeId
                userInfoDict = NSDictionary(object: volId!, forKey: "volume" as NSCopying)
            }
            else {
                userInfoDict = NSDictionary(object: issueId, forKey: "issue" as NSCopying)
            }
            
            //Send notification just once - not everytime there's a download
            if url.range(of: "/issues/") != nil {
                lLog("Pushing ISSUE_DOWNLOAD_COMPLETE for \(userInfoDict)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: ISSUE_DOWNLOAD_COMPLETE), object: nil, userInfo: userInfoDict as! [String : String])
            }
        }
        
        if stats.count > 1 && (stats as NSArray).contains(NSNumber(value: 0 as Int)) { //Found a 0 - download of issue not complete
        }
        else {
            //Issue or volume download complete (with or without errors)
            var userInfoDict: NSDictionary
            if !Helper.isNilOrEmpty(volumeId) {
                let volId = volumeId
                userInfoDict = NSDictionary(object: volId!, forKey: "volume" as NSCopying)
            }
            else {
                userInfoDict = NSDictionary(object: issueId, forKey: "issue" as NSCopying)
            }
            
            lLog("Pushing DOWNLOAD_COMPLETE for \(userInfoDict)")
            NotificationCenter.default.post(name: Notification.Name(rawValue: DOWNLOAD_COMPLETE), object: nil, userInfo: userInfoDict as! [String : String])
            
            //Check for all volumes/articles
            let allValues: NSArray = self.activeDownloads.allValues as NSArray //Returns an array of dictionaries
            var allDone = true
            for statusDict: NSDictionary in allValues as! [NSDictionary] {
                let statusValues: NSArray = statusDict.allValues as NSArray
                if statusValues.count > 0 && statusValues.contains(NSNumber(value: 0 as Int)) {
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
                
                let userInfoDict = NSDictionary(object: objects, forKey: key as NSCopying)
                lLog("Pushing ALL_DOWNLOADS_COMPLETE for \(userInfoDict)")
                NotificationCenter.default.post(name: Notification.Name(rawValue: ALL_DOWNLOADS_COMPLETE), object: nil, userInfo: userInfoDict as! Dictionary<String, [AnyObject]>)
            }
        }
    }
    
    /**
    Find download % progress for an issue or volume. The method requires either a volume's global id or an issue's global id. The issue's global id should be used only if it is an independent issue (i.e. not belonging to any volume)
    
    - parameter issueId: Global id of an issue
    
    - parameter volumeId: Global id of a volume
    
    :return: Download progress (in percentage) for the issue or volume
    */
    open func findDownloadProgress(_ volumeId: String?, issueId: String?) -> Int {
        if let volId = volumeId {
            let volumeStatus: NSMutableDictionary = NSMutableDictionary(dictionary: self.activeDownloads.value(forKey: volId) as! NSDictionary)
            let values = volumeStatus.allValues
            var occurrences = 0
            for value in values {
                occurrences += ((value as AnyObject).intValue != 0) ? 1 : 0
            }
            
            let percent = occurrences * 100 / values.count
            return percent
        }
        if let issueGlobalId = issueId {
            let issueStatus: NSMutableDictionary = NSMutableDictionary(dictionary: self.activeDownloads.value(forKey: issueGlobalId) as! NSDictionary)
            let values = issueStatus.allValues
            var occurrences = 0
            for value in values {
                occurrences += ((value as AnyObject).intValue != 0) ? 1 : 0
            }
            
            let percent = occurrences * 100 / values.count
            return percent
        }
        
        return 0
    }
    
    open func findAllDownloads(_ issueId: String) -> NSDictionary {
        let issueStatus: NSMutableDictionary = NSMutableDictionary(dictionary: self.activeDownloads.value(forKey: issueId) as! NSDictionary)
        return issueStatus
    }
    
    /**
    Get issue/volume ids whose download not complete yet
    
    :return: array with issue/volume ids whose download is not complete
    */
    open func getActiveDownloads() -> NSArray? {
        //Return issueId whose download is not complete yet
        let globalIds = NSMutableArray(array: self.activeDownloads.allKeys)
        for (globalid, urls) in self.activeDownloads {
            let stats = NSArray(array: (urls as AnyObject).allValues) //get all URLs status for the issueId
        
            if stats.count > 1 && stats.contains(NSNumber(value: 0 as Int)) { //Found a 0 - download of issue not complete
            }
            else {
                //Issue download complete - remove from array to be returned
                globalIds.remove(globalid)
            }
        }
        
        return globalIds
    }
    
}
