//
//  Article.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
import Realm

//Article object
class Article: RLMObject {
    dynamic var globalId = ""
    dynamic var title = ""
    dynamic var articleDesc = "" //description
    dynamic var slug = ""
    dynamic var dek = ""
    dynamic var body = ""
    dynamic var permalink = "" //keeping URLs as string - we might need to append parts to get the final
    dynamic var url = ""
    dynamic var sourceURL = ""
    dynamic var authorName = ""
    dynamic var authorURL = ""
    dynamic var section = ""
    dynamic var articleType = ""
    dynamic var keywords = ""
    dynamic var commentary = ""
    dynamic var metadata = ""
    dynamic var versionStashed = ""
    dynamic var placement = 0
    dynamic var mainImageURL = ""
    dynamic var thumbImageURL = ""
    dynamic var isFeatured = false
    dynamic var issueId = "" //globalId of issue
    
    override class func primaryKey() -> String {
        return "globalId"
    }
    
    //Delete articles and assets for a specific issue
    class func deleteArticlesFor(globalId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issueId = '%@'", globalId)
        var articles = Article.objectsWithPredicate(predicate)
        
        var articleIds = NSMutableArray()
        //go through each article and delete all assets associated with it
        for article in articles {
            let article = article as Article
            articleIds.addObject(article.globalId)
        }
        
        Asset.deleteAssetsForIssue(globalId)
        Asset.deleteAssetsForArticles(articleIds)
        
        //Delete articles
        realm.beginWriteTransaction()
        realm.deleteObjects(articles)
        realm.commitWriteTransaction()
    }
    
    //Is article featured
    class func isArticleFeatured(issue: Issue, placement: Int) -> Bool{
        let globalId = issue.globalId
        //TODO: Needs to be implemented
        return false
    }

}
