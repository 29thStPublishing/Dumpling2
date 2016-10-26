//
//  Asset.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
import ImageIO
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
    
    /// Image file URLs
    dynamic var cdnUrl = ""
    dynamic var imgUrl = ""
    dynamic var cdnThumbUrl = ""
    dynamic var imgThumbUrl = ""
    
    override public class func primaryKey() -> String {
        return "globalId"
    }
    
    //Required for backward compatibility when upgrading to V 0.96.2
    override public class func requiredProperties() -> Array<String> {
        return ["globalId", "caption", "source", "squareURL", "originalURL", "mainPortraitURL", "mainLandscapeURL", "iconURL", "metadata", "type", "placement", "fullFolderPath", "articleId", "volumeId"]
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
        
        let globalId = asset.objectForKey("id") as! String
        let results = Asset.objectsWhere("globalId = '\(globalId)'")
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
        do {
            try realm.commitWriteTransaction()
            Relation.createRelation(issue.globalId, articleId: articleId, assetId: currentAsset.globalId, placement: placement)
        } catch let error {
            NSLog("Error creating asset: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    //Add asset from API for volumes
    class func downloadAndCreateVolumeAsset(assetId: NSString, volume: Volume, placement: Int, delegate: AnyObject?) {
        lLog("Volume asset \(assetId)")
        let realm = RLMRealm.defaultRealm()
        
        let requestURL = "\(baseURL)media/\(assetId)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allMedia: NSArray = response.valueForKey("media") as! NSArray
                let mediaFile: NSDictionary = allMedia.firstObject as! NSDictionary
                //Update Asset now
                
                let meta = mediaFile.objectForKey("meta") as! NSDictionary
                
                //var toDownload = true //Define whether the image should be downloaded or not
                if let existingAsset = Asset.getAsset(mediaFile.valueForKey("id") as! String) {
                    //Asset exists already
                    if let updateDate: String = existingAsset.getValue("updateDate") as? String {
                        //Get date from this string
                        let lastUpdatedDate = Helper.publishedDateFromISO(updateDate)
                        var newUpdatedDate = NSDate()
                        if let updated: Dictionary<String, AnyObject> = meta.objectForKey("updated") as? Dictionary {
                            if let dt: String = updated["date"] as? String {
                                newUpdatedDate = Helper.publishedDateFromISO(dt)
                            }
                        }
                        //Compare the two dates - if newUpdated <= lastUpdated, don't download
                        if newUpdatedDate.compare(lastUpdatedDate) != NSComparisonResult.OrderedDescending {
                            //toDownload = false //Don't download - this file is up-to-date (if present)
                            //If cdnUrl and imgUrl are blank, save the asset again so we get them
                            if !existingAsset.cdnUrl.isEmpty || !existingAsset.imgUrl.isEmpty {
                                if delegate != nil {
                                    //No change - not downloaded
                                    if existingAsset.assetImageExists() {
                                        (delegate as! IssueHandler).updateStatusDictionary(volume.globalId, issueId:"", url: requestURL, status: 3)
                                    }
                                    else {
                                        (delegate as! IssueHandler).updateStatusDictionary(volume.globalId, issueId:"", url: requestURL, status: 1)
                                    }
                                }
                                return
                            }
                        }
                    }
                }
                
                realm.beginWriteTransaction()
                
                let currentAsset = Asset()
                currentAsset.globalId = mediaFile.valueForKey("id") as! String
                currentAsset.caption = mediaFile.valueForKey("caption") as! String
                currentAsset.volumeId = volume.globalId
                
                let dataType = meta.objectForKey("type") as! NSString
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
                
                //var isCdn = true
                var fileUrl = mediaFile.valueForKey("cdnUrl") as! String
                currentAsset.cdnUrl = fileUrl
                if Helper.isNilOrEmpty(fileUrl) {
                    fileUrl = mediaFile.valueForKey("url") as! String
                    currentAsset.imgUrl = fileUrl
                    //isCdn = false
                }
                
                currentAsset.originalURL = "original-\((fileUrl as NSString).lastPathComponent)"
                
                //var isCdnThumb = true
                var thumbUrl = mediaFile.valueForKey("cdnUrlThumb") as! String
                currentAsset.cdnThumbUrl = thumbUrl
                if Helper.isNilOrEmpty(thumbUrl) {
                    thumbUrl = mediaFile.valueForKey("urlThumb") as! String
                    currentAsset.imgThumbUrl = thumbUrl
                    //isCdnThumb = false
                }
                
                currentAsset.squareURL = "thumb-\((thumbUrl as NSString).lastPathComponent)"
                
                if let metadata: AnyObject = mediaFile.objectForKey("customMeta") {
                    if metadata.isKindOfClass(NSDictionary) {
                        let metadataDict = NSMutableDictionary(dictionary: metadata as! NSDictionary)
                        if let height = meta.objectForKey("height") {
                            metadataDict.setObject(height, forKey: "height")
                        }
                        if let width = meta.objectForKey("width") {
                            metadataDict.setObject(width, forKey: "width")
                        }
                        if let updated: Dictionary<String, AnyObject> = meta.objectForKey("updated") as? Dictionary {
                            if let updateDate: String = updated["date"] as? String {
                                metadataDict.setObject(updateDate, forKey: "updateDate")
                            }
                        }
                        currentAsset.metadata = Helper.stringFromJSON(metadataDict)!
                    }
                    else {
                        currentAsset.metadata = metadata as! String
                    }
                }
                
                realm.addOrUpdateObject(currentAsset)
                do {
                    try realm.commitWriteTransaction()
                } catch let error {
                    NSLog("Error writing volume asset: \(error)")
                }
                //AFTER NUKE
                if delegate != nil {
                    //No change - not downloaded
                    (delegate as! IssueHandler).updateStatusDictionary(volume.globalId, issueId:"", url: requestURL, status: 1)
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                if delegate != nil {
                    (delegate as! IssueHandler).updateStatusDictionary(volume.globalId, issueId: "", url: requestURL, status: 2)
                }
            }
            
        }
    }
    
    //Add asset from API - for issues or articles
    class func downloadAndCreateAsset(assetId: NSString, issue: Issue, articleId: String, placement: Int, delegate: AnyObject?) {
        lLog("Asset \(assetId)")
        let realm = RLMRealm.defaultRealm()
        
        let requestURL = "\(baseURL)media/\(assetId)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allMedia: NSArray = response.valueForKey("media") as! NSArray
                let mediaFile: NSDictionary = allMedia.firstObject as! NSDictionary
                
                let meta = mediaFile.objectForKey("meta") as! NSDictionary
                
                //var toDownload = true //Define whether the image should be downloaded or not
                if let existingAsset = Asset.getAsset(mediaFile.objectForKey("id") as! String) {
                    //Asset exists already
                    if let updateDate: String = existingAsset.getValue("updateDate") as? String {
                        //Get date from this string
                        let lastUpdatedDate = Helper.publishedDateFromISO(updateDate)
                        var newUpdatedDate = NSDate()
                        if let updated: Dictionary<String, AnyObject> = meta.objectForKey("updated") as? Dictionary {
                            if let dt: String = updated["date"] as? String {
                                newUpdatedDate = Helper.publishedDateFromISO(dt)
                            }
                        }
                        //Compare the two dates - if newUpdated <= lastUpdated, don't download
                        if newUpdatedDate.compare(lastUpdatedDate) != NSComparisonResult.OrderedDescending {
                            //toDownload = false //Don't download
                            //If cdnUrl and imgUrl are blank, save the asset again so we get them
                            if !existingAsset.cdnUrl.isEmpty || !existingAsset.imgUrl.isEmpty {
                                if delegate != nil {
                                    var status = 1
                                    if existingAsset.assetImageExists() {
                                        status = 3
                                    }
                                    if !issue.globalId.isEmpty {
                                        //This is an issue's asset or an article's (belonging to an issue) asset
                                        //No change - not downloaded
                                        (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: requestURL, status: status)
                                    }
                                    else {
                                        //This is an independent article's asset
                                        //No change - not downloaded
                                        (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: requestURL, status: status)
                                    }
                                }
                                return
                            }
                        }
                    }
                }
                
                //Update Asset now
                realm.beginWriteTransaction()
                
                let currentAsset = Asset()
                currentAsset.globalId = mediaFile.valueForKey("id") as! String
                currentAsset.caption = mediaFile.valueForKey("caption") as! String
                currentAsset.issue = issue
                currentAsset.articleId = articleId
                
                let dataType = meta.objectForKey("type") as! NSString
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
                
                //var isCdn = true
                var fileUrl = mediaFile.valueForKey("cdnUrl") as! String
                currentAsset.cdnUrl = fileUrl
                if Helper.isNilOrEmpty(fileUrl) {
                    fileUrl = mediaFile.valueForKey("url") as! String
                    currentAsset.imgUrl = fileUrl
                    //isCdn = false
                }
                
                currentAsset.originalURL = "original-\((fileUrl as NSString).lastPathComponent)"
                
                //var isCdnThumb = true
                var thumbUrl = mediaFile.valueForKey("cdnUrlThumb") as! String
                currentAsset.cdnThumbUrl = thumbUrl
                if Helper.isNilOrEmpty(thumbUrl) {
                    thumbUrl = mediaFile.valueForKey("urlThumb") as! String
                    currentAsset.imgThumbUrl = thumbUrl
                    //isCdnThumb = false
                }
                
                currentAsset.squareURL = "thumb-\((thumbUrl as NSString).lastPathComponent)"
                
                if let metadata: AnyObject = mediaFile.objectForKey("customMeta") {
                    if metadata.isKindOfClass(NSDictionary) {
                        let metadataDict = NSMutableDictionary(dictionary: metadata as! NSDictionary)
                        if let height = meta.objectForKey("height") {
                            metadataDict.setObject(height, forKey: "height")
                        }
                        if let width = meta.objectForKey("width") {
                            metadataDict.setObject(width, forKey: "width")
                        }
                        if let updated: Dictionary<String, AnyObject> = meta.objectForKey("updated") as? Dictionary {
                            if let updateDate: String = updated["date"] as? String {
                                metadataDict.setObject(updateDate, forKey: "updateDate")
                            }
                        }
                        currentAsset.metadata = Helper.stringFromJSON(metadataDict)!
                    }
                    else {
                        currentAsset.metadata = metadata as! String
                    }
                }
                
                realm.addOrUpdateObject(currentAsset)
                do {
                    try realm.commitWriteTransaction()
                } catch let error {
                    NSLog("Error creating asset: \(error)")
                }
                //AFTER NUKE
                if delegate != nil {
                    if !issue.globalId.isEmpty {
                        //This is an issue's asset or an article's (belonging to an issue) asset
                        //No change - not downloaded
                        (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: requestURL, status: 1)
                    }
                    else {
                        //This is an independent article's asset
                        //No change - not downloaded
                        (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: requestURL, status: 1)
                    }
                }
            }
            else if let err = error {
                print("Error: " + err.description)
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
    
    //Add list of assets from API - for issues or articles
    class func downloadAndCreateAssetsForIds(assetIds: String, issue: Issue?, articleId: String, delegate: AnyObject?) {
        lLog("downloadAndCreateAssetsFrom \(assetIds)")
        let realm = RLMRealm.defaultRealm()
        
        let requestURL = "\(baseURL)media/\(assetIds)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allMedia: NSArray = response.valueForKey("media") as! NSArray
                
                for (index, mediaFile) in allMedia.enumerate() {
                    
                    let meta = mediaFile.objectForKey("meta") as! NSDictionary
                    let assetId = mediaFile.objectForKey("id") as! String
                    
                    //NUKE
                    if let existingAsset = Asset.getAsset(assetId) {
                        //Asset exists already
                        if let updateDate: String = existingAsset.getValue("updateDate") as? String {
                            //Get date from this string
                            let lastUpdatedDate = Helper.publishedDateFromISO(updateDate)
                            var newUpdatedDate = NSDate()
                            if let updated: Dictionary<String, AnyObject> = meta.objectForKey("updated") as? Dictionary {
                                if let dt: String = updated["date"] as? String {
                                    newUpdatedDate = Helper.publishedDateFromISO(dt)
                                }
                            }
                            //Compare the two dates - if newUpdated <= lastUpdated, don't download
                            if newUpdatedDate.compare(lastUpdatedDate) != NSComparisonResult.OrderedDescending {
                                //Check if the image exists or not
                                //toDownload = false //Don't download
                                //If cdnUrl and imgUrl are blank, save the asset again so we get them
                                if !existingAsset.cdnUrl.isEmpty || !existingAsset.imgUrl.isEmpty {
                                    if delegate != nil {
                                        var status = 1
                                        if existingAsset.assetImageExists() {
                                            status = 3
                                        }
                                        let url = "\(baseURL)media/\(assetId)"
                                        if let issue = issue {
                                            if !issue.globalId.isEmpty {
                                                //This is an issue's asset or an article's (belonging to an issue) asset
                                                //No change - not downloaded
                                                (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: url , status: status)
                                            }
                                            else {
                                                //This is an independent article's asset
                                                //No change - not downloaded
                                                (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: url, status: status)
                                            }
                                        }
                                        else {
                                            //No change - not downloaded
                                            (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: url, status: status)
                                        }
                                    }
                                    return
                                }
                            }
                        }
                    }
                    
                    //Update Asset now
                    realm.beginWriteTransaction()
                    
                    let currentAsset = Asset()
                    currentAsset.globalId = mediaFile.valueForKey("id") as! String
                    currentAsset.caption = mediaFile.valueForKey("caption") as! String
                    if let issue = issue {
                        currentAsset.issue = issue
                    }
                    currentAsset.articleId = articleId
                    
                    let dataType = meta.objectForKey("type") as! NSString
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
                    currentAsset.placement = index + 1
                    
                    //var isCdn = true
                    var fileUrl = mediaFile.valueForKey("cdnUrl") as! String
                    currentAsset.cdnUrl = fileUrl
                    if Helper.isNilOrEmpty(fileUrl) {
                        fileUrl = mediaFile.valueForKey("url") as! String
                        currentAsset.imgUrl = fileUrl
                        //isCdn = false
                    }
                    
                    currentAsset.originalURL = "original-\((fileUrl as NSString).lastPathComponent)"
                    
                    //var isCdnThumb = true
                    var thumbUrl = mediaFile.valueForKey("cdnUrlThumb") as! String
                    currentAsset.cdnThumbUrl = thumbUrl
                    if Helper.isNilOrEmpty(thumbUrl) {
                        thumbUrl = mediaFile.valueForKey("urlThumb") as! String
                        currentAsset.imgThumbUrl = thumbUrl
                        //isCdnThumb = false
                    }
                    
                    currentAsset.squareURL = "thumb-\((thumbUrl as NSString).lastPathComponent)"
                    
                    if let metadata: AnyObject = mediaFile.objectForKey("customMeta") {
                        if metadata.isKindOfClass(NSDictionary) {
                            let metadataDict = NSMutableDictionary(dictionary: metadata as! NSDictionary)
                            if let height = meta.objectForKey("height") {
                                metadataDict.setObject(height, forKey: "height")
                            }
                            if let width = meta.objectForKey("width") {
                                metadataDict.setObject(width, forKey: "width")
                            }
                            if let updated: Dictionary<String, AnyObject> = meta.objectForKey("updated") as? Dictionary {
                                if let updateDate: String = updated["date"] as? String {
                                    metadataDict.setObject(updateDate, forKey: "updateDate")
                                }
                            }
                            currentAsset.metadata = Helper.stringFromJSON(metadataDict)!
                        }
                        else {
                            currentAsset.metadata = metadata as! String
                        }
                    }
                    
                    realm.addOrUpdateObject(currentAsset)
                    do {
                        try realm.commitWriteTransaction()
                    } catch let error {
                        NSLog("Error saving issue: \(error)")
                    }
                    //AFTER NUKE
                    if delegate != nil {
                        if let issue = issue {
                            if !issue.globalId.isEmpty {
                                //This is an issue's asset or an article's (belonging to an issue) asset
                                //No change - not downloaded
                                (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 1)
                            }
                            else {
                                //This is an independent article's asset
                                //No change - not downloaded
                                (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 1)
                            }
                        }
                        else {
                            //No change - not downloaded
                            (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 1)
                        }
                    }
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                if delegate != nil {
                    var articleGlobalId = articleId
                    if let issue = issue {
                        if !issue.globalId.isEmpty {
                            articleGlobalId = issue.globalId
                        }
                    }
                    let arr = assetIds.characters.split(",").map { String($0) }
                    for assetId in arr {
                        (delegate as! IssueHandler).updateStatusDictionary("", issueId: articleGlobalId, url: "\(baseURL)media/\(assetId)", status: 2)
                    }
                }
            }
            
        }
    }
    
    //Delete all assets for a single article
    class func deleteAssetsFor(articleId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "articleId = %@", articleId)
        let results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        //Iterate through the results and delete the files saved
        let fileManager = NSFileManager.defaultManager()
        for asset in results {
            let assetDetails = asset as! Asset
            if let originalURL = assetDetails.getAssetPath() {
                do {
                    try fileManager.removeItemAtPath(originalURL)
                    let thumb = originalURL.stringByReplacingOccurrencesOfString(assetDetails.originalURL, withString: assetDetails.squareURL) as String
                    try fileManager.removeItemAtPath(thumb)
                } catch _ {
                }
            }
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error deleting asset: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    
    //Delete all assets for multiple articles
    class func deleteAssetsForArticles(articles: NSArray) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "articleId IN %@", articles)
        let results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        //Iterate through the results and delete the files saved
        let fileManager = NSFileManager.defaultManager()
        for asset in results {
            let assetDetails = asset as! Asset
            if let originalURL = assetDetails.getAssetPath() {
                do {
                    try fileManager.removeItemAtPath(originalURL)
                    let thumb = originalURL.stringByReplacingOccurrencesOfString(assetDetails.originalURL, withString: assetDetails.squareURL) as String
                    try fileManager.removeItemAtPath(thumb)
                } catch _ {
                }
            }
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error deleting assets for articles: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    //Delete all assets for multiple issues
    class func deleteAssetsForIssues(issues: NSArray) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issue.globalId IN %@", issues)
        let results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        //Iterate through the results and delete the files saved
        let fileManager = NSFileManager.defaultManager()
        for asset in results {
            let assetDetails = asset as! Asset
            if let originalURL = assetDetails.getAssetPath() {
                do {
                    try fileManager.removeItemAtPath(originalURL)
                    let thumb = originalURL.stringByReplacingOccurrencesOfString(assetDetails.originalURL, withString: assetDetails.squareURL) as String
                    try fileManager.removeItemAtPath(thumb)
                } catch _ {
                }
            }
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error deleting assets for issues: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    //Delete all assets for a single issue
    class func deleteAssetsForIssue(globalId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issue.globalId = %@", globalId)
        let results = Asset.objectsInRealm(realm, withPredicate: predicate)
        var assetIds = [String]()
        
        //Iterate through the results and delete the files saved
        let fileManager = NSFileManager.defaultManager()
        for asset in results {
            let assetDetails = asset as! Asset
            assetIds.append(assetDetails.globalId)
            if let originalURL = assetDetails.getAssetPath() {
                do {
                    try fileManager.removeItemAtPath(originalURL)
                    let thumb = originalURL.stringByReplacingOccurrencesOfString(assetDetails.originalURL, withString: assetDetails.squareURL) as String
                    try fileManager.removeItemAtPath(thumb)
                } catch _ {
                }
            }
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        do {
            try realm.commitWriteTransaction()
            Relation.deleteRelations([globalId as String], articleId: nil, assetId: assetIds)
        } catch let error {
            NSLog("Error deleting assets for issues: \(error)")
        }
        //realm.commitWriteTransaction()
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
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving asset: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    /**
     This method accepts an array of global ids for assets and deletes them from the database. The files for the assets are also deleted
     
     - parameter  assetIds: Array containing the global ids for assets to be deleted
     */
    public class func deleteAssets(assetIds: [String]) {
        lLog("Deleting assets for \(assetIds)")
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId IN %@", assetIds)
        let results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        //Iterate through the results and delete the files saved
        let fileManager = NSFileManager.defaultManager()
        for asset in results {
            let assetDetails = asset as! Asset
            
            if let originalURL = assetDetails.getAssetPath() {
                do {
                    try fileManager.removeItemAtPath(originalURL)
                    let thumb = originalURL.stringByReplacingOccurrencesOfString(assetDetails.originalURL, withString: assetDetails.squareURL) as String
                    try fileManager.removeItemAtPath(thumb)
                } catch _ {
                }
            }
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error deleting asset: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    /**
     This method accepts the global id of an asset and deletes it from the database. The file for the asset is also deleted
     
     :brief: Delete a specific asset
     
     - parameter  assetId: The global id for the asset
     */
    public class func deleteAsset(assetId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = %@", assetId)
        let results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        //Iterate through the results and delete the files saved
        let fileManager = NSFileManager.defaultManager()
        for asset in results {
            let assetDetails = asset as! Asset
            if let originalURL = assetDetails.getAssetPath() {
                do {
                    try fileManager.removeItemAtPath(originalURL)
                    let thumb = originalURL.stringByReplacingOccurrencesOfString(assetDetails.originalURL, withString: assetDetails.squareURL) as String
                    try fileManager.removeItemAtPath(thumb)
                } catch _ {
                }
            }
        }
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error deleting asset: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    /**
     This method uses the global id for an issue and/or article and returns its first image asset (i.e. placement = 1, type = image)
     
     :brief: Retrieve first asset for an issue/article
     
     - parameter  issueId: The global id for the issue
     
     - parameter articleId: The global id for the article
     
     - parameter volumeId: The global id for the volume
     
     :return: Asset object
     */
    public class func getFirstAssetFor(issueId: String, articleId: String, volumeId: String?) -> Asset? {
        _ = RLMRealm.defaultRealm()
        
        if Helper.isNilOrEmpty(issueId) {
            if let vol = volumeId {
                let predicate = NSPredicate(format: "volumeId = %@ AND placement = 1 AND type = %@", vol, "image")
                let assets = Asset.objectsWithPredicate(predicate)
                
                if assets.count > 0 {
                    return assets.firstObject() as? Asset
                }
            }
        }
        
        var assetIds = ""
        if issueId == "" {
            assetIds = Relation.getAssetForArticle(articleId, placement: 1)
        }
        else {
            assetIds = Relation.getAssetsForIssue(issueId, articleId: articleId, placement: 1)
        }
        if !assetIds.isEmpty {
            let predicate = NSPredicate(format: "globalId = %@ AND placement = 1 AND type = %@", assetIds, "image")
            let assets = Asset.objectsWithPredicate(predicate)
            
            if assets.count > 0 {
                return assets.firstObject() as? Asset
            }
            else {
                let predicate = NSPredicate(format: "globalId = %@ AND type = %@", assetIds, "image")
                let assets = Asset.objectsWithPredicate(predicate)
                if assets.count == 1 {
                    return assets.firstObject() as? Asset
                }
            }
        }
        
        return nil
    }
    
    /**
     This method uses the global id for an issue and/or article and returns the number of assets it has
     
     :brief: Retrieve number of assets for an issue/article
     
     - parameter  issueId: The global id for the issue
     
     - parameter articleId: The global id for the article
     
     - parameter volumeId: The global id of the volume
     
     :return: asset count for the issue and/or article
     */
    public class func getNumberOfAssetsFor(issueId: String, articleId: String, volumeId: String?) -> UInt {
        _ = RLMRealm.defaultRealm()
        
        if Helper.isNilOrEmpty(issueId) {
            if let vol = volumeId {
                let predicate = NSPredicate(format: "volumeId = %@", vol)
                let assets = Asset.objectsWithPredicate(predicate)
                
                if assets.count > 0 {
                    lLog("\(assets.count)")
                    return assets.count
                }
            }
        }
        
        let assets = Relation.getAssetsForIssue(issueId, articleId: articleId)
        return UInt(assets.count)
    }
    
    /**
     This method uses the global id for an issue and/or article and the assets in an array. It takes in an optional type parameter. If specified, only assets of that type will be returned
     
     :brief: Retrieve all assets for an issue/article of a specific type
     
     - parameter  issueId: The global id for the issue
     
     - parameter articleId: The global id for the article
     
     - parameter volumeId: The global id for the volume
     
     - parameter type: The type of asset. If nil, all assets will be returned
     
     :return: array of assets following the conditions
     */
    public class func getAssetsFor(issueId: String, articleId: String, volumeId: String?, type: String?) -> Array<Asset>? {
        _ = RLMRealm.defaultRealm()
        
        var subPredicates = Array<NSPredicate>()
        
        if !Helper.isNilOrEmpty(volumeId) {
            if let vol = volumeId {
                let predicate = NSPredicate(format: "volumeId = %@", vol)
                subPredicates.append(predicate)
            }
        }
        
        let assets = Relation.getAssetsForIssue(issueId, articleId: articleId)
        if assets.count > 0 {
            let predicate = NSPredicate(format: "globalId IN %@", assets)
            subPredicates.append(predicate)
        }
        
        if type != nil {
            let assetPredicate = NSPredicate(format: "type = %@", type!)
            subPredicates.append(assetPredicate)
        }
        
        let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
        let results: RLMResults = Asset.objectsWithPredicate(searchPredicate) as RLMResults
        
        if results.count > 0 {
            var array = Array<Asset>()
            for object in results {
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
     
     - parameter  assetId: The global id for the asset
     
     :return: asset object for the global id. Returns nil if the asset is not found
     */
    public class func getAsset(assetId: String) -> Asset? {
        _ = RLMRealm.defaultRealm()
        lLog("\(assetId)")
        
        let predicate = NSPredicate(format: "globalId = %@", assetId)
        let assets = Asset.objectsWithPredicate(predicate)
        
        if assets.count > 0 {
            return assets.firstObject() as? Asset
        }
        
        return nil
    }
    
    /**
     This method inputs the global id of an issue and/or article and returns all sound assets for it in an array
     
     :brief: Retrieve all sound files for an article/issue as a playlist/array
     
     - parameter  issueId: The global id for the issue
     
     - parameter  articleId: The global id for the article
     
     :return: Array of sound asset objects for the given issue and/or article
     */
    public class func getPlaylistFor(issueId: String, articleId: String) -> Array<Asset>? {
        _ = RLMRealm.defaultRealm()
        
        var subPredicates = Array<NSPredicate>()
        
        let assets = Relation.getAssetsForIssue(issueId, articleId: articleId)
        if assets.count > 0 {
            let predicate = NSPredicate(format: "globalId IN %@", assets)
            subPredicates.append(predicate)
        }
        
        let assetPredicate = NSPredicate(format: "type = %@", "sound")
        subPredicates.append(assetPredicate)
        
        let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
        let results: RLMResults = Asset.objectsWithPredicate(searchPredicate) as RLMResults
        
        if results.count > 0 {
            var array = Array<Asset>()
            for object in results {
                let obj: Asset = object as! Asset
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    /**
     This method returns an array of articles for the asset
     
     :return: Array of articles associated with the asset
     */
    public func getArticlesForAsset() -> [String] {
        return Relation.getArticlesForAsset(self.globalId)
    }
    
    /**
     This method returns the path of the asset file for the current object
     
     :return: Path of the asset file or nil if not found
     */
    public func getAssetPath() -> String? {
        lLog("Get path for \(self.globalId)")
        let fileURL = self.originalURL
        if !Helper.isNilOrEmpty(fileURL) {
            
            var assetFolder = ""
            let issueId = Relation.getIssuesForAsset(self.globalId).first
            if let issue = Issue.getIssue(issueId!) {
                assetFolder = issue.assetFolder
            }
            if Helper.isNilOrEmpty(assetFolder) && !volumeId.isEmpty {
                _ = RLMRealm.defaultRealm()
                
                let predicate = NSPredicate(format: "globalId = %@", volumeId)
                let volumes = Volume.objectsWithPredicate(predicate)
                
                if volumes.count > 0 {
                    let volume: Volume = volumes.firstObject() as! Volume
                    assetFolder = volume.assetFolder
                }
            }
            if Helper.isNilOrEmpty(assetFolder) {
                assetFolder = "/Documents"
            }
            
            //Found the asset folder. Get the file now
            var folderPath = assetFolder
            if assetFolder.hasPrefix("/Documents") {
                var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
                let docsDir: NSString = docPaths[0] as NSString
                folderPath = assetFolder.stringByReplacingOccurrencesOfString("/Documents", withString: docsDir as String)
            }
            
            if !folderPath.hasSuffix("/") {
                //Add the trailing slash
                folderPath = "\(folderPath)/"
            }
            let filePath = "\(folderPath)\(fileURL)"
            lLog("\(filePath) for \(self.globalId)")
            return filePath
        }
        return nil
    }
    
    /**
     This method returns an image for an asset if it exists
     
     :return: Image or nil if not found
     */
    public func getAssetImage() -> UIImage? {
        if let assetPath = self.getAssetPath() {
            if NSFileManager.defaultManager().fileExistsAtPath(assetPath) {
                return UIImage(contentsOfFile: assetPath) //will return image or nil
            }
        }
        return nil
    }
    
    private func assetImageExists() -> Bool {
        if let assetPath = self.getAssetPath() {
            if NSFileManager.defaultManager().fileExistsAtPath(assetPath) {
                if let _ = UIImage(contentsOfFile: assetPath) {
                    return true
                }
            }
        }
        return false
    }
    
    public func getAssetThumbImage() -> UIImage? {
        if let assetPath = self.getAssetPath() {
            let thumbPath = assetPath.stringByReplacingOccurrencesOfString(self.originalURL, withString: self.squareURL)
            if NSFileManager.defaultManager().fileExistsAtPath(thumbPath) {
                return UIImage(contentsOfFile: thumbPath)
            }
        }
        return nil
    }
    
    /**
     This method returns the value for a specific key from the custom metadata of the asset
     
     :return: an object for the key from the custom metadata (or nil)
     */
    public func getValue(key: NSString) -> AnyObject? {
        
        let testAsset = Asset()
        let properties: NSArray = testAsset.objectSchema.properties
        
        var foundProperty = false
        for property: RLMProperty in properties as! [RLMProperty] {
            let propertyName = property.name
            if propertyName == key {
                //This is the property we are looking for
                foundProperty = true
                break
            }
        }
        if (foundProperty) {
            //Get value of this property and return
            return self.valueForKey(key as String)
        }
        else {
            //This is a metadata key
            let metadata: AnyObject? = Helper.jsonFromString(self.metadata)
            if let metadataDict = metadata as? NSDictionary {
                return metadataDict.valueForKey(key as String)
            }
        }
        
        return nil
    }
    
    public func getOriginalImageForAsset(article: String?, issue: String?) -> String? {
        //If image exists, return its path
        //If not, download image for asset if we have the URL in the asset object - return nil - will send notif
        //If not, get the asset object from magnet, get the URL and download image - return nil - will send notif
        if let assetPath = self.getAssetPath() {
            if NSFileManager.defaultManager().fileExistsAtPath(assetPath) {
                if let _ = UIImage(contentsOfFile: assetPath) {
                    return assetPath
                }
            }
            //Do we have URLs? Download then
            if !self.cdnUrl.isEmpty {
                //Download CDN image
                let imageDownloader = SDWebImageManager.sharedManager()
                let url = NSURL(string: self.cdnUrl)
                imageDownloader.downloadImageWithURL(url, options: [], progress: {(receivedSize: Int, expectedSize: Int) -> Void in
                    // progression tracking code
                    }, completed: {(image: UIImage!, error: NSError!, cacheType: SDImageCacheType!, finished: Bool, imageUrl: NSURL!) -> Void in
                        if image != nil && finished {
                            
                            autoreleasepool{
                                let data = UIImageJPEGRepresentation(image, 0.8)
                                data!.writeToFile(assetPath, atomically: true)
                            }
                            
                            SDImageCache.sharedImageCache().clearMemory()
                            
                            var userInfo = ["media":self.globalId, "type":"original"]
                            //Check relation between issue, article and asset as well
                            if let articleGlobalId = article {
                                if Relation.assetExistsForArticle(articleGlobalId, assetId: self.globalId) {
                                    userInfo["article"] = articleGlobalId
                                }
                            }
                            if let issueGlobalId = issue {
                                if Relation.assetExistsForIssue(issueGlobalId, assetId: self.globalId) {
                                    userInfo["issue"] = issueGlobalId
                                }
                            }
                            lLog("Pushing IMAGE_DOWNLOADED for M:\(self.globalId)")
                            NSNotificationCenter.defaultCenter().postNotificationName(IMAGE_DOWNLOADED, object: nil, userInfo: userInfo)
                            return
                            //}
                        }
                        if let err = error {
                            //cdn url download failed, try downloading using self.imgUrl
                            lLog("Error downloading \(self.cdnUrl): \(err.localizedDescription)")
                            self.downloadImage(self.imgUrl, toPath: assetPath, article: article, issue: issue)
                        }
                })
            }
            else if !self.imgUrl.isEmpty {
                self.downloadImage(self.imgUrl, toPath: assetPath, article: article, issue: issue)
            }
        }
        
        return nil
    }
    
    public func getThumbImageForAsset(article: String?, issue: String?) -> String? {
        //If image exists, return its path
        //If not, download image for asset if we have the URL in the asset object - return nil - will send notif
        //If not, get the asset object from magnet, get the URL and download image - return nil - will send notif
        if let assetPath = self.getAssetPath() {
            let thumbPath = assetPath.stringByReplacingOccurrencesOfString(self.originalURL, withString: self.squareURL)
            if NSFileManager.defaultManager().fileExistsAtPath(thumbPath) {
                if let _ = UIImage(contentsOfFile: thumbPath) {
                    return thumbPath
                }
            }
            if !self.cdnThumbUrl.isEmpty {
                //Download CDN image
                let imageDownloader = SDWebImageManager.sharedManager()
                //let imageDownloader = SDWebImageDownloader.sharedDownloader()
                let url = NSURL(string: self.cdnThumbUrl)
                imageDownloader.downloadImageWithURL(url, options: [], progress: {(receivedSize: Int, expectedSize: Int) -> Void in
                    // progression tracking code
                    }, completed: {(image: UIImage!, error: NSError!, cacheType: SDImageCacheType!, finished: Bool, imageUrl: NSURL!) -> Void in
                       //completed: {(image: UIImage!, data: NSData!, error: NSError!, finished: Bool) -> Void in
                        
                        if image != nil && finished {
                            
                            let thumbPath = assetPath.stringByReplacingOccurrencesOfString(self.originalURL, withString: self.squareURL)
                            autoreleasepool{
                                let data = UIImageJPEGRepresentation(image, 0.8)
                                data!.writeToFile(thumbPath, atomically: true)
                            }
                            
                            SDImageCache.sharedImageCache().clearMemory()
                            
                            var userInfo = ["media":self.globalId, "type":"thumb"]
                            if let articleGlobalId = article {
                                //if let _ = Relation.getAssetsForArticle(articleGlobalId).indexOf(self.globalId) {
                                if Relation.assetExistsForArticle(articleGlobalId, assetId: self.globalId) {
                                    userInfo["article"] = articleGlobalId
                                }
                            }
                            if let issueGlobalId = issue {
                                //if let _ = Relation.getAssetsForIssue(issueGlobalId).indexOf(self.globalId) {
                                if Relation.assetExistsForIssue(issueGlobalId, assetId: self.globalId) {
                                    userInfo["issue"] = issueGlobalId
                                }
                            }
                            lLog("Pushing IMAGE_DOWNLOADED THUMB for M:\(self.globalId)")
                            NSNotificationCenter.defaultCenter().postNotificationName(IMAGE_DOWNLOADED, object: nil, userInfo: userInfo)
                            return
                            //}
                        }
                        if error != nil {
                            //cdn url download failed, try downloading using self.imgUrl
                            lLog("Error downloading \(self.cdnThumbUrl): \(error.localizedDescription)")
                            let thumbPath = assetPath.stringByReplacingOccurrencesOfString(self.originalURL, withString: self.squareURL)
                            self.downloadImage(self.imgThumbUrl, toPath: thumbPath, article: article, issue: issue)
                        }
                })
            }
            else if !self.imgThumbUrl.isEmpty {
                let thumbPath = assetPath.stringByReplacingOccurrencesOfString(self.originalURL, withString: self.squareURL)
                self.downloadImage(self.imgThumbUrl, toPath: thumbPath, article: article, issue: issue)
            }
        }
        
        return nil
    }
    
    private func downloadImage(url: String, toPath: String, article: String?, issue: String?) {
        if !url.isEmpty {
            let imageDownloader = SDWebImageManager.sharedManager()
            let imgUrl = NSURL(string: url)
            imageDownloader.downloadImageWithURL(imgUrl, options: [], progress: {(receivedSize: Int, expectedSize: Int) -> Void in
                // progression tracking code
                }, completed: {(image: UIImage!, error: NSError!, cacheType: SDImageCacheType!, finished: Bool, imageUrl: NSURL!) -> Void in
                    if image != nil && finished {
                        
                        autoreleasepool{
                            let data = UIImageJPEGRepresentation(image, 0.8)
                            data!.writeToFile(toPath, atomically: true)
                        }
                        
                        SDImageCache.sharedImageCache().clearMemory()
                        
                        var userInfo = ["media":self.globalId, "type":"original"]
                        if let articleGlobalId = article {
                            //if let _ = Relation.getAssetsForArticle(articleGlobalId).indexOf(self.globalId) {
                            if Relation.assetExistsForArticle(articleGlobalId, assetId: self.globalId) {
                                userInfo["article"] = articleGlobalId
                            }
                        }
                        if let issueGlobalId = issue {
                            //if let _ = Relation.getAssetsForIssue(issueGlobalId).indexOf(self.globalId) {
                            if Relation.assetExistsForIssue(issueGlobalId, assetId: self.globalId) {
                                userInfo["issue"] = issueGlobalId
                            }
                        }
                        lLog("Pushing IMAGE_DOWNLOADED for M:\(self.globalId)")
                        NSNotificationCenter.defaultCenter().postNotificationName(IMAGE_DOWNLOADED, object: nil, userInfo: userInfo)
                        
                        return
                    }
                    else if error != nil {
                        //cdn url download failed, try downloading using self.imgUrl
                        lLog("Error downloading \(self.cdnThumbUrl): \(error.localizedDescription)")
                    }
            })
        }
        else {
            
        }
    }
}
