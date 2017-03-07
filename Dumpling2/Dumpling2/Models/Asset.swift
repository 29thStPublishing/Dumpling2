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
open class Asset: RLMObject {
    /// Global id of an asset - this is unique for each asset
    dynamic open var globalId = ""
    /// Caption for the asset - used in the final rendered HTML
    dynamic open var caption = ""
    /// Source attribution for the asset
    dynamic open var source = ""
    /// File URL for the asset's square thumbnail
    dynamic open var squareURL = ""
    /// File URL for the original asset
    dynamic open var originalURL = ""
    /// File URL for the portrait image of the asset
    dynamic open var mainPortraitURL = ""
    /// File URL for the landscape image of the asset
    dynamic open var mainLandscapeURL = ""
    /// File URL for the icon image
    dynamic open var iconURL = ""
    /// Custom metadata for the asset
    dynamic open var metadata = ""
    /// Asset type. Defaults to a photo. Can be image, sound, video or custom
    dynamic open var type = AssetType.Image.rawValue //default to a photo
    /// Placement of an asset for an article or issue
    dynamic open var placement = 0
    /// Folder which stores the asset files - downloaded or unzipped
    dynamic open var fullFolderPath = ""
    /// Global id for the article with which the asset is associated. Can be blank if this is an issue's asset
    dynamic open var articleId = ""
    /// Issue object for the issue with which the asset is associated. Can be a default Issue object if the asset is for an independent article
    dynamic open var issue = Issue()
    /// Global id of volume the asset is associated with. Can be blank if this is an issue or article asset
    dynamic open var volumeId = ""
    
    override open class func primaryKey() -> String {
        return "globalId"
    }
    
    //Required for backward compatibility when upgrading to V 0.96.2
    override open class func requiredProperties() -> Array<String> {
        return ["globalId", "caption", "source", "squareURL", "originalURL", "mainPortraitURL", "mainLandscapeURL", "iconURL", "metadata", "type", "placement", "fullFolderPath", "articleId", "volumeId"]
    }
    
    //Add asset
    class func createAsset(_ asset: NSDictionary, issue: Issue, articleId: String, placement: Int) {
        createAsset(asset, issue: issue, articleId: articleId, sound: false, placement: placement)
    }
    
    //Add any asset (sound/image)
    class func createAsset(_ asset: NSDictionary, issue: Issue, articleId: String, sound: Bool, placement: Int) {
        var type = AssetType.Image.rawValue
        if sound {
            type = AssetType.Sound.rawValue
        }
        createAsset(asset, issue: issue, articleId: articleId, type: type, placement: placement)
    }
    
    //Add any asset (sound/image/anything else)
    class func createAsset(_ asset: NSDictionary, issue: Issue, articleId: String, type: String, placement: Int) {
        let realm = RLMRealm.default()
        
        let globalId = asset.object(forKey: "id") as! String
        let results = Asset.objects(where: "globalId = '\(globalId)'")
        var currentAsset: Asset!
        
        realm.beginWriteTransaction()
        if results.count > 0 {
            //existing asset
            currentAsset = results.firstObject() as! Asset
        }
        else {
            //Create a new asset
            currentAsset = Asset()
            currentAsset.globalId = asset.object(forKey: "id") as! String
        }
        
        currentAsset.caption = asset.object(forKey: "caption") as! String
        currentAsset.source = asset.object(forKey: "source") as! String
        if let metadata: AnyObject = asset.object(forKey: "metadata") as AnyObject? {
            if metadata is NSDictionary {
                currentAsset.metadata = Helper.stringFromJSON(metadata)! // metadata.JSONString()!
            }
            else {
                currentAsset.metadata = metadata as! String
            }
        }
        currentAsset.issue = issue
        currentAsset.articleId = articleId
        
        currentAsset.type = type
        
        var value = asset.object(forKey: "crop_350_350") as! String
        currentAsset.squareURL = value
        
        value = asset.object(forKey: "file_name") as! String
        currentAsset.originalURL = value
        
        var main_portrait = ""
        var main_landscape = ""
        var icon = ""
        
        let device = Helper.isiPhone() ? "iphone" : "ipad"
        let quality = Helper.isRetinaDevice() ? "_retinal" : ""
        
        if let cover = asset.object(forKey: "cover") as? NSDictionary {
            var key = "cover_main_\(device)_portrait\(quality)"
            value = cover.object(forKey: key) as! String
            main_portrait = value
            
            key = "cover_main_\(device)_landscape\(quality)"
            if let val = cover.object(forKey: key) as? String {
                main_landscape = val
            }
            
            key = "cover_icon_iphone_portrait_retinal"
            value = cover.object(forKey: key) as! String
            icon = value
        }
        else if let cropDict = asset.object(forKey: "crop") as? NSDictionary {
            var key = "main_\(device)_portrait\(quality)"
            value = cropDict.object(forKey: key) as! String
            main_portrait = value
            
            key = "main_\(device)_landscape\(quality)"
            if let val = cropDict.object(forKey: key) as? String {
                main_landscape = val
            }
        }
        
