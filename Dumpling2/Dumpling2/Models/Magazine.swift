//
//  Magazine.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
//import Realm

//Magazine object
class Magazine: RLMObject {
    dynamic var name = ""
    dynamic var type = ""
    
    //Required for backward compatibility when upgrading to V 0.96.2
    override class func requiredProperties() -> Array<String> {
        return ["type", "name"]
    }
}
