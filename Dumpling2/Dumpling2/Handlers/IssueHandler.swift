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
    :brief: Initializer object
    
    :discussion: Initializes the IssueHandler with the Documents directory. This is where the database and assets will be saved
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
    Initializes the IssueHandler with the given folder. This is where the database and assets will be saved. The method expects to find a key `ClientKey` in the project's Info.plist with your client key. If none is found, the method returns a nil
    
    :brief: Initializer object
    
    :param: folder The folder where the database and downloaded assets should be saved
    */
    public init?(folder: NSString){
        super.init()
        
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir: NSString = docPaths[0] as! NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            var folderPath = folder.stringByReplacingOccurrencesOfString(docsDir as String, withString: "/Documents")
            self.defaultFolder = folderPath
        }
        else {
            self.defaultFolder = folder
        }
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(folder)/default.realm"
        RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
        var mainBundle = NSBundle.mainBundle()
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
    
    :param: clientkey Client API key to be used for making calls to the Magnet API
    */
    public init(clientkey: NSString) {
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir: NSString = docPaths[0] as! NSString
        
        self.defaultFolder = "/Documents" //docsDir
        clientKey = clientKey as String
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(docsDir)/default.realm"
        RLMRealm.setDefaultRealmPath(defaultRealmPath)
    }
    
    /**
    Initializes the IssueHandler with a custom directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
    :brief: Initializer object
    
    :param: folder The folder where the database and downloaded assets should be saved
    
    :param: clientkey Client API key to be used for making calls to the Magnet API
    */
    public init(folder: NSString, clientkey: NSString) {
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir: NSString = docPaths[0] as! NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            var folderPath = folder.stringByReplacingOccurrencesOfString(docsDir as String, withString: "/Documents")
            self.defaultFolder = folderPath
        }
        else {
            self.defaultFolder = folder
        }
        clientKey = clientkey as String
        self.activeDownloads = NSMutableDictionary()
        
        let defaultRealmPath = "\(folder)/default.realm"
        RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
    }
        
    // MARK: Use zip
    
    /**
    The method uses an Apple id, gets a zip file from the project Bundle with the name appleId.zip, extracts its contents and adds the issue, articles and assets to the database
    
    :brief: Add issue details from an extracted zip file to the database
    
    :param: appleId The SKU/Apple id for the issue. The method looks for a zip with the same name in the Bundle
    */
    public func addIssueZip(appleId: NSString) {
        /* Step 1 - import zip file */
        
        var appPath = NSBundle.mainBundle().bundlePath
        var defaultZipPath = "\(appPath)/\(appleId).zip"
        var newZipDir = "\(self.defaultFolder)/\(appleId)"
        
        var folderPath: String
        if self.defaultFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            var docsDir: NSString = docPaths[0] as! NSString
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
            var docsDir: NSString = docPaths[0] as! NSString
            jsonPath = jsonPath.stringByReplacingOccurrencesOfString("/Documents", withString: docsDir as String)
        }
        
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
    The method uses the global id of an issue, gets its content from the Magnet API and adds it to the database
    
    :brief: Get Issue details from API and add to database
    
    :param: appleId The SKU/Apple id for the issue. The method looks for a zip with the same name in the Bundle
    */
    public func addIssueFromAPI(issueId: String, volumeId: String?) {
        
        let requestURL = "\(baseURL)issues/\(issueId)"
        
        if volumeId == nil {
            //Independent issue - have an entry with the issueId key
            self.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: issueId)
        }
        else if let volId = volumeId {
            //Issue of a volume. Add the issue as one of the downloads for the volume
            self.updateStatusDictionary(volId, issueId: issueId, url: requestURL, status: 0)
            //self.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: volId)
        }
        
        var networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                var response: NSDictionary = data as! NSDictionary
                var allIssues: NSArray = response.valueForKey("issues") as! NSArray
                if let issueDetails: NSDictionary = allIssues.firstObject as? NSDictionary {
                    //Update issue now
                    self.updateIssueFromAPI(issueDetails, globalId: issueDetails.objectForKey("id") as! String, volumeId: volumeId)
                }
            }
            else if let err = error {
                println("Error: " + err.description)
                //Mark issue download as failed
                self.updateStatusDictionary(volumeId, issueId: issueId, url: "\(baseURL)issues/\(issueId)", status: 2)
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
        if let firstAsset = Asset.getFirstAssetFor(currentIssue.globalId, articleId: "", volumeId: currentIssue.volumeId) {
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
    func updateIssueFromAPI(issue: NSDictionary, globalId: String, volumeId: String?) -> Int {
        let realm = RLMRealm.defaultRealm()
        var results = Issue.objectsWhere("globalId = '\(globalId)'")
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
        
        var meta = issue.valueForKey("meta") as! NSDictionary
        var updatedInfo = meta.valueForKey("updated") as! NSDictionary
        
        if updatedInfo.count > 0 {
            currentIssue.lastUpdateDate = updatedInfo.valueForKey("date") as! String
        }
        currentIssue.displayDate = meta.valueForKey("displayDate") as! String
        currentIssue.publishedDate = Helper.publishedDateFromISO(meta.valueForKey("created") as? String)
        currentIssue.appleId = issue.valueForKey("sku") as! String
        
        currentIssue.assetFolder = "\(self.defaultFolder)/\(currentIssue.appleId)"
        
        var folderPath: String
        if self.defaultFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            var docsDir: NSString = docPaths[0] as! NSString
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
            //Folder doesn't exist, create folder where assets will be downloaded
            NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil, error: nil)
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
                self.updateStatusDictionary(volumeId, issueId: globalId, url: "\(baseURL)media/\(assetId)", status: 0)
                Asset.downloadAndCreateAsset(assetId, issue: currentIssue, articleId: "", placement: index+1, delegate: self)
            }
        }
        
        //add all articles into the database
        var articles = issue.objectForKey("articles") as! NSArray
        for (index, articleDict) in enumerate(articles) {
            //Insert article
            //Add article and its assets to Issue dictionary
            let articleId = articleDict.valueForKey("id") as! NSString
            self.updateStatusDictionary(volumeId, issueId: globalId, url: "\(baseURL)articles/\(articleId)", status: 0)
            Article.createArticleForId(articleId, issue: currentIssue, placement: index+1, delegate: self)
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
    The method searches for an issue with a specific Apple ID. If the issue is not available in the database, the issue will be downloaded from the Magnet API and added to the DB
    
    :brief: Search for an issue with an apple id
    
    :param: appleId The SKU/Apple id for the issue
    
    :return: Issue object or nil if the issue is not in the database or on the server
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
                    var issueVolumes = issueDetails.objectForKey("volumes") as! NSArray
                    var volumeId: String?
                    if issueVolumes.count > 0 {
                        var volumeDict: NSDictionary = issueVolumes.firstObject as! NSDictionary
                        volumeId = volumeDict.valueForKey("id") as? String
                    }
                    self.updateIssueFromAPI(issueDetails, globalId: issueDetails.objectForKey("id") as! String, volumeId: volumeId)
                }
                else if let err = error {
                    println("Error: " + err.description)
                }
            }
        }
        
        return issue
    }
    
    /**
    Get issue details from database for a specific global id
    
    :param: issueId global id of the issue
    
    :return: Issue object or nil if the issue is not in the database
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
    Add an issue on Newsstand
    
    :param: issueId global id of the issue
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
                    if let coverImgURL = asset?.getAssetPath() {
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
    func updateStatusDictionary(volumeId: String?, issueId: String, url: String, status: Int) {
        var dictionaryLock = NSLock()
        dictionaryLock.lock()

        var issueStatus: NSMutableDictionary = NSMutableDictionary()
        if !Helper.isNilOrEmpty(volumeId) {
            if let volId = volumeId {
                issueStatus = NSMutableDictionary(dictionary: self.activeDownloads.valueForKey(volId) as! NSDictionary)
                issueStatus.setValue(NSNumber(integer: status), forKey: url)
                self.activeDownloads.setValue(issueStatus, forKey: volId)
            }
        }
        else {
            //Volume id is empty. This is an independent issue
            issueStatus = NSMutableDictionary(dictionary: self.activeDownloads.valueForKey(issueId) as! NSDictionary)
            issueStatus.setValue(NSNumber(integer: status), forKey: url)
            self.activeDownloads.setValue(issueStatus, forKey: issueId)
        }
        
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
            //All articles downloaded (with or without errors) - send notif only if status of an article was updated
            if url.rangeOfString("/articles/") != nil {
                NSNotificationCenter.defaultCenter().postNotificationName(ARTICLES_DOWNLOAD_COMPLETE, object: nil, userInfo: NSDictionary(object: issueId, forKey: "issue") as! [String : String])
            }
        }
        
        predicate = NSPredicate(format: "SELF contains[c] %@", "/issues/")
        var issueKeys = (keys as NSArray).filteredArrayUsingPredicate(predicate)
        
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
            
            NSNotificationCenter.defaultCenter().postNotificationName(ISSUE_DOWNLOAD_COMPLETE, object: nil, userInfo: userInfoDict as! [String : String])
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
            
            NSNotificationCenter.defaultCenter().postNotificationName(DOWNLOAD_COMPLETE, object: nil, userInfo: userInfoDict as! [String : String])
            
            //Check for all volumes/articles
            var allValues: NSArray = self.activeDownloads.allValues //Returns an array of dictionaries
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
                var objects: [AnyObject] = self.activeDownloads.allKeys as [AnyObject]
                var key = "articles"
                if !Helper.isNilOrEmpty(volumeId) {
                    key = "volumes"
                }
                
                var userInfoDict = NSDictionary(object: objects, forKey: key)
                NSNotificationCenter.defaultCenter().postNotificationName(ALL_DOWNLOADS_COMPLETE, object: nil, userInfo: userInfoDict as! Dictionary<String, [AnyObject]>)
            }
        }
    }
    
    /**
    Find download % progress for an issue or volume. The method requires either a volume's global id or an issue's global id. The issue's global id should be used only if it is an independent issue (i.e. not belonging to any volume)
    
    :param: issueId Global id of an issue
    
    :param: volumeId Global id of a volume
    
    :return: Download progress (in percentage) for the issue or volume
    */
    public func findDownloadProgress(volumeId: String?, issueId: String?) -> Int {
        if let volId = volumeId {
            var volumeStatus: NSMutableDictionary = NSMutableDictionary(dictionary: self.activeDownloads.valueForKey(volId) as! NSDictionary)
            var values = volumeStatus.allValues
            var occurrences = 0
            for value in values {
                occurrences += (value.integerValue != 0) ? 1 : 0
            }
            
            let percent = occurrences * 100 / values.count
            return percent
        }
        if let issueGlobalId = issueId {
            var issueStatus: NSMutableDictionary = NSMutableDictionary(dictionary: self.activeDownloads.valueForKey(issueGlobalId) as! NSDictionary)
            var values = issueStatus.allValues
            var occurrences = 0
            for value in values {
                occurrences += (value.integerValue != 0) ? 1 : 0
            }
            
            let percent = occurrences * 100 / values.count
            return percent
        }
        
        return 0
    }
    
    /**
    Get issue/volume ids whose download not complete yet
    
    :return: array with issue/volume ids whose download is not complete
    */
    public func getActiveDownloads() -> NSArray? {
        //Return issueId whose download is not complete yet
        var globalIds = NSMutableArray(array: self.activeDownloads.allKeys)
        for (globalid, urls) in self.activeDownloads {
            var stats = urls.allValues //get all URLs status for the issueId
        
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