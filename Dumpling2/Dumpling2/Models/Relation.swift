//
//  Relation.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 02/05/16.
//  Copyright © 2016 29th Street. All rights reserved.
//

import UIKit

/** A model object for Issue */
class Relation: RLMObject {
    /// Global id of an issue
    dynamic var issueId = ""
    /// Global id of an article
    dynamic var articleId = ""
    /// Global id of an asset
    dynamic var assetId = ""
    
    
    // MARK: Get association
    
    class func getArticlesForIssue(issueId: String) -> [String] {
        _ = RLMRealm.defaultRealm()
        
        var articles: RLMResults
        let predicate = NSPredicate(format: "issueId = %@ AND articleId != %@ AND assetId == %@", issueId, "", "")
        articles = Relation.objectsWithPredicate(predicate)
        
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
    
    class func getAssetsForIssue(issueId: String) -> [String] {
        _ = RLMRealm.defaultRealm()
        
        var assets: RLMResults
        let predicate = NSPredicate(format: "issueId = %@ AND articleId == %@ AND assetId != %@", issueId, "", "")
        assets = Relation.objectsWithPredicate(predicate)
        
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
    
    class func getAssetsForIssue(issueId: String, articleId: String) -> [String] {
        _ = RLMRealm.defaultRealm()
        
        var assets: RLMResults
        let predicate = NSPredicate(format: "issueId = %@ AND articleId = %@ AND assetId != %@", issueId, articleId, "")
        assets = Relation.objectsWithPredicate(predicate)
        
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
    
    class func getAssetsForArticle(articleId: String) -> [String] {
        _ = RLMRealm.defaultRealm()
        
        var assets: RLMResults
        let predicate = NSPredicate(format: "articleId = %@ AND assetId != %@", articleId, "")
        assets = Relation.objectsWithPredicate(predicate)
        
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
    
    class func getIssuesForArticle(articleId: String) -> [String] {
        _ = RLMRealm.defaultRealm()
        
        var issues: RLMResults
        let predicate = NSPredicate(format: "articleId = %@ && issueId != %@", articleId, "")
        issues = Relation.objectsWithPredicate(predicate)
        
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
    
    class func getIssuesForAsset(assetId: String) -> [String] {
        _ = RLMRealm.defaultRealm()
        
        var issues: RLMResults
        let predicate = NSPredicate(format: "assetId = %@ && issueId != %@", assetId, "")
        issues = Relation.objectsWithPredicate(predicate)
        
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
    
    class func relationExistsFor(issueId: String?, articleId: String?, assetId: String?) -> Bool {
        _ = RLMRealm.defaultRealm()
        
        var results: RLMResults
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
            results = Relation.objectsWithPredicate(searchPredicate)
            
            if results.count > 0 {
                return true
            }
        }
        
        return false
    }
    
    class func findRelationFor(issueId: String?, articleId: String?, assetId: String?) -> Relation? {
        _ = RLMRealm.defaultRealm()
        
        var results: RLMResults
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
            results = Relation.objectsWithPredicate(searchPredicate)
            
            if results.count > 0 {
                return results.firstObject() as? Relation
            }
        }
        
        return nil
    }
    
    class func createRelation(issueId: String?, articleId: String?, assetId: String?) {
        if !relationExistsFor(issueId, articleId: articleId, assetId: assetId) {
            let realm = RLMRealm.defaultRealm()
            
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
            
            realm.beginWriteTransaction()
            realm.addObject(relation)
            do {
                try realm.commitWriteTransaction()
            } catch let error {
                NSLog("Error adding relation: \(error)")
            }
        }
    }
    
    class func removeRelation(issueId: String?, articleId: String?, assetId: String?) {
        if let relation = findRelationFor(issueId, articleId: articleId, assetId: assetId) {
            let realm = RLMRealm.defaultRealm()
            
            realm.beginWriteTransaction()
            realm.deleteObject(relation)
            do {
                try realm.commitWriteTransaction()
            } catch let error {
                NSLog("Error deleting relation: \(error)")
            }
        
        }
    }
    
    class func deleteRelations(issueId: [String]?, articleId: [String]?, assetId: [String]?) {
        let realm = RLMRealm.defaultRealm()
        
        var results: RLMResults
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
            results = Relation.objectsWithPredicate(searchPredicate)
            
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
            relations.append(relation)
        }
        if relations.count > 0 {
            let realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()
            realm.addObjects(relations)
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
            relations.append(relation)
        }
        if relations.count > 0 {
            let realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()
            realm.addObjects(relations)
            do {
                try realm.commitWriteTransaction()
            } catch let error {
                NSLog("Error adding asset relations: \(error)")
            }
        }
    }
}
