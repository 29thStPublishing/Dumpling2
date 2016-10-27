//
//  Relation.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 02/05/16.
//  Copyright © 2016 29th Street. All rights reserved.
//

import UIKit

/** A model object for Issue */
open class Relation: RLMObject {
    /// Global id of an issue
    dynamic var issueId = ""
    /// Global id of an article
    dynamic var articleId = ""
    /// Global id of an asset
    dynamic var assetId = ""
    /// Placement of article in issue or asset in issue/article
    dynamic var placement = 0
    
    
    // MARK: Get association
    
    open class func getArticlesForIssue(_ issueId: String) -> [String] {
        _ = RLMRealm.default()
        
        var articles: RLMResults<RLMObject>
        let predicate = NSPredicate(format: "issueId = %@ AND articleId != %@ AND assetId == %@", issueId, "", "")
        articles = Relation.objects(with: predicate).sortedResults(usingProperty: "placement", ascending: true)
        
        if articles.count > 0 {
            var array = [String]()
            for object in articles {
                let obj: Relation = object as! Relation
                array.append(obj.articleId)
            }
            return array
        }
        
        return [String]()
    }
    
    class func getAssetsForIssue(_ issueId: String) -> [String] {
        _ = RLMRealm.default()
        
        var assets: RLMResults<RLMObject>
        let predicate = NSPredicate(format: "issueId = %@ AND articleId == %@ AND assetId != %@", issueId, "", "")
        assets = Relation.objects(with: predicate).sortedResults(usingProperty: "placement", ascending: true)
        
        if assets.count > 0 {
            var array = [String]()
            for object in assets {
                let obj: Relation = object as! Relation
                array.append(obj.assetId)
            }
            return array
        }
        
        return [String]()
    }
    
    class func assetExistsForIssue(_ issueId: String, assetId: String) -> Bool {
        _ = RLMRealm.default()
        
        var assets: RLMResults<RLMObject>
        let predicate = NSPredicate(format: "issueId = %@ AND articleId == %@ AND assetId = %@", issueId, "", assetId)
        assets = Relation.objects(with: predicate)
        
        if assets.count > 0 {
            return true
        }
        
        return false
    }
    
    class func getAssetsForIssue(_ issueId: String, articleId: String) -> [String] {
        _ = RLMRealm.default()
        
        var assets: RLMResults<RLMObject>
        let predicate = NSPredicate(format: "issueId = %@ AND articleId = %@ AND assetId != %@", issueId, articleId, "")
        assets = Relation.objects(with: predicate).sortedResults(usingProperty: "placement", ascending: true)
        
        if assets.count > 0 {
            var array = [String]()
            for object in assets {
                let obj: Relation = object as! Relation
                array.append(obj.assetId)
            }
            return array
        }
        
       return [String]()
    }
    
    class func getAssetsForIssue(_ issueId: String, articleId: String, placement: Int) -> String {
        _ = RLMRealm.default()
        
        var assets: RLMResults<RLMObject>
        let predicate = NSPredicate(format: "issueId = %@ AND articleId = %@ AND assetId != %@ AND placement = %d", issueId, articleId, "", placement)
        assets = Relation.objects(with: predicate)
        
        if assets.count > 0 {
            let obj: Relation = assets[0] as! Relation
            return obj.assetId
        }
        
        return ""
    }
    
    class func getAssetsForArticle(_ articleId: String) -> [String] {
        _ = RLMRealm.default()
        
        var assets: RLMResults<RLMObject>
        let predicate = NSPredicate(format: "articleId = %@ AND assetId != %@", articleId, "")
        assets = Relation.objects(with: predicate).sortedResults(usingProperty: "placement", ascending: true)
        
        if assets.count > 0 {
            var array = [String]()
            for object in assets {
                let obj: Relation = object as! Relation
                array.append(obj.assetId)
            }
            return array
        }
        
        return [String]()
    }
    
    class func assetExistsForArticle(_ articleId: String, assetId: String) -> Bool {
        _ = RLMRealm.default()
        
        var assets: RLMResults<RLMObject>
        let predicate = NSPredicate(format: "articleId = %@ AND assetId = %@", articleId, assetId)
        assets = Relation.objects(with: predicate)
        
        if assets.count > 0 {
            return true
        }
        
        return false
    }
    
    class func getAssetForArticle(_ articleId: String, placement: Int) -> String {
        _ = RLMRealm.default()
        
        var assets: RLMResults<RLMObject>
        let predicate = NSPredicate(format: "articleId = %@ AND assetId != %@ AND placement = %d", articleId, "", placement)
        assets = Relation.objects(with: predicate)
        
        if assets.count > 0 {
            let obj: Relation = assets[0] as! Relation
            return obj.assetId
        }
        
        return ""
    }
    
    class func getIssuesForArticle(_ articleId: String) -> [String] {
        _ = RLMRealm.default()
        
        var issues: RLMResults<RLMObject>
        let predicate = NSPredicate(format: "articleId = %@ && issueId != %@", articleId, "")
        issues = Relation.objects(with: predicate)
        
        if issues.count > 0 {
            var array = [String]()
            for object in issues {
                let obj: Relation = object as! Relation
                array.append(obj.issueId)
            }
            return array
        }
        
        return [String]()
    }
    
    class func getIssuesForAsset(_ assetId: String) -> [String] {
        _ = RLMRealm.default()
        
        var issues: RLMResults<RLMObject>
        let predicate = NSPredicate(format: "assetId = %@ && issueId != %@", assetId, "")
        issues = Relation.objects(with: predicate)
        
        if issues.count > 0 {
            var array = [String]()
            for object in issues {
                let obj: Relation = object as! Relation
                array.append(obj.issueId)
            }
            return array
        }
        
        return [""]
    }
    
    class func getArticlesForAsset(_ assetId: String) -> [String] {
        _ = RLMRealm.default()
        
        var articles: RLMResults<RLMObject>
        let predicate = NSPredicate(format: "assetId = %@ && articleId != %@", assetId, "")
        articles = Relation.objects(with: predicate)
        
        if articles.count > 0 {
            var array = [String]()
            for object in articles {
                let obj: Relation = object as! Relation
                array.append(obj.articleId)
            }
            return array
        }
        
        return [""]
    }
    
    class func relationExistsFor(_ issueId: String?, articleId: String?, assetId: String?) -> Bool {
        _ = RLMRealm.default()
        
        var results: RLMResults<RLMObject>
        var subPredicates = Array<NSPredicate>()
        
        if let issueId = issueId {
            let predicate = NSPredicate(format: "issueId = %@", issueId)
            subPredicates.append(predicate)
        }
        if let articleId = articleId {
            let predicate = NSPredicate(format: "articleId = %@", articleId)
            subPredicates.append(predicate)
        }
        if let assetId = assetId {
            let predicate = NSPredicate(format: "assetId = %@", assetId)
            subPredicates.append(predicate)
        }
        if issueId != nil && articleId != nil && assetId == nil {
            let predicate = NSPredicate(format: "assetId == %@", "")
            subPredicates.append(predicate)
        }
        if issueId != nil && assetId != nil && articleId == nil {
            let predicate = NSPredicate(format: "articleId == %@", "")
            subPredicates.append(predicate)
        }
        if articleId != nil && assetId != nil && issueId == nil {
            let predicate = NSPredicate(format: "issueId == %@", "")
            subPredicates.append(predicate)
        }
        
        if subPredicates.count > 0 {
            let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
            results = Relation.objects(with: searchPredicate)
            
            if results.count > 0 {
                return true
            }
        }
        
        return false
    }
    
    class func findRelationFor(_ issueId: String?, articleId: String?, assetId: String?) -> Relation? {
        _ = RLMRealm.default()
        
        var results: RLMResults<RLMObject>
        var subPredicates = Array<NSPredicate>()
        
        if let issueId = issueId {
            let predicate = NSPredicate(format: "issueId = %@", issueId)
            subPredicates.append(predicate)
        }
        if let articleId = articleId {
            let predicate = NSPredicate(format: "articleId = %@", articleId)
            subPredicates.append(predicate)
        }
        if let assetId = assetId {
            let predicate = NSPredicate(format: "assetId = %@", assetId)
            subPredicates.append(predicate)
        }
        if issueId != nil && articleId != nil && assetId == nil {
            let predicate = NSPredicate(format: "assetId == %@", "")
            subPredicates.append(predicate)
        }
        if issueId != nil && assetId != nil && articleId == nil {
            let predicate = NSPredicate(format: "articleId == %@", "")
            subPredicates.append(predicate)
        }
        if articleId != nil && assetId != nil && issueId == nil {
            let predicate = NSPredicate(format: "issueId == %@", "")
            subPredicates.append(predicate)
        }
        if subPredicates.count > 0 {
            let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
            results = Relation.objects(with: searchPredicate)
            
            if results.count > 0 {
                return results.firstObject() as? Relation
            }
        }
        
