//
//  ArticleHandler.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 28/05/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import Foundation

/** Starter class which adds independent articles to the database */
public class ArticleHandler: NSObject {
    
    var defaultFolder: NSString!
    var issueHandler: IssueHandler!
    
    // MARK: Initializers
    
    /**
    Initializes the ArticleHandler with the given folder. This is where the database and assets will be saved. The method expects to find a key `ClientKey` in the project's Info.plist with your client key. If none is found, the method returns a nil
    
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
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath

        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        
        self.checkAndMigrateData(4)
        
        let mainBundle = NSBundle.mainBundle()
        if let key: String = mainBundle.objectForInfoDictionaryKey("ClientKey") as? String {
            clientKey = key
            issueHandler = IssueHandler(folder: folder, clientkey: clientKey)
        }
        else {
            return nil
        }
    }
    
    /**
    Initializes the ArticleHandler with the Documents directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
    - parameter clientkey: Client API key to be used for making calls to the Magnet API
    */
    public init(clientkey: NSString) {
        super.init()
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        self.defaultFolder = "/Documents"
        clientKey = clientKey as String
        
        let defaultRealmPath = "\(docsDir)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        
        self.checkAndMigrateData(4)
        
        issueHandler = IssueHandler(folder: docsDir, clientkey: clientKey)
    }
    
    /**
    Initializes the ArticleHandler with a custom directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
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
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        
        self.checkAndMigrateData(4)
        
        issueHandler = IssueHandler(folder: folder, clientkey: clientKey)
        
    }
    
    //Check and migrate Realm data if needed
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
                migration.enumerateObjects(Asset.className()) { oldObject, newObject in
                    if let issue = oldObject!["issue"] as? Issue {
                        newObject!["issue"] = issue
                    }
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
    
    /**
    The method uses the global id of an article, gets its content from the Magnet API and adds it to the database
    
    :brief: Get Article details from API and add to database
    
    - parameter globalId: The global id for the article
    */
    public func addArticleFromAPI(globalId: String) {
        let requestURL = "\(baseURL)articles/\(globalId)"

        //self.issueHandler.updateStatusDictionary(nil, issueId: globalId, url: requestURL, status: 0)
        self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: globalId)
        
