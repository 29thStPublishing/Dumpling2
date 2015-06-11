//
//  AccessControl.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 11/05/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit
import StoreKit

/** A protocol for managing access control to various purchases*/
public protocol AccessControl {
    
    /**
    This method makes an in-app purchase and calls the Subscriber API to verify if the purchase receipt is valid or not. If valid, the content is unlocked and made available to the user
    
    :param: object Object which has to be purchased. Can be an Article, Volume or Issue object
    */
    func purchaseItem(object: AnyObject)
    
    /**
    This method restores all in-app purchases for the current logged in user. If any issues purchased are not available, they will be downloaded, saved to the database and made available. This method checks both in-app purchases as well as web purchases (if userId is not nil)
    
    :brief: Restore IAPs, save to database
    
    :param: userId User id for which web purchases should be checked. This param is optional. If nil, web purchases will not be checked for
    */
    func restorePurchases(userId: AnyObject?)
    
    /**
    This method retrieves all web purchases for the user whose id is passed. If any issues purchased are not available, they will be downloaded, saved to the database and made available
    
    :brief: Retrieve web purchases, save to database
    
    :param: userId User id for which web purchases should be checked
    */
    func restoreWebPurchases(userId: AnyObject)
    
    /**
    This method checks if a user has access to a given issue (based on Apple id/SKU). If the userId is provided, the app will check for access permissions through both in-app purchase and web purchases. Otherwise it will only check against in-app purchases
    
    :brief: Check if user has access to a specific issue/article
    
    :param: appleId SKU for which access needs to be checked
    
    :param: userId User id for which web purchase should be checked
    */
    func isAvailable(appleId: String, userId: AnyObject?)
    
    /**
    This method returns an array of skus for Purchases made by the current logged in user (or IAPs + web purchases if userId is not nil)
    
    :param: userId User id for which purchases should be retrieved
    
    :return: Array of SKUs which the user has access to
    */
    func listPurchases(userId: AnyObject?) -> Array<String>?
    
    /**
    This method syncs all purchases saved in the database to the server for given user identity. All purchases which do not have a user id (i.e. have been purchased on the device through IAPs) will also be marked as purchased by this user on the server
    
    :param: userId User id for which purchases should be synced with the server
    */
    func syncPurchases(userId: AnyObject)
    
}
