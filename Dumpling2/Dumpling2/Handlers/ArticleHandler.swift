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
        
        let defaultRealmPath = "\(folder)/default.realm"
        RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
        var mainBundle = NSBundle.mainBundle()
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
    
    :param: clientkey Client API key to be used for making calls to the Magnet API
    */
    public init(clientkey: NSString) {
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir: NSString = docPaths[0] as! NSString
        
        self.defaultFolder = "/Documents"
        clientKey = clientKey as String
        issueHandler = IssueHandler(folder: docsDir, clientkey: clientKey)
        
        let defaultRealmPath = "\(docsDir)/default.realm"
        RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
    }
    
    /**
    Initializes the ArticleHandler with a custom directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
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
        issueHandler = IssueHandler(folder: folder, clientkey: clientKey)
        
        let defaultRealmPath = "\(folder)/default.realm"
        RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
    }
    
    /**
    The method uses the global id of an article, gets its content from the Magnet API and adds it to the database
    
    :brief: Get Article details from API and add to database
    
    :param: globalId The global id for the article
    */
    public func addArticleFromAPI(globalId: String) {
        let requestURL = "\(baseURL)articles/\(globalId)"
        self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: globalId)
        
        Article.createIndependentArticle(globalId, delegate: self.issueHandler)
    }
    
    /**
    The method uses an SKU/Apple id of an article, gets its content from the Magnet API and adds it to the database
    
    :param: appleId The Apple id for the article
    */
    public func addArticleWith(appleId: String) {
        let requestURL = "\(baseURL)articles/sku/\(appleId)"
        
        var networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                var response: NSDictionary = data as! NSDictionary
                var allArticles: NSArray = response.valueForKey("articles") as! NSArray
                let articleDetails: NSDictionary = allArticles.firstObject as! NSDictionary
                //Update article
                
                self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: articleDetails.objectForKey("id") as! String)
                
                Article.addArticle(articleDetails, delegate: self.issueHandler)
            }
            else if let err = error {
                println("Error: " + err.description)
            }
        }
    }
    
    /**
    The method lets you download and add all articles to the database
    
    :param: page Page number of articles to fetch. Limit is set to 20. Pagination starts at 0
    */
    public func addAllArticles(page: Int) {
        var requestURL = "\(baseURL)articles/?limit=20"
        
        if page > 0 {
            requestURL = requestURL + "&page=\(page+1)"
        }

        var networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                var response: NSDictionary = data as! NSDictionary
                var allArticles: NSArray = response.valueForKey("articles") as! NSArray
                if allArticles.count > 0 {
                    for (index, articleDict) in enumerate(allArticles) {
                        let articleId = articleDict.valueForKey("id") as! NSString
                        let requestURL = "\(baseURL)articles/\(articleId)"
                        self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: articleId)
                        
                        Article.createIndependentArticle(articleId as String, delegate: self.issueHandler)
                    }
                }
            }
            else if let err = error {
                println("Error: " + err.description)
            }
        }
    }
    
    /**
    Get paginated articles (array) from the database
    
    :param: page Page number for results (starts at 0)
    
    :param: count Number of items to be returned (specify as 0 if you need all articles)
    
    :return: Array of independent articles (without any issueIds)
    */
    public func getAllArticles(page: Int, count: Int) -> Array<Article>? {
        
        let realm = RLMRealm.defaultRealm()
        
        var array: Array<Article>? = Article.getArticlesFor("", type: nil, excludeType: nil, count: count, page: page)
        return array
    }
    
}
