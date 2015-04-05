//
//  Asset.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
//import Realm

enum AssetType: String {
    case Image = "image"
    case Sound = "sound"
    case Video = "video"
}
//Asset object
public class Asset: RLMObject {
    dynamic public var globalId = ""
    dynamic public var caption = ""
    dynamic public var source = ""
    dynamic public var squareURL = ""
    dynamic public var originalURL = ""
    dynamic public var mainPortraitURL = ""
    dynamic public var mainLandscapeURL = ""
    dynamic public var iconURL = ""
    dynamic public var metadata = ""
    dynamic public var type = AssetType.Image.rawValue //default to a photo
    dynamic public var placement = 0
    dynamic public var fullFolderPath = ""
    dynamic public var articleId = "" //globalId of associated article
    dynamic public var issue = Issue() //an asset can belong to an article or an issue
    
    override public class func primaryKey() -> String {
        return "globalId"
    }
    
    //Add asset
    class func createAsset(asset: NSDictionary, issue: Issue, articleId: String, placement: Int) {
        createAsset(asset, issue: issue, articleId: articleId, sound: false, placement: placement)
    }
    
    //Add any asset (sound/image)
    class func createAsset(asset: NSDictionary, issue: Issue, articleId: String, sound: Bool, placement: Int) {
        var type = AssetType.Image.rawValue
        if sound {
            type = AssetType.Sound.rawValue
        }
        createAsset(asset, issue: issue, articleId: articleId, type: type, placement: placement)
    }
    
    //Add any asset (sound/image/anything else)
    class func createAsset(asset: NSDictionary, issue: Issue, articleId: String, type: String, placement: Int) {
        let realm = RLMRealm.defaultRealm()
        
        var globalId = asset.objectForKey("id") as String
        var results = Asset.objectsWhere("globalId = '\(globalId)'")
        var currentAsset: Asset!
        
        realm.beginWriteTransaction()
        if results.count > 0 {
            //existing asset
            currentAsset = results.firstObject() as Asset
        }
        else {
            //Create a new asset
            currentAsset = Asset()
            currentAsset.globalId = asset.objectForKey("id") as String
        }
        
        currentAsset.caption = asset.objectForKey("caption") as String
        currentAsset.source = asset.objectForKey("source") as String
        if let metadata: AnyObject = asset.objectForKey("metadata") {
            if metadata.isKindOfClass(NSDictionary) {
                currentAsset.metadata = Helper.stringFromJSON(metadata)! // metadata.JSONString()!
            }
            else {
                currentAsset.metadata = metadata as String
            }
        }
        currentAsset.issue = issue
        currentAsset.articleId = articleId
        
        currentAsset.type = type
        
        var value = asset.objectForKey("crop_350_350") as String
        currentAsset.squareURL = "\(issue.assetFolder)/\(value)"
        
        value = asset.objectForKey("file_name") as String
        currentAsset.originalURL = "\(issue.assetFolder)/\(value)"
        
        var main_portrait = ""
        var main_landscape = ""
        var icon = ""
        
        let device = Helper.isiPhone() ? "iphone" : "ipad"
        let quality = Helper.isRetinaDevice() ? "_retinal" : ""
        
        if let cover = asset.objectForKey("cover") as? NSDictionary {
            var key = "cover_main_\(device)_portrait\(quality)"
            value = cover.objectForKey(key) as String
            main_portrait = "\(issue.assetFolder)/\(value)"
            
            key = "cover_main_\(device)_landscape\(quality)"
            if let val = cover.objectForKey(key) as? String {
                main_landscape = "\(issue.assetFolder)/\(val)"
            }
            
            key = "cover_icon_iphone_portrait_retinal"
            value = cover.objectForKey(key) as String
            icon = "\(issue.assetFolder)/\(value)"
        }
        else if let cropDict = asset.objectForKey("crop") as? NSDictionary {
            var key = "main_\(device)_portrait\(quality)"
            value = cropDict.objectForKey(key) as String
            main_portrait = "\(issue.assetFolder)/\(value)"
            
            key = "main_\(device)_landscape\(quality)"
            if let val = cropDict.objectForKey(key) as? String {
                main_landscape = "\(issue.assetFolder)/\(val)"
            }
        }
        
        currentAsset.mainPortraitURL = main_portrait
        currentAsset.mainLandscapeURL = main_landscape
        currentAsset.iconURL = icon
        
