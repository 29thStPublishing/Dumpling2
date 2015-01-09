//
//  Asset.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
import Realm

enum AssetType: String {
    case Photo = "photo"
    case Sound = "sound"
}
//Asset object
class Asset: RLMObject {
    dynamic var globalId = ""
    dynamic var caption = ""
    dynamic var source = ""
    dynamic var squareURL = ""
    dynamic var originalURL = ""
    dynamic var mainPortraitURL = ""
    dynamic var mainLandscapeURL = ""
    dynamic var iconURL = ""
    dynamic var metadata = ""
    dynamic var type = AssetType.Photo.rawValue //default to a photo
    dynamic var placement = 0
    dynamic var fullFolderPath = ""
    dynamic var articleId = "" //globalId of associated article
    dynamic var issue = Issue() //an asset can belong to an article or an issue
    
    override class func primaryKey() -> String {
        return "globalId"
    }
    
    //Add asset
    class func createAsset(asset: NSDictionary, issue: Issue, articleId: String, placement: Int) {
        createAsset(asset, issue: issue, articleId: articleId, sound: false, placement: placement)
    }
    
    //Add any asset (sound/image)
    class func createAsset(asset: NSDictionary, issue: Issue, articleId: String, sound: Bool, placement: Int) {
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
        
        if sound {
            currentAsset.type = AssetType.Sound.rawValue
        }
        else {
            currentAsset.type = AssetType.Photo.rawValue
        }
        
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
    
    //Retrieve asset
    class func getFirstAssetFor(issueId: String, articleId: String) -> Asset? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issue.globalId = '%@' AND articleId = '%@' AND placement = 1", issueId, articleId)
        var assets = Asset.objectsWithPredicate(predicate)
        
        if assets.count > 0 {
            return assets.firstObject() as? Asset
        }
        
        return nil
    }
    
    //Delete all assets for a single article
    class func deleteAssetsFor(articleId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "articleId = '%@'", articleId)
        var results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
    
    
    //Delete all assets for multiple articles
    class func deleteAssetsForArticles(articles: NSArray) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "articleId IN %@", articles)
        var results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
    
    //Delete all assets for a single issue
    class func deleteAssetsForIssue(globalId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issue.globalId = '%@'", globalId)
        var results = Asset.objectsInRealm(realm, withPredicate: predicate)
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
}
