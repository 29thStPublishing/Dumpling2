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
        //RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
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
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        self.defaultFolder = "/Documents"
        clientKey = clientKey as String
        issueHandler = IssueHandler(folder: docsDir, clientkey: clientKey)
        
        let defaultRealmPath = "\(docsDir)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        //RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
    }
    
    /**
    Initializes the ArticleHandler with a custom directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
    - parameter folder: The folder where the database and downloaded assets should be saved
    
    - parameter clientkey: Client API key to be used for making calls to the Magnet API
    */
    public init(folder: NSString, clientkey: NSString) {
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
        issueHandler = IssueHandler(folder: folder, clientkey: clientKey)
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        //RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
    }
    
    /**
    The method uses the global id of an article, gets its content from the Magnet API and adds it to the database
    
    :brief: Get Article details from API and add to database
    
    - parameter globalId: The global id for the article
    */
    public func addArticleFromAPI(globalId: String) {
        let requestURL = "\(baseURL)articles/\(globalId)"
        self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: globalId)
        
        Article.createIndependentArticle(globalId, delegate: self.issueHandler)
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
        
        var requestURL = "\(baseURL)articles/\(property)/\(value)?limit="
        
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