        currentAsset.placement = placement
        
        realm.addOrUpdateObject(currentAsset)
        realm.commitWriteTransaction()
    }
    
    //Add asset from API
    class func downloadAndCreateAsset(assetId: NSString, issue: Issue, articleId: String, placement: Int, delegate: AnyObject?) {
        let realm = RLMRealm.defaultRealm()
        
        let requestURL = "\(baseURL)media/\(assetId)"
        
        var networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                var response: NSDictionary = data as NSDictionary
                var allMedia: NSArray = response.valueForKey("media") as NSArray
                let mediaFile: NSDictionary = allMedia.firstObject as NSDictionary
                //Update Asset now
                
                realm.beginWriteTransaction()
                
                var currentAsset = Asset()
                currentAsset.globalId = mediaFile.valueForKey("id") as String
                currentAsset.caption = mediaFile.valueForKey("title") as String
                currentAsset.issue = issue
                currentAsset.articleId = articleId
                
                var meta = mediaFile.objectForKey("meta") as NSDictionary
                var dataType = meta.objectForKey("type") as NSString
                if dataType.isEqualToString("image") {
                    currentAsset.type = AssetType.Image.rawValue
                }
                else if dataType.isEqualToString("audio") {
                    currentAsset.type = AssetType.Sound.rawValue
                }
                else if dataType.isEqualToString("video") {
                    currentAsset.type = AssetType.Video.rawValue
                }
                else {
                    currentAsset.type = dataType
                }
                currentAsset.placement = placement
                
                let fileUrl = mediaFile.valueForKey("url") as String
                let finalURL = "\(issue.assetFolder)/\(fileUrl.lastPathComponent)"
                
                networkManager.downloadFile(fileUrl, toPath: finalURL) {
                    (status:AnyObject?, error:NSError?) -> () in
                    if status != nil {
                        let completed = status as NSNumber
                        if completed.boolValue {
                            //Mark asset download as done
                            if delegate != nil {
                                (delegate as IssueHandler).updateStatusDictionary(issue.globalId, url: requestURL, status: 1)
                            }
                        }
                    }
                    else if let err = error {
                        println("Error: " + err.description)
                        if delegate != nil {
                            (delegate as IssueHandler).updateStatusDictionary(issue.globalId, url: requestURL, status: 2)
                        }
                    }
                }
                //currentAsset.saveFileFromURL(fileUrl, toFolder: "\(issue.assetFolder)/")
                currentAsset.originalURL = "\(issue.assetFolder)/\(fileUrl.lastPathComponent)"
                
                if let metadata: AnyObject = mediaFile.objectForKey("customMeta") {
                    if metadata.isKindOfClass(NSDictionary) {
                        currentAsset.metadata = Helper.stringFromJSON(metadata)!
                    }
                    else {
                        currentAsset.metadata = metadata as String
                    }
                }
                