        currentAsset.mainPortraitURL = main_portrait
        currentAsset.mainLandscapeURL = main_landscape
        currentAsset.iconURL = icon
        
        currentAsset.placement = placement
        
        realm.addOrUpdate(currentAsset)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error creating asset: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    //Add asset from API for volumes
    class func downloadAndCreateVolumeAsset(_ assetId: NSString, volume: Volume, placement: Int, delegate: AnyObject?) {
        lLog("Volume asset \(assetId)")
        let realm = RLMRealm.default()
        
        let requestURL = "\(baseURL)media/\(assetId)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allMedia: NSArray = response.value(forKey: "media") as! NSArray
                let mediaFile: NSDictionary = allMedia.firstObject as! NSDictionary
                //Update Asset now

                realm.beginWriteTransaction()
                
                let currentAsset = Asset()
                currentAsset.globalId = mediaFile.value(forKey: "id") as! String
                currentAsset.caption = mediaFile.value(forKey: "caption") as! String
                currentAsset.volumeId = volume.globalId
                
                let meta = mediaFile.object(forKey: "meta") as! NSDictionary
                let dataType = meta.object(forKey: "type") as! NSString
                if dataType.isEqual(to: "image") {
                    currentAsset.type = AssetType.Image.rawValue
                }
                else if dataType.isEqual(to: "audio") {
                    currentAsset.type = AssetType.Sound.rawValue
                }
                else if dataType.isEqual(to: "video") {
                    currentAsset.type = AssetType.Video.rawValue
                }
                else {
                    currentAsset.type = dataType as String
                }
                currentAsset.placement = placement
                
                var isCdn = true
                var fileUrl = mediaFile.value(forKey: "cdnUrl") as! String
                if Helper.isNilOrEmpty(fileUrl) {
                    fileUrl = mediaFile.value(forKey: "url") as! String
                    isCdn = false
                }
                
                var finalURL: String
                if volume.assetFolder.hasPrefix("/Documents") {
                    var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                    let docsDir: NSString = docPaths[0] as NSString
                    let finalFolder = volume.assetFolder.replacingOccurrences(of: "/Documents", with: docsDir as String)
                    finalURL = "\(finalFolder)/original-\((fileUrl as NSString).lastPathComponent)"
                }
                else {
                    finalURL = "\(volume.assetFolder)/original-\((fileUrl as NSString).lastPathComponent)"
                }
                
                var toDownload = true //Define whether the image should be downloaded or not
                if let existingAsset = Asset.getAsset(currentAsset.globalId) {
                    //Asset exists already
                    if let updateDate: String = existingAsset.getValue("updateDate") as? String {
                        //Get date from this string
                        let lastUpdatedDate = Helper.publishedDateFromISO(updateDate)
                        var newUpdatedDate = Date()
                        if let updated: Dictionary<String, AnyObject> = meta.object(forKey: "updated") as? Dictionary {
                            if let dt: String = updated["date"] as? String {
                                newUpdatedDate = Helper.publishedDateFromISO(dt)
                            }
                        }
                        //Compare the two dates - if newUpdated <= lastUpdated, don't download
                        if newUpdatedDate.compare(lastUpdatedDate) != ComparisonResult.orderedDescending {
                            toDownload = false //Don't download - this file is up-to-date (if present)
                        }
                    }
                    //Check if the image exists already
                    if FileManager.default.fileExists(atPath: finalURL) {
                        let dict = try? FileManager.default.attributesOfItem(atPath: finalURL)
                        if let fileSize: NSNumber = dict![FileAttributeKey.size] as? NSNumber {
                            if fileSize.int64Value > 0 {
                                toDownload = false //we have a valid file
                            }
                            else {
                                toDownload = true //file not downloaded
                            }
                        }
                    }
                    else {
                        toDownload = true //file not downloaded
                    }
                }
                
