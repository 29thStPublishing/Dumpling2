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

/** A model object for Assets */
public class Asset: RLMObject {
    /// Global id of an asset - this is unique for each asset
    dynamic public var globalId = ""
    /// Caption for the asset - used in the final rendered HTML
    dynamic public var caption = ""
    /// Source attribution for the asset
    dynamic public var source = ""
    /// File URL for the asset's square thumbnail
    dynamic public var squareURL = ""
    /// File URL for the original asset
    dynamic public var originalURL = ""
    /// File URL for the portrait image of the asset
    dynamic public var mainPortraitURL = ""
    /// File URL for the landscape image of the asset
    dynamic public var mainLandscapeURL = ""
    /// File URL for the icon image
    dynamic public var iconURL = ""
    /// Custom metadata for the asset
    dynamic public var metadata = ""
    /// Asset type. Defaults to a photo. Can be image, sound, video or custom
    dynamic public var type = AssetType.Image.rawValue //default to a photo
    /// Placement of an asset for an article or issue
    dynamic public var placement = 0
    /// Folder which stores the asset files - downloaded or unzipped
    dynamic public var fullFolderPath = ""
    /// Global id for the article with which the asset is associated. Can be blank if this is an issue's asset
    dynamic public var articleId = ""
    /// Issue object for the issue with which the asset is associated. Can be a default Issue object if the asset is for an independent article
    dynamic public var issue = Issue()
    /// Global id of volume the asset is associated with. Can be blank if this is an issue or article asset
    dynamic public var volumeId = ""
    
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
        
        var globalId = asset.objectForKey("id") as! String
        var results = Asset.objectsWhere("globalId = '\(globalId)'")
        var currentAsset: Asset!
        
        realm.beginWriteTransaction()
        if results.count > 0 {
            //existing asset
            currentAsset = results.firstObject() as! Asset
        }
        else {
            //Create a new asset
            currentAsset = Asset()
            currentAsset.globalId = asset.objectForKey("id") as! String
        }
        
        currentAsset.caption = asset.objectForKey("caption") as! String
        currentAsset.source = asset.objectForKey("source") as! String
        if let metadata: AnyObject = asset.objectForKey("metadata") {
            if metadata.isKindOfClass(NSDictionary) {
                currentAsset.metadata = Helper.stringFromJSON(metadata)! // metadata.JSONString()!
            }
            else {
                currentAsset.metadata = metadata as! String
            }
        }
        currentAsset.issue = issue
        currentAsset.articleId = articleId
        
        currentAsset.type = type
        
        var value = asset.objectForKey("crop_350_350") as! String
        currentAsset.squareURL = value
        
        value = asset.objectForKey("file_name") as! String
        currentAsset.originalURL = value
        
        var main_portrait = ""
        var main_landscape = ""
        var icon = ""
        
        let device = Helper.isiPhone() ? "iphone" : "ipad"
        let quality = Helper.isRetinaDevice() ? "_retinal" : ""
        
        if let cover = asset.objectForKey("cover") as? NSDictionary {
            var key = "cover_main_\(device)_portrait\(quality)"
            value = cover.objectForKey(key) as! String
            main_portrait = value
            
            key = "cover_main_\(device)_landscape\(quality)"
            if let val = cover.objectForKey(key) as? String {
                main_landscape = val
            }
            
            key = "cover_icon_iphone_portrait_retinal"
            value = cover.objectForKey(key) as! String
            icon = value
        }
        else if let cropDict = asset.objectForKey("crop") as? NSDictionary {
            var key = "main_\(device)_portrait\(quality)"
            value = cropDict.objectForKey(key) as! String
            main_portrait = value
            
            key = "main_\(device)_landscape\(quality)"
            if let val = cropDict.objectForKey(key) as? String {
                main_landscape = val
            }
        }
        
        currentAsset.mainPortraitURL = main_portrait
        currentAsset.mainLandscapeURL = main_landscape
        currentAsset.iconURL = icon
        
        currentAsset.placement = placement
        