                realm.addOrUpdateObject(currentAsset)
                realm.commitWriteTransaction()
            }
            else if let err = error {
                println("Error: " + err.description)
                if delegate != nil {
                    (delegate as IssueHandler).updateStatusDictionary(issue.globalId, url: requestURL, status: 2)
                }
            }
            
        }
    }
    
    
    //Saves a file from a remote URL - not used any more - Use LRNetworkManager
    /*func saveFileFromURL(path: String, toFolder: String) {
        var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        var man = AFURLSessionManager(sessionConfiguration: configuration)
        var url = NSURL(string: path)
        var request = NSURLRequest(URL:url!)
        
        var downloadTask = man.downloadTaskWithRequest(request, progress: nil,
            destination:{(targetPath:NSURL!,response:NSURLResponse!) -> NSURL! in
                
                var url:NSURL! = NSURL(fileURLWithPath: toFolder)
                var urlPath = url.URLByAppendingPathComponent(response.suggestedFilename as String!)
                return urlPath
            },
            completionHandler:{(response:NSURLResponse!,filePath:NSURL!,error:NSError!)  in
                println(response.suggestedFilename)
        })
        
        downloadTask.resume();
    }*/
    
    //Delete all assets for a single article
    class func deleteAssetsFor(articleId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "articleId = %@", articleId)
        var results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        //Iterate through the results and delete the files saved
        var fileManager = NSFileManager.defaultManager()
        for asset in results {
            let assetDetails = asset as Asset
            let originalURL = assetDetails.originalURL
            fileManager.removeItemAtPath(originalURL, error: nil)
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
    
    
    //Delete all assets for multiple articles
    class func deleteAssetsForArticles(articles: NSArray) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "articleId IN %@", articles)
        var results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        //Iterate through the results and delete the files saved
        var fileManager = NSFileManager.defaultManager()
        for asset in results {
            let assetDetails = asset as Asset
            let originalURL = assetDetails.originalURL
            fileManager.removeItemAtPath(originalURL, error: nil)
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
    
    //Delete all assets for a single issue
    class func deleteAssetsForIssue(globalId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issue.globalId = %@", globalId)
        var results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        //Iterate through the results and delete the files saved
        var fileManager = NSFileManager.defaultManager()
        for asset in results {
            let assetDetails = asset as Asset
            let originalURL = assetDetails.originalURL
            fileManager.removeItemAtPath(originalURL, error: nil)
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
    
    // MARK: Public methods
    
    //Save an Asset to the database
    public func saveAsset() {
        let realm = RLMRealm.defaultRealm()
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(self)
        realm.commitWriteTransaction()
    }
    
    //Delete a specific asset
    public class func deleteAsset(assetId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = %@", assetId)
        var results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        //Iterate through the results and delete the files saved
        var fileManager = NSFileManager.defaultManager()
        for asset in results {
            let assetDetails = asset as Asset
            let originalURL = assetDetails.originalURL
            fileManager.removeItemAtPath(originalURL, error: nil)
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
    
    //Retrieve first asset for an issue/article
    //articleId will be blank if this is an issue's asset
    public class func getFirstAssetFor(issueId: String, articleId: String) -> Asset? {
        let realm = RLMRealm.defaultRealm()
        
        if issueId == "" {
            let predicate = NSPredicate(format: "articleId = %@ AND placement = 1 AND type = %@", issueId, articleId, "image")
            var assets = Asset.objectsWithPredicate(predicate)
            
            if assets.count > 0 {
                return assets.firstObject() as? Asset
            }
        }
        else {
            let predicate = NSPredicate(format: "issue.globalId = %@ AND articleId = %@ AND placement = 1 AND type = %@", issueId, articleId, "image")
            var assets = Asset.objectsWithPredicate(predicate)
        
            if assets.count > 0 {
                return assets.firstObject() as? Asset
            }
        }
        
        return nil
    }
    
    //Retrieve number of assets for an issue/article
    public class func getNumberOfAssetsFor(issueId: String, articleId: String) -> UInt {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issue.globalId = %@ AND articleId = %@", issueId, articleId)
        var assets = Asset.objectsWithPredicate(predicate)
        
        if assets.count > 0 {
            return assets.count
        }
        
        return 0
    }
    
    //Retrieve all assets for an issue/article (of a specific type: optional)
    public class func getAssetsFor(issueId: String, articleId: String, type: String?) -> Array<Asset>? {
        let realm = RLMRealm.defaultRealm()
        
        var subPredicates = NSMutableArray()
        
        let predicate = NSPredicate(format: "issue.globalId = %@ AND articleId = %@", issueId, articleId)
        subPredicates.addObject(predicate!)

        if type != nil {
            var assetPredicate = NSPredicate(format: "type = %@", type!)
            subPredicates.addObject(assetPredicate!)
        }
        
        let searchPredicate = NSCompoundPredicate.andPredicateWithSubpredicates(subPredicates)
        var assets: RLMResults = Asset.objectsWithPredicate(searchPredicate) as RLMResults
        
        if assets.count > 0 {
            var array = Array<Asset>()
            for object in assets {
                let obj: Asset = object as Asset
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    //Retrieve a specific asset
    public class func getAsset(assetId: String) -> Asset? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = %@", assetId)
        var assets = Asset.objectsWithPredicate(predicate)
        
        if assets.count > 0 {
            return assets.firstObject() as? Asset
        }
        
        return nil
    }
    
    //Retrieve all sound files for an article/issue as a playlist/array
    public class func getPlaylistFor(issueId: String, articleId: String) -> Array<Asset>? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issue.globalId = %@ AND articleId = %@ AND type = %@", issueId, articleId, "sound")
        var assets = Asset.objectsWithPredicate(predicate)
        
        if assets.count > 0 {
            var array = Array<Asset>()
            for object in assets {
                let obj: Asset = object as Asset
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
}
