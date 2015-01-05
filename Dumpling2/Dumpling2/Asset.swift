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
    dynamic var caption = ""
    dynamic var source = ""
    dynamic var squareURL = ""
    dynamic var originalURL = ""
    dynamic var mainPortraitURL = ""
    dynamic var mainLandscapeURL = ""
    dynamic var iconURL = ""
    dynamic var globalId = ""
    dynamic var type = AssetType.Photo.rawValue //default to a photo
    dynamic var placement = 0
    dynamic var fullFolderPath = ""
    dynamic var article = Article()
    dynamic var issue = Issue() //an asset can belong to an article or an issue
}
