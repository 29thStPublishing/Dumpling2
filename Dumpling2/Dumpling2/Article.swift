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
    dynamic var id = ""
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
    dynamic var placement = 0
    dynamic var mainImage = UIImage()
    dynamic var thumbImage = UIImage()
    dynamic var isFeatured = true
    dynamic var customValues = NSMutableDictionary()
    dynamic var issue = Issue()
}