                if toDownload {
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
                            print("Error cdn: " + err.description)
                            //Try downloading with url if cdn url download failed
                            if isCdn {
                                fileUrl = mediaFile.value(forKey: "url") as! String
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
                                        print("Error non cdn: " + err.description)
                                        if delegate != nil {
                                            (delegate as! IssueHandler).updateStatusDictionary(volume.globalId, issueId: "", url: requestURL, status: 2)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    if delegate != nil {
                        (delegate as! IssueHandler).updateStatusDictionary(volume.globalId, issueId:"", url: requestURL, status: 1)
                    }
                }
                
                currentAsset.originalURL = "original-\((fileUrl as NSString).lastPathComponent)"
                
                var isCdnThumb = true
                var thumbUrl = mediaFile.value(forKey: "cdnUrlThumb") as! String
                if Helper.isNilOrEmpty(thumbUrl) {
                    thumbUrl = mediaFile.value(forKey: "urlThumb") as! String
                    isCdnThumb = false
                }
                
                var finalThumbURL: String
                if volume.assetFolder.hasPrefix("/Documents") {
                    var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                    let docsDir: NSString = docPaths[0] as NSString
                    let finalFolder = volume.assetFolder.replacingOccurrences(of: "/Documents", with: docsDir as String)
                    finalThumbURL = "\(finalFolder)/thumb-\((thumbUrl as NSString).lastPathComponent)"
                }
                else {
                    finalThumbURL = "\(volume.assetFolder)/thumb-\((thumbUrl as NSString).lastPathComponent)"
                }
                
                networkManager.downloadFile(thumbUrl, toPath: finalThumbURL) {
                    (status:AnyObject?, error:NSError?) -> () in
                    if status != nil {
                        _ = status as! NSNumber
                    }
                    else if let err = error {
                        print("Error: " + err.description)
                        //Try downloading with url if cdn url download failed
                        if isCdnThumb {
                            thumbUrl = mediaFile.value(forKey: "urlThumb") as! String
                            networkManager.downloadFile(thumbUrl, toPath: finalThumbURL) {
                                (status:AnyObject?, error:NSError?) -> () in
                                if status != nil {
                                    _ = status as! NSNumber
                                }
                                else if let err = error {
                                    print("Error non cdn: " + err.description)
                                }
                            }
                        }
                    }
                }
                
                currentAsset.squareURL = "thumb-\((thumbUrl as NSString).lastPathComponent)"
                if let metadata: Any = mediaFile.object(forKey: "customMeta") {
                    if metadata is NSDictionary {
                        let metadataDict = NSMutableDictionary(dictionary: metadata as! NSDictionary)
                        if let height = meta.object(forKey: "height") {
                            metadataDict.setObject(height, forKey: "height" as NSCopying)
                        }
                        if let width = meta.object(forKey: "width") {
                            metadataDict.setObject(width, forKey: "width" as NSCopying)
                        }
                        if let updated: Dictionary<String, AnyObject> = meta.object(forKey: "updated") as? Dictionary {
                            if let updateDate: String = updated["date"] as? String {
                                metadataDict.setObject(updateDate, forKey: "updateDate" as NSCopying)
                            }
                        }
                        currentAsset.metadata = Helper.stringFromJSON(metadataDict)!
                    }
                    else {
                        currentAsset.metadata = metadata as! String
                    }
                }
                
                realm.addOrUpdate(currentAsset)
                do {
                    try realm.commitWriteTransaction()
                } catch let error {
                    NSLog("Error writing volume asset: \(error)")
                }
                //realm.commitWriteTransaction()
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
    class func downloadAndCreateAsset(_ assetId: NSString, issue: Issue, articleId: String, placement: Int, delegate: AnyObject?) {
        lLog("Asset \(assetId)")
        let realm = RLMRealm.default()
        
        let requestURL = "\(baseURL)media/\(assetId)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allMedia: NSArray = response.value(forKey: "media") as! NSArray
                let mediaFile: NSDictionary = allMedia.firstObject as! NSDictionary
                
                //Update Asset now
                realm.beginWriteTransaction()

                let currentAsset = Asset()
                currentAsset.globalId = mediaFile.value(forKey: "id") as! String
                currentAsset.caption = mediaFile.value(forKey: "caption") as! String
                currentAsset.issue = issue
                currentAsset.articleId = articleId
                
                let meta = mediaFile.object(forKey: "meta") as! NSDictionary
                let dataType = meta.object(forKey: "type") as! NSString
                if dataType.isEqual(to: "image") {
                    currentAsset.type = AssetType.Image.rawValue
                }
                else if dataType.isEqual(to: "audio") {
                    currentAsset.type = AssetType.Sound.rawValue
                }
                else if dataType.isEqual(to: "video") {
                    currentAsset.type = AssetType.Video.rawValue
                }
                else {
                    currentAsset.type = dataType as String
                }
                currentAsset.placement = placement
                
                var isCdn = true
                var fileUrl = mediaFile.value(forKey: "cdnUrl") as! String
                if Helper.isNilOrEmpty(fileUrl) {
                    fileUrl = mediaFile.value(forKey: "url") as! String
                    isCdn = false
                }
                var finalURL: String
                if issue.assetFolder.hasPrefix("/Documents") {
                    var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                    let docsDir: NSString = docPaths[0] as NSString
                    let finalFolder = issue.assetFolder.replacingOccurrences(of: "/Documents", with: docsDir as String)
                    finalURL = "\(finalFolder)/original-\((fileUrl as NSString).lastPathComponent)"
                }
                else {
                    finalURL = "\(issue.assetFolder)/original-\((fileUrl as NSString).lastPathComponent)"
                }
                
                var toDownload = true //Define whether the image should be downloaded or not
                if let existingAsset = Asset.getAsset(currentAsset.globalId) {
                    //Asset exists already
                    if let updateDate: String = existingAsset.getValue("updateDate") as? String {
                        //Get date from this string
                        let lastUpdatedDate = Helper.publishedDateFromISO(updateDate)
                        var newUpdatedDate = Date()
                        if let updated: Dictionary<String, AnyObject> = meta.object(forKey: "updated") as? Dictionary {
                            if let dt: String = updated["date"] as? String {
                                newUpdatedDate = Helper.publishedDateFromISO(dt)
                            }
                        }
                        //Compare the two dates - if newUpdated <= lastUpdated, don't download
                        if newUpdatedDate.compare(lastUpdatedDate) != ComparisonResult.orderedDescending {
                            toDownload = false //Don't download
                        }
                    }
                    //Check if the image exists already
                    if FileManager.default.fileExists(atPath: finalURL) {
                        let dict = try? FileManager.default.attributesOfItem(atPath: finalURL)
                        if let fileSize: NSNumber = dict![FileAttributeKey.size] as? NSNumber {
                            if fileSize.int64Value > 0 {
                                toDownload = false //we have a valid file
                            }
                            else {
                                toDownload = true
                            }
                        }
                    }
                    else {
                        toDownload = true
                    }
                }

                if toDownload {
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
                            print("Error: " + err.description)
                            if isCdn {
                                fileUrl = mediaFile.value(forKey: "url") as! String
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
                                    else if let _ = error {
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
                        }
                    }
                }
                else {
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
                currentAsset.originalURL = "original-\((fileUrl as NSString).lastPathComponent)"
                
                var isCdnThumb = true
                var thumbUrl = mediaFile.value(forKey: "cdnUrlThumb") as! String
                if Helper.isNilOrEmpty(thumbUrl) {
                    thumbUrl = mediaFile.value(forKey: "urlThumb") as! String
                    isCdnThumb = false
                }
                
                var finalThumbURL: String
                if issue.assetFolder.hasPrefix("/Documents") {
                    var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                    let docsDir: NSString = docPaths[0] as NSString
                    let finalFolder = issue.assetFolder.replacingOccurrences(of: "/Documents", with: docsDir as String)
                    finalThumbURL = "\(finalFolder)/thumb-\((thumbUrl as NSString).lastPathComponent)"
                }
                else {
                    finalThumbURL = "\(issue.assetFolder)/thumb-\((thumbUrl as NSString).lastPathComponent)"
                }
                
                networkManager.downloadFile(thumbUrl, toPath: finalThumbURL) {
                    (status:AnyObject?, error:NSError?) -> () in
                    if status != nil {
                        let completed = status as! NSNumber
                        if completed.boolValue {
                            //Mark asset download as done
                        }
                    }
                    else if let err = error {
                        print("Error: " + err.description)
                        if isCdnThumb {
                            thumbUrl = mediaFile.value(forKey: "urlThumb") as! String
                            networkManager.downloadFile(thumbUrl, toPath: finalThumbURL) {
                                (status:AnyObject?, error:NSError?) -> () in
                                if status != nil {
                                    let completed = status as! NSNumber
                                    if completed.boolValue {
                                    }
                                }
                                else if let err = error {
                                    print("Error: " + err.description)
                                }
                            }
                        }
                    }
                }
                currentAsset.squareURL = "thumb-\((thumbUrl as NSString).lastPathComponent)"
                
                if let metadata: Any = mediaFile.object(forKey: "customMeta") {
                    if metadata is NSDictionary {
                        let metadataDict = NSMutableDictionary(dictionary: metadata as! NSDictionary)
                        if let height = meta.object(forKey: "height") {
                            metadataDict.setObject(height, forKey: "height" as NSCopying)
                        }
                        if let width = meta.object(forKey: "width") {
                            metadataDict.setObject(width, forKey: "width" as NSCopying)
                        }
                        if let updated: Dictionary<String, AnyObject> = meta.object(forKey: "updated") as? Dictionary {
                            if let updateDate: String = updated["date"] as? String {
                                metadataDict.setObject(updateDate, forKey: "updateDate" as NSCopying)
                            }
                        }
                        currentAsset.metadata = Helper.stringFromJSON(metadataDict)!
                    }
                    else {
                        currentAsset.metadata = metadata as! String
                    }
                }
                
                realm.addOrUpdate(currentAsset)
                do {
                    try realm.commitWriteTransaction()
                } catch let error {
                    NSLog("Error creating asset: \(error)")
                }
                //realm.commitWriteTransaction()
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
    class func downloadAndCreateAssetsForIds(_ assetIds: String, issue: Issue?, articleId: String, delegate: AnyObject?) {
        lLog("downloadAndCreateAssetsFrom \(assetIds)")
        let realm = RLMRealm.default()
        
        let requestURL = "\(baseURL)media/\(assetIds)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allMedia: NSArray = response.value(forKey: "media") as! NSArray
                
                for (index, mediaFile) in allMedia.enumerated() {
                    //Update Asset now
                    realm.beginWriteTransaction()
                    
                    let currentAsset = Asset()
                    let mediaFileDictionary = mediaFile as! NSDictionary
                    currentAsset.globalId = mediaFileDictionary.value(forKey: "id") as! String
                    currentAsset.caption = mediaFileDictionary.value(forKey: "caption") as! String
                    if let issue = issue {
                        currentAsset.issue = issue
                    }
                    currentAsset.articleId = articleId
                    
                    let meta = mediaFileDictionary.object(forKey: "meta") as! NSDictionary
                    let dataType = meta.object(forKey: "type") as! NSString
                    if dataType.isEqual(to: "image") {
                        currentAsset.type = AssetType.Image.rawValue
                    }
                    else if dataType.isEqual(to: "audio") {
                        currentAsset.type = AssetType.Sound.rawValue
                    }
                    else if dataType.isEqual(to: "video") {
                        currentAsset.type = AssetType.Video.rawValue
                    }
                    else {
                        currentAsset.type = dataType as String
                    }
                    currentAsset.placement = index + 1
                    
                    var isCdn = true
                    var fileUrl = mediaFileDictionary.value(forKey: "cdnUrl") as! String
                    if Helper.isNilOrEmpty(fileUrl) {
                        fileUrl = mediaFileDictionary.value(forKey: "url") as! String
                        isCdn = false
                    }
                    var finalURL: String = ""
                    if let issue = issue {
                        if issue.assetFolder.hasPrefix("/Documents") {
                            var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                            let docsDir: NSString = docPaths[0] as NSString
                            let finalFolder = issue.assetFolder.replacingOccurrences(of: "/Documents", with: docsDir as String)
                            finalURL = "\(finalFolder)/original-\((fileUrl as NSString).lastPathComponent)"
                        }
                        else {
                            finalURL = "\(issue.assetFolder)/original-\((fileUrl as NSString).lastPathComponent)"
                        }
                    }
                    else {
                        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                        let docsDir = docPaths[0]
                        finalURL = "\(docsDir)/original-\((fileUrl as NSString).lastPathComponent)"
                    }
                    
                    var toDownload = true //Define whether the image should be downloaded or not
                    if let existingAsset = Asset.getAsset(currentAsset.globalId) {
                        //Asset exists already
                        if let updateDate: String = existingAsset.getValue("updateDate") as? String {
                            //Get date from this string
                            let lastUpdatedDate = Helper.publishedDateFromISO(updateDate)
                            var newUpdatedDate = Date()
                            if let updated: Dictionary<String, AnyObject> = meta.object(forKey: "updated") as? Dictionary {
                                if let dt: String = updated["date"] as? String {
                                    newUpdatedDate = Helper.publishedDateFromISO(dt)
                                }
                            }
                            //Compare the two dates - if newUpdated <= lastUpdated, don't download
                            if newUpdatedDate.compare(lastUpdatedDate) != ComparisonResult.orderedDescending {
                                toDownload = false //Don't download
                            }
                        }
                        //Check if the image exists already
                        if FileManager.default.fileExists(atPath: finalURL) {
                            let dict = try? FileManager.default.attributesOfItem(atPath: finalURL)
                            if let fileSize: NSNumber = dict![FileAttributeKey.size] as? NSNumber {
                                if fileSize.int64Value > 0 {
                                    toDownload = false //we have a valid file
                                }
                                else {
                                    toDownload = true
                                }
                            }
                        }
                        else {
                            toDownload = true
                        }
                    }
                    
                    if toDownload {
                        networkManager.downloadFile(fileUrl, toPath: finalURL) {
                            (status:AnyObject?, error:NSError?) -> () in
                            if status != nil {
                                let completed = status as! NSNumber
                                if completed.boolValue {
                                    //Mark asset download as done
                                    if delegate != nil {
                                        if let issue = issue {
                                            if !issue.globalId.isEmpty {
                                                //This is an issue's asset or an article's (belonging to an issue) asset
                                                (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 1)
                                            }
                                            else {
                                                //This is an independent article's asset
                                                (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 1)
                                            }
                                        }
                                        else {
                                            //This is an independent article's asset
                                            (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 1)
                                        }
                                    }
                                }
                            }
                            else if let err = error {
                                print("Error: " + err.description)
                                if isCdn {
                                    fileUrl = mediaFileDictionary.value(forKey: "url") as! String
                                    networkManager.downloadFile(fileUrl, toPath: finalURL) {
                                        (status:AnyObject?, error:NSError?) -> () in
                                        if status != nil {
                                            let completed = status as! NSNumber
                                            if completed.boolValue {
                                                //Mark asset download as done
                                                if delegate != nil {
                                                    if let issue = issue {
                                                        if !issue.globalId.isEmpty {
                                                            //This is an issue's asset or an article's (belonging to an issue) asset
                                                            (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 1)
                                                        }
                                                        else {
                                                            //This is an independent article's asset
                                                            (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 1)
                                                        }
                                                    }
                                                    else {
                                                        (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 1)
                                                    }
                                                }
                                            }
                                        }
                                        else if let _ = error {
                                            if delegate != nil {
                                                if let issue = issue {
                                                    if !issue.globalId.isEmpty {
                                                        (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 2)
                                                    }
                                                    else {
                                                        (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 2)
                                                    }
                                                }
                                                else {
                                                    (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 2)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else {
                        if delegate != nil {
                            if let issue = issue {
                                if !issue.globalId.isEmpty {
                                    //This is an issue's asset or an article's (belonging to an issue) asset
                                    (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 1)
                                }
                                else {
                                    //This is an independent article's asset
                                    (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 1)
                                }
                            }
                            else {
                                (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: "\(baseURL)media/\(currentAsset.globalId)", status: 1)
                            }
                        }
                    }
                    currentAsset.originalURL = "original-\((fileUrl as NSString).lastPathComponent)"
                    
                    var isCdnThumb = true
                    var thumbUrl = mediaFileDictionary.value(forKey: "cdnUrlThumb") as! String
                    if Helper.isNilOrEmpty(thumbUrl) {
                        thumbUrl = mediaFileDictionary.value(forKey: "urlThumb") as! String
                        isCdnThumb = false
                    }
                    
                    var finalThumbURL: String
                    if let issue = issue {
                        if issue.assetFolder.hasPrefix("/Documents") {
                            var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                            let docsDir: NSString = docPaths[0] as NSString
                            let finalFolder = issue.assetFolder.replacingOccurrences(of: "/Documents", with: docsDir as String)
                            finalThumbURL = "\(finalFolder)/thumb-\((thumbUrl as NSString).lastPathComponent)"
                        }
                        else {
                            finalThumbURL = "\(issue.assetFolder)/thumb-\((thumbUrl as NSString).lastPathComponent)"
                        }
                    }
                    else {
                        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                        let docsDir = docPaths[0]
                        finalThumbURL = "\(docsDir)/thumb-\((thumbUrl as NSString).lastPathComponent)"
                    }
                    
                    networkManager.downloadFile(thumbUrl, toPath: finalThumbURL) {
                        (status:AnyObject?, error:NSError?) -> () in
                        if status != nil {
                            let completed = status as! NSNumber
                            if completed.boolValue {
                                //Mark asset download as done
                            }
                        }
                        else if let err = error {
                            print("Error: " + err.description)
                            if isCdnThumb {
                                thumbUrl = mediaFileDictionary.value(forKey: "urlThumb") as! String
                                networkManager.downloadFile(thumbUrl, toPath: finalThumbURL) {
                                    (status:AnyObject?, error:NSError?) -> () in
                                    if status != nil {
                                        let completed = status as! NSNumber
                                        if completed.boolValue {
                                        }
                                    }
                                    else if let err = error {
                                        print("Error: " + err.description)
                                    }
                                }
                            }
                        }
                    }
                    currentAsset.squareURL = "thumb-\((thumbUrl as NSString).lastPathComponent)"
                    
                    if let metadata: Any = mediaFileDictionary.object(forKey: "customMeta") {
                        if metadata is NSDictionary {
                            let metadataDict = NSMutableDictionary(dictionary: metadata as! NSDictionary)
                            if let height = meta.object(forKey: "height") {
                                metadataDict.setObject(height, forKey: "height" as NSCopying)
                            }
                            if let width = meta.object(forKey: "width") {
                                metadataDict.setObject(width, forKey: "width" as NSCopying)
                            }
                            if let updated: Dictionary<String, AnyObject> = meta.object(forKey: "updated") as? Dictionary {
                                if let updateDate: String = updated["date"] as? String {
                                    metadataDict.setObject(updateDate, forKey: "updateDate" as NSCopying)
                                }
                            }
                            currentAsset.metadata = Helper.stringFromJSON(metadataDict)!
                        }
                        else {
                            currentAsset.metadata = metadata as! String
                        }
                    }
                    
                    realm.addOrUpdate(currentAsset)
                    do {
                        try realm.commitWriteTransaction()
                    } catch let error {
                        NSLog("Error saving issue: \(error)")
                    }
                    //realm.commitWriteTransaction()
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
                    let arr = assetIds.characters.split(separator: ",").map { String($0) }
                    for assetId in arr {
                        (delegate as! IssueHandler).updateStatusDictionary("", issueId: articleGlobalId, url: "\(baseURL)media/\(assetId)", status: 2)
                    }
                }
            }
            
        }
    }
    
    //Delete all assets for a single article
    class func deleteAssetsFor(_ articleId: NSString) {
        let realm = RLMRealm.default()
        
        let predicate = NSPredicate(format: "articleId = %@", articleId)
        let results = Asset.objects(in: realm, with: predicate)
        
        //Iterate through the results and delete the files saved
        let fileManager = FileManager.default
        for asset in results {
            let assetDetails = asset as! Asset
            let originalURL = assetDetails.getAssetPath()
            do {
                try fileManager.removeItem(atPath: originalURL!)
            } catch _ {
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
    class func deleteAssetsForArticles(_ articles: NSArray) {
        let realm = RLMRealm.default()
        
        let predicate = NSPredicate(format: "articleId IN %@", articles)
        let results = Asset.objects(in: realm, with: predicate)
        
        //Iterate through the results and delete the files saved
        let fileManager = FileManager.default
        for asset in results {
            let assetDetails = asset as! Asset
            let originalURL = assetDetails.getAssetPath()
            do {
                try fileManager.removeItem(atPath: originalURL!)
            } catch _ {
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
    class func deleteAssetsForIssues(_ issues: NSArray) {
        let realm = RLMRealm.default()
        
        let predicate = NSPredicate(format: "issue.globalId IN %@", issues)
        let results = Asset.objects(in: realm, with: predicate)
        
        //Iterate through the results and delete the files saved
        let fileManager = FileManager.default
        for asset in results {
            let assetDetails = asset as! Asset
            let originalURL = assetDetails.getAssetPath()
            do {
                try fileManager.removeItem(atPath: originalURL!)
            } catch _ {
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
    class func deleteAssetsForIssue(_ globalId: NSString) {
        let realm = RLMRealm.default()
        
        let predicate = NSPredicate(format: "issue.globalId = %@", globalId)
        let results = Asset.objects(in: realm, with: predicate)
        
        //Iterate through the results and delete the files saved
        let fileManager = FileManager.default
        for asset in results {
            let assetDetails = asset as! Asset
            let originalURL = assetDetails.getAssetPath()
            do {
                try fileManager.removeItem(atPath: originalURL!)
            } catch _ {
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
    
    // MARK: Public methods
    
    /**
    This method lets you save an Asset object back to the database in case some changes are made to it
    
    :brief: Save an Asset to the database
    */
    open func saveAsset() {
        let realm = RLMRealm.default()
        
        realm.beginWriteTransaction()
        realm.addOrUpdate(self)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving asset: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    /**
    This method accepts the global id of an asset and deletes it from the database. The file for the asset is also deleted
    
    :brief: Delete a specific asset
    
    - parameter  assetId: The global id for the asset
    */
    open class func deleteAsset(_ assetId: NSString) {
        let realm = RLMRealm.default()
        
        let predicate = NSPredicate(format: "globalId = %@", assetId)
        let results = Asset.objects(in: realm, with: predicate)
        
        //Iterate through the results and delete the files saved
        let fileManager = FileManager.default
        for asset in results {
            let assetDetails = asset as! Asset
            let originalURL = assetDetails.getAssetPath()
            do {
                try fileManager.removeItem(atPath: originalURL!)
            } catch _ {
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
    open class func getFirstAssetFor(_ issueId: String, articleId: String, volumeId: String?) -> Asset? {
        _ = RLMRealm.default()
        
        if Helper.isNilOrEmpty(issueId) {
            if let vol = volumeId {
                let predicate = NSPredicate(format: "volumeId = %@ AND placement = 1 AND type = %@", vol, "image")
                let assets = Asset.objects(with: predicate)
                
                if assets.count > 0 {
                    return assets.firstObject() as? Asset
                }
            }
        }
        
        if issueId == "" {
            let predicate = NSPredicate(format: "articleId = %@ AND placement = 1 AND type = %@", articleId, "image")
            let assets = Asset.objects(with: predicate)
            
            if assets.count > 0 {
                return assets.firstObject() as? Asset
            }
        }
        else {
            let predicate = NSPredicate(format: "issue.globalId = %@ AND articleId = %@ AND placement = 1 AND type = %@", issueId, articleId, "image")
            let assets = Asset.objects(with: predicate)
        
            if assets.count > 0 {
                return assets.firstObject() as? Asset
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
    open class func getNumberOfAssetsFor(_ issueId: String, articleId: String, volumeId: String?) -> UInt {
        _ = RLMRealm.default()
        
        if Helper.isNilOrEmpty(issueId) {
            if let vol = volumeId {
                let predicate = NSPredicate(format: "volumeId = %@", vol)
                let assets = Asset.objects(with: predicate)
                
                if assets.count > 0 {
                    lLog("\(assets.count)")
                    return assets.count
                }
            }
        }
        
        let predicate = NSPredicate(format: "issue.globalId = %@ AND articleId = %@", issueId, articleId)
        let assets = Asset.objects(with: predicate)
        
        if assets.count > 0 {
            lLog("\(assets.count)")
            return assets.count
        }
        
        return 0
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
    open class func getAssetsFor(_ issueId: String, articleId: String, volumeId: String?, type: String?) -> Array<Asset>? {
        _ = RLMRealm.default()
        
        var subPredicates = Array<NSPredicate>()

        if !Helper.isNilOrEmpty(volumeId) {
            if let vol = volumeId {
                let predicate = NSPredicate(format: "volumeId = %@", vol)
                subPredicates.append(predicate)
            }
        }
        
        let predicate = NSPredicate(format: "issue.globalId = %@ AND articleId = %@", issueId, articleId)
        subPredicates.append(predicate)

        if type != nil {
            let assetPredicate = NSPredicate(format: "type = %@", type!)
            subPredicates.append(assetPredicate)
        }
        
        let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
        //let searchPredicate = NSCompoundPredicate.andPredicateWithSubpredicates(subPredicates as [NSPredicate])
        let assets: RLMResults = Asset.objects(with: searchPredicate) as RLMResults
        
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
    
    - parameter  assetId: The global id for the asset
    
    :return: asset object for the global id. Returns nil if the asset is not found
    */
    open class func getAsset(_ assetId: String) -> Asset? {
        _ = RLMRealm.default()
        lLog("\(assetId)")
        
        let predicate = NSPredicate(format: "globalId = %@", assetId)
        let assets = Asset.objects(with: predicate)
        
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
    open class func getPlaylistFor(_ issueId: String, articleId: String) -> Array<Asset>? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "issue.globalId = %@ AND articleId = %@ AND type = %@", issueId, articleId, "sound")
        let assets = Asset.objects(with: predicate)
        
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
    open func getAssetPath() -> String? {
        let fileURL = self.originalURL
        if !Helper.isNilOrEmpty(fileURL) {
            var assetFolder = self.issue.assetFolder
            if Helper.isNilOrEmpty(assetFolder) {
                _ = RLMRealm.default()
                
                let predicate = NSPredicate(format: "globalId = %@", volumeId)
                let volumes = Volume.objects(with: predicate)
                
                if volumes.count > 0 {
                    let volume: Volume = volumes.firstObject() as! Volume
                    assetFolder = volume.assetFolder
                }
            }
            if Helper.isNilOrEmpty(assetFolder) {
                assetFolder = "/Documents"
            }
            
            if !Helper.isNilOrEmpty(assetFolder) {
                //Found the asset folder. Get the file now
                var folderPath = assetFolder
                if assetFolder.hasPrefix("/Documents") {
                    var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                    let docsDir: NSString = docPaths[0] as NSString
                    folderPath = assetFolder.replacingOccurrences(of: "/Documents", with: docsDir as String)
                }
                
                if !folderPath.hasSuffix("/") {
                    //Add the trailing slash
                    folderPath = "\(folderPath)/"
                }
                let filePath = "\(folderPath)\(fileURL)"
                lLog("\(filePath) for \(self.globalId)")
                return filePath
            }
        }
        return nil
    }
    
    /**
    This method returns the value for a specific key from the custom metadata of the asset
    
    :return: an object for the key from the custom metadata (or nil)
    */
    open func getValue(_ key: NSString) -> AnyObject? {
        
        let testAsset = Asset()
        let properties: NSArray = testAsset.objectSchema.properties as NSArray
        
        var foundProperty = false
        for property: RLMProperty in properties as! [RLMProperty] {
            let propertyName = property.name
            if propertyName == key as String {
                //This is the property we are looking for
                foundProperty = true
                break
            }
        }
        if (foundProperty) {
            //Get value of this property and return
            return self.value(forKey: key as String) as AnyObject?
        }
        else {
            //This is a metadata key
            let metadata: AnyObject? = Helper.jsonFromString(self.metadata)
            if let metadataDict = metadata as? NSDictionary {
                return metadataDict.value(forKey: key as String) as AnyObject?
            }
        }
        
        return nil
    }
}
