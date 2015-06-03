//
//  Purchase.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 06/05/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit

/** A model object for Purchases */
public class Purchase: RLMObject {
    /// Apple id/SKU of the purchase made - article or issue
    dynamic public var appleId = ""
    /// Global id of the purchase made - article, issue or volume
    dynamic public var globalId = ""
    /// Mode of purchase - Web (could be any - Stripe or any other), IAP
    dynamic public var mode = ""
    /// Type of purchase - article, issue or volume
    dynamic public var type = ""
    /// Purchase date
    dynamic public var purchaseDate = NSDate()
    /// Expiration date
    dynamic public var expirationDate = "" //Only used for subscriptions
    /// Identity used for syncing web purchases
    dynamic public var userIdentity = ""
    
}