        realm.addOrUpdateObject(currentAsset)
        realm.commitWriteTransaction()
    }
    
    //Add asset from API for volumes
    class func downloadAndCreateVolumeAsset(assetId: NSString, volume: Volume, placement: Int, delegate: AnyObject?) {
        let realm = RLMRealm.defaultRealm()
        
        let requestURL = "\(baseURL)media/\(assetId)"
        
        var networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                var response: NSDictionary = data as! NSDictionary
                var allMedia: NSArray = response.valueForKey("media") as! NSArray
                let mediaFile: NSDictionary = allMedia.firstObject as! NSDictionary
                //Update Asset now
                
                realm.beginWriteTransaction()
                
                var currentAsset = Asset()
                currentAsset.globalId = mediaFile.valueForKey("id") as! String
                currentAsset.caption = mediaFile.valueForKey("caption") as! String
                currentAsset.volumeId = volume.globalId
                
                var meta = mediaFile.objectForKey("meta") as! NSDictionary
                var dataType = meta.objectForKey("type") as! NSString
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
                    currentAsset.type = dataType as String
                }
                currentAsset.placement = placement
                
                let fileUrl = mediaFile.valueForKey("url") as! String
                
                var finalURL: String
                if volume.assetFolder.hasPrefix("/Documents") {
                    var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
                    var docsDir: NSString = docPaths[0] as! NSString
                    let finalFolder = volume.assetFolder.stringByReplacingOccurrencesOfString("/Documents", withString: docsDir as String)
                    finalURL = "\(finalFolder)/\(fileUrl.lastPathComponent)"
                }
                else {
                    finalURL = "\(volume.assetFolder)/\(fileUrl.lastPathComponent)"
                }
                
                networkManager.downloadFile(fileUrl, toPath: finalURL) {
                    (status:AnyObject?, error:NSError?) -> () in
                    if status != nil {
                        let completed = status as! NSNumber
                        if completed.boolValue {
                            //Mark asset download as done
                            if delegate != nil {
                                (delegate as! IssueHandler).updateStatusDictionary(volume.globalId, issueId:"", url: requestURL, status: 1)
                            }
                        }
                    }
                    else if let err = error {
                        println("Error: " + err.description)
                        if delegate != nil {
                            (delegate as! IssueHandler).updateStatusDictionary(volume.globalId, issueId: "", url: requestURL, status: 2)
                        }
                    }
                }
                
                currentAsset.originalURL = fileUrl.lastPathComponent
                
                if let metadata: AnyObject = mediaFile.objectForKey("customMeta") {
                    if metadata.isKindOfClass(NSDictionary) {
                        currentAsset.metadata = Helper.stringFromJSON(metadata)!
                    }
                    else {
                        currentAsset.metadata = metadata as! String
                    }
                }
                
                realm.addOrUpdateObject(currentAsset)
                realm.commitWriteTransaction()
            }
            else if let err = error {
                println("Error: " + err.description)
                if delegate != nil {
                    (delegate as! IssueHandler).updateStatusDictionary(volume.globalId, issueId: "", url: requestURL, status: 2)
                }
            }
            
        }
    }
    
    //Add asset from API - for issues or articles
    class func downloadAndCreateAsset(assetId: NSString, issue: Issue, articleId: String, placement: Int, delegate: AnyObject?) {
        let realm = RLMRealm.defaultRealm()
        
        let requestURL = "\(baseURL)media/\(assetId)"
        
        var networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                var response: NSDictionary = data as! NSDictionary
                var allMedia: NSArray = response.valueForKey("media") as! NSArray
                let mediaFile: NSDictionary = allMedia.firstObject as! NSDictionary
                //Update Asset now
                realm.beginWriteTransaction()
                
                var currentAsset = Asset()
                currentAsset.globalId = mediaFile.valueForKey("id") as! String
                currentAsset.caption = mediaFile.valueForKey("caption") as! String
                currentAsset.issue = issue
                currentAsset.articleId = articleId
                
                var meta = mediaFile.objectForKey("meta") as! NSDictionary
                var dataType = meta.objectForKey("type") as! NSString
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
                    currentAsset.type = dataType as String
                }
                currentAsset.placement = placement
                
                let fileUrl = mediaFile.valueForKey("url") as! String
                var finalURL: String
                if issue.assetFolder.hasPrefix("/Documents") {
                    var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
                    var docsDir: NSString = docPaths[0] as! NSString
                    let finalFolder = issue.assetFolder.stringByReplacingOccurrencesOfString("/Documents", withString: docsDir as String)
                    finalURL = "\(finalFolder)/\(fileUrl.lastPathComponent)"
                }
                else {
                    finalURL = "\(issue.assetFolder)/\(fileUrl.lastPathComponent)"
                }
                
                networkManager.downloadFile(fileUrl, toPath: finalURL) {
                    (status:AnyObject?, error:NSError?) -> () in
                    if status != nil {
                        let completed = status as! NSNumber
                        if completed.boolValue {
                            //Mark asset download as done
                            if delegate != nil {
                                if !issue.globalId.isEmpty {
                                    //This is an issue's asset or an article's (belonging to an issue) asset
                                    (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: requestURL, status: 1)
                                }
                                else {
                                    //This is an independent article's asset
                                    (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: requestURL, status: 1)
                                }
                            }
                        }
                    }
                    else if let err = error {
                        println("Error: " + err.description)
                        if delegate != nil {
                            if !issue.globalId.isEmpty {
                                (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: requestURL, status: 2)
                            }
                            else {
                                (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: requestURL, status: 2)
                            }
                        }
                    }
                }
                currentAsset.originalURL = fileUrl.lastPathComponent
                
                if let metadata: AnyObject = mediaFile.objectForKey("customMeta") {
                    if metadata.isKindOfClass(NSDictionary) {
                        currentAsset.metadata = Helper.stringFromJSON(metadata)!
                    }
                    else {
                        currentAsset.metadata = metadata as! String
                    }
                }
                
                realm.addOrUpdateObject(currentAsset)
                realm.commitWriteTransaction()
            }
            else if let err = error {
                println("Error: " + err.description)
                if delegate != nil {
                    if !issue.globalId.isEmpty {
                        (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: requestURL, status: 2)
                    }
                    else {
                        (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: requestURL, status: 2)
                    }
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
            let assetDetails = asset as! Asset
            let originalURL = assetDetails.getAssetPath()
            fileManager.removeItemAtPath(originalURL!, error: nil)
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
            let assetDetails = asset as! Asset
            let originalURL = assetDetails.getAssetPath()
            fileManager.removeItemAtPath(originalURL!, error: nil)
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
    
    //Delete all assets for multiple issues
    class func deleteAssetsForIssues(issues: NSArray) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issue.globalId IN %@", issues)
        var results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        //Iterate through the results and delete the files saved
        var fileManager = NSFileManager.defaultManager()
        for asset in results {
            let assetDetails = asset as! Asset
            let originalURL = assetDetails.getAssetPath()
            fileManager.removeItemAtPath(originalURL!, error: nil)
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
            let assetDetails = asset as! Asset
            let originalURL = assetDetails.getAssetPath()
            fileManager.removeItemAtPath(originalURL!, error: nil)
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
    
    // MARK: Public methods
    
    /**
    This method lets you save an Asset object back to the database in case some changes are made to it
    
    :brief: Save an Asset to the database
    */
    public func saveAsset() {
        let realm = RLMRealm.defaultRealm()
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(self)
        realm.commitWriteTransaction()
    }
    
    /**
    This method accepts the global id of an asset and deletes it from the database. The file for the asset is also deleted
    
    :brief: Delete a specific asset
    
    :param:  assetId The global id for the asset
    */
    public class func deleteAsset(assetId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = %@", assetId)
        var results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        //Iterate through the results and delete the files saved
        var fileManager = NSFileManager.defaultManager()
        for asset in results {
            let assetDetails = asset as! Asset
            let originalURL = assetDetails.getAssetPath()
            fileManager.removeItemAtPath(originalURL!, error: nil)
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
    
    /**
    This method uses the global id for an issue and/or article and returns its first image asset (i.e. placement = 1, type = image)
    
    :brief: Retrieve first asset for an issue/article

    :param:  issueId The global id for the issue
    
    :param: articleId The global id for the article
    
    :param: volumeId The global id for the volume
    
    :return: Asset object
    */
    public class func getFirstAssetFor(issueId: String, articleId: String, volumeId: String?) -> Asset? {
        let realm = RLMRealm.defaultRealm()
        
        if Helper.isNilOrEmpty(issueId) {
            if let vol = volumeId {
                let predicate = NSPredicate(format: "volumeId = %@ AND placement = 1 AND type = %@", vol, "image")
                var assets = Asset.objectsWithPredicate(predicate)
                
                if assets.count > 0 {
                    return assets.firstObject() as? Asset
                }
            }
        }
        
        if issueId == "" {
            let predicate = NSPredicate(format: "articleId = %@ AND placement = 1 AND type = %@", articleId, "image")
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
    
    /**
    This method uses the global id for an issue and/or article and returns the number of assets it has
    
    :brief: Retrieve number of assets for an issue/article
    
    :param:  issueId The global id for the issue
    
    :param: articleId The global id for the article
    
    :param: volumeId The global id of the volume
    
    :return: asset count for the issue and/or article
    */
    public class func getNumberOfAssetsFor(issueId: String, articleId: String, volumeId: String?) -> UInt {
        let realm = RLMRealm.defaultRealm()
        
        if Helper.isNilOrEmpty(issueId) {
            if let vol = volumeId {
                let predicate = NSPredicate(format: "volumeId = %@", vol)
                var assets = Asset.objectsWithPredicate(predicate)
                
                if assets.count > 0 {
                    return assets.count
                }
            }
        }
        
        let predicate = NSPredicate(format: "issue.globalId = %@ AND articleId = %@", issueId, articleId)
        var assets = Asset.objectsWithPredicate(predicate)
        
        if assets.count > 0 {
            return assets.count
        }
        
        return 0
    }
    
    /**
    This method uses the global id for an issue and/or article and the assets in an array. It takes in an optional type parameter. If specified, only assets of that type will be returned
    
    :brief: Retrieve all assets for an issue/article of a specific type
    
    :param:  issueId The global id for the issue
    
    :param: articleId The global id for the article
    
    :param: volumeId The global id for the volume
    
    :param: type The type of asset. If nil, all assets will be returned
    
    :return: array of assets following the conditions
    */
    public class func getAssetsFor(issueId: String, articleId: String, volumeId: String?, type: String?) -> Array<Asset>? {
        let realm = RLMRealm.defaultRealm()
        
        var subPredicates = NSMutableArray()
        
        if !Helper.isNilOrEmpty(volumeId) {
            if let vol = volumeId {
                let predicate = NSPredicate(format: "volumeId = %@", vol)
                subPredicates.addObject(predicate)
            }
        }
        
        let predicate = NSPredicate(format: "issue.globalId = %@ AND articleId = %@", issueId, articleId)
        subPredicates.addObject(predicate)

        if type != nil {
            var assetPredicate = NSPredicate(format: "type = %@", type!)
            subPredicates.addObject(assetPredicate)
        }
        
        let searchPredicate = NSCompoundPredicate.andPredicateWithSubpredicates(subPredicates as [AnyObject])
        var assets: RLMResults = Asset.objectsWithPredicate(searchPredicate) as RLMResults
        
        if assets.count > 0 {
            var array = Array<Asset>()
            for object in assets {
                let obj: Asset = object as! Asset
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    /**
    This method inputs the global id of an asset and returns the Asset object
    
    :brief: Retrieve a specific asset
    
    :param:  assetId The global id for the asset
    
    :return: asset object for the global id. Returns nil if the asset is not found
    */
    public class func getAsset(assetId: String) -> Asset? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = %@", assetId)
        var assets = Asset.objectsWithPredicate(predicate)
        
        if assets.count > 0 {
            return assets.firstObject() as? Asset
        }
        
        return nil
    }
    
    /**
    This method inputs the global id of an issue and/or article and returns all sound assets for it in an array
    
    :brief: Retrieve all sound files for an article/issue as a playlist/array
    
    :param:  issueId The global id for the issue
    
    :param:  articleId The global id for the article
    
    :return: Array of sound asset objects for the given issue and/or article
    */
    public class func getPlaylistFor(issueId: String, articleId: String) -> Array<Asset>? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issue.globalId = %@ AND articleId = %@ AND type = %@", issueId, articleId, "sound")
        var assets = Asset.objectsWithPredicate(predicate)
        
        if assets.count > 0 {
            var array = Array<Asset>()
            for object in assets {
                let obj: Asset = object as! Asset
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    /**
    This method returns the path of the asset file for the current object
    
    :return: Path of the asset file or nil if not found
    */
    public func getAssetPath() -> String? {
        let fileURL = self.originalURL
        if !Helper.isNilOrEmpty(fileURL) {
            var assetFolder = self.issue.assetFolder
            if Helper.isNilOrEmpty(assetFolder) {
                let realm = RLMRealm.defaultRealm()
                
                let predicate = NSPredicate(format: "globalId = %@", volumeId)
                var volumes = Volume.objectsWithPredicate(predicate)
                
                if volumes.count > 0 {
                    let volume: Volume = volumes.firstObject() as! Volume
                    assetFolder = volume.assetFolder
                }
            }
            
            if !Helper.isNilOrEmpty(assetFolder) {
                //Found the asset folder. Get the file now
                var folderPath = assetFolder
                if assetFolder.hasPrefix("/Documents") {
                    var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
                    var docsDir: NSString = docPaths[0] as! NSString
                    folderPath = assetFolder.stringByReplacingOccurrencesOfString("/Documents", withString: docsDir as String)
                }
                
                var filePath = "\(folderPath)/\(fileURL)"
                return filePath
            }
        }
        return nil
    }
}