        Article.createIndependentArticle(globalId, delegate: self.issueHandler)
    }
    
    /**
    The method uses the global id of an article and its issue's global id, gets its content from the Magnet API and adds it to the database
    
    - parameter globalId: The global id for the article
    
    - parameter issueId: The global id for the issue
    */
    public func addArticleFromAPI(globalId: String, issueId: String) {
        let requestURL = "\(baseURL)articles/\(globalId)"

        //self.issueHandler.updateStatusDictionary("", issueId: issueId, url: "\(baseURL)issues/\(issueId)", status: 0)
        self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: "\(baseURL)issues/\(issueId)"), forKey: issueId)

        self.issueHandler.updateStatusDictionary("", issueId: issueId, url: requestURL, status: 0)
        if let issue = Issue.getIssue(issueId) {
            Article.createArticleForId(globalId, issue: issue, placement: 0, delegate: self.issueHandler)
        }
        self.issueHandler.updateStatusDictionary("", issueId: issueId, url: "\(baseURL)issues/\(issueId)", status: 1)
    }
    
    /**
    The method uses an SKU/Apple id of an article, gets its content from the Magnet API and adds it to the database
    
    - parameter appleId: The Apple id for the article
    */
    public func addArticleWith(appleId: String) {
        let requestURL = "\(baseURL)articles/sku/\(appleId)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                let articleDetails: NSDictionary = allArticles.firstObject as! NSDictionary
                //Update article
                
                //self.issueHandler.updateStatusDictionary(nil, issueId: articleDetails.objectForKey("id") as! String, url: requestURL, status: 0)
                self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: articleDetails.objectForKey("id") as! String)
                
                Article.addArticle(articleDetails, delegate: self.issueHandler)
            }
            else if let err = error {
                print("Error: " + err.description)
            }
        }
    }
    
    /**
    This method accepts a property name, its corresponding values and retrieves a paginated list of articles from the API which match this. If either of property or value are blank, the normal addAllArticles method will be invoked
    
    - parameter  property: The property by matching which articles need to be retrieved
    
    - parameter  value: The value of the property
    
    - parameter page: Page number of articles to fetch. Limit is set to 20. Pagination starts at 0
    
    - parameter limit: Parameter accepting the number of records to fetch at a time. If this is set to 0, we will fetch 20 records by default
    */
    public func addArticlesFor(property: String, value: String, page: Int, limit: Int) {
        if Helper.isNilOrEmpty(property) || Helper.isNilOrEmpty(value) {
            self.addAllArticles(page, limit: limit)
            return
        }
        
        //let encodedVal = value.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let encodedVal = value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        var requestURL = "\(baseURL)articles/\(property)/" + encodedVal! + "?limit="
        
        if limit > 0 {
            requestURL += "\(limit)"
        }
        else {
            requestURL += "20"
        }
        
        if page > 0 {
            requestURL = requestURL + "&page=\(page+1)"
        }
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                if allArticles.count > 0 {
                    for (_, articleDict) in allArticles.enumerate() {
                        let articleId = articleDict.valueForKey("id") as! NSString
                        let requestURL = "\(baseURL)articles/\(articleId)"

                        //self.issueHandler.updateStatusDictionary(nil, issueId: articleId as String, url: requestURL, status: 0)
                        self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: articleId)
                        
                        Article.createIndependentArticle(articleId as String, delegate: self.issueHandler)
                    }
                }
            }
            else if let err = error {
                print("Error: " + err.description)
            }
        }
    }
    
    /**
    The method lets you download and add all articles to the database
    
    - parameter page: Page number of articles to fetch. Limit is set to 20. Pagination starts at 0
    
    - parameter limit: Parameter accepting the number of records to fetch at a time. If this is set to 0, we will fetch 20 records by default
    */
    public func addAllArticles(page: Int, limit: Int) {
        var requestURL = "\(baseURL)articles?limit="
        
        if limit > 0 {
            requestURL += "\(limit)"
        }
        else {
            requestURL += "20"
        }
        
        if page > 0 {
            requestURL = requestURL + "&page=\(page+1)"
        }

        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                if allArticles.count > 0 {
                    for (_, articleDict) in allArticles.enumerate() {
                        let articleId = articleDict.valueForKey("id") as! NSString
                        let requestURL = "\(baseURL)articles/\(articleId)"
                        
                        //self.issueHandler.updateStatusDictionary(nil, issueId: articleId as String, url: requestURL, status: 0)
                        self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: articleId)
                        
                        Article.createIndependentArticle(articleId as String, delegate: self.issueHandler)
                    }
                }
            }
            else if let err = error {
                print("Error: " + err.description)
            }
        }
    }
    
    /**
    The method lets you download and add all published articles to the database
    
    - parameter page: Page number of articles to fetch. Limit is set to 20. Pagination starts at 0
    
    - parameter limit: Parameter accepting the number of records to fetch at a time. If this is set to 0, we will fetch 20 records by default
    */
    public func addAllPublishedArticles(page: Int, limit: Int) {
        var requestURL = "\(baseURL)articles/published?limit="
        
        if limit > 0 {
            requestURL += "\(limit)"
        }
        else {
            requestURL += "20"
        }
        
        if page > 0 {
            requestURL = requestURL + "&page=\(page+1)"
        }
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                if allArticles.count > 0 {
                    for (_, articleDict) in allArticles.enumerate() {
                        let articleId = articleDict.valueForKey("id") as! NSString
                        let requestURL = "\(baseURL)articles/\(articleId)"
                        
                        //self.issueHandler.updateStatusDictionary(nil, issueId: articleId as String, url: requestURL, status: 0)
                        self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: articleId)
                        
                        Article.createIndependentArticle(articleId as String, delegate: self.issueHandler)
                    }
                }
            }
            else if let err = error {
                print("Error: " + err.description)
            }
        }
    }
    
    /**
    Get paginated articles (array) from the database
    
    - parameter page: Page number for results (starts at 0)
    
    - parameter count: Number of items to be returned (specify as 0 if you need all articles)
    
    :return: Array of independent articles (without any issueIds)
    */
    public func getAllArticles(page: Int, count: Int) -> Array<Article>? {
        
        _ = RLMRealm.defaultRealm()
        
        let array: Array<Article>? = Article.getArticlesFor("", type: nil, excludeType: nil, count: count, page: page)
        return array
    }
    
}