        return nil
    }
    
    class func createRelation(_ issueId: String?, articleId: String?, assetId: String?, placement: Int) {
        if let relation = findRelationFor(issueId, articleId: articleId, assetId: assetId) {
            if relation.placement != placement {
                removeRelation(issueId, articleId: articleId, assetId: assetId)
            }
        }
        if !relationExistsFor(issueId, articleId: articleId, assetId: assetId) {
            let realm = RLMRealm.default()
            
            let relation = Relation()
            if let issueId = issueId {
                relation.issueId = issueId
            }
            if let assetId = assetId {
                relation.assetId = assetId
            }
            if let articleId = articleId {
                relation.articleId = articleId
            }
            relation.placement = placement
            
            realm.beginWriteTransaction()
            realm.add(relation)
            do {
                try realm.commitWriteTransaction()
            } catch let error {
                NSLog("Error adding relation: \(error)")
            }
        }
    }
    
    class func removeRelation(_ issueId: String?, articleId: String?, assetId: String?) {
        if let relation = findRelationFor(issueId, articleId: articleId, assetId: assetId) {
            let realm = RLMRealm.default()
            
            realm.beginWriteTransaction()
            realm.delete(relation)
            do {
                try realm.commitWriteTransaction()
            } catch let error {
                NSLog("Error deleting relation: \(error)")
            }
        
        }
    }
    
    class func deleteRelations(_ issueId: [String]?, articleId: [String]?, assetId: [String]?) {
        let realm = RLMRealm.default()
        
        var results: RLMResults<RLMObject>
        var subPredicates = Array<NSPredicate>()
        
        if let issueId = issueId {
            let predicate = NSPredicate(format: "issueId IN %@", issueId)
            subPredicates.append(predicate)
        }
        if let articleId = articleId {
            let predicate = NSPredicate(format: "articleId IN %@", articleId)
            subPredicates.append(predicate)
        }
        if let assetId = assetId {
            let predicate = NSPredicate(format: "assetId IN %@", assetId)
            subPredicates.append(predicate)
        }
        if subPredicates.count > 0 {
            let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
            results = Relation.objects(with: searchPredicate)
            
            if results.count > 0 {
                realm.beginWriteTransaction()
                realm.deleteObjects(results)
                do {
                    try realm.commitWriteTransaction()
                } catch let error {
                    NSLog("Error deleting relations: \(error)")
                }
            }
        }
    }
    
    class func addAllArticles() {
        let articles = Article.allObjects()
        var relations = [Relation]()
        for article in articles {
            let article = article as! Article
            let relation = Relation()
            relation.articleId = article.globalId
            relation.issueId = article.issueId
            relation.placement = article.placement
            relations.append(relation)
        }
        if relations.count > 0 {
            let realm = RLMRealm.default()
            realm.beginWriteTransaction()
            realm.addObjects(relations as NSFastEnumeration)
            do {
                try realm.commitWriteTransaction()
            } catch let error {
                NSLog("Error adding article relations: \(error)")
            }
        }
    }
    
    class func addAllAssets() {
        let assets = Asset.allObjects()
        var relations = [Relation]()
        for asset in assets {
            let asset = asset as! Asset
            let relation = Relation()
            relation.articleId = asset.articleId
            relation.issueId = asset.issue.globalId
            relation.assetId = asset.globalId
            relation.placement = asset.placement
            relations.append(relation)
        }
        if relations.count > 0 {
            let realm = RLMRealm.default()
            realm.beginWriteTransaction()
            realm.addObjects(relations as NSFastEnumeration)
            do {
                try realm.commitWriteTransaction()
            } catch let error {
                NSLog("Error adding asset relations: \(error)")
            }
        }
    }
}
