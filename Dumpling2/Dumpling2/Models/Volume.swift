//
//  Volume.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 25/05/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit

/** A model object for Volumes */
open class Volume: RLMObject {
    /// Global id of a volume - this is unique for each volume
    dynamic open var globalId = ""
    /// Title of the volume
    dynamic open var title = ""
    /// Subtitle of the volume
    dynamic open var subtitle = ""
    /// Description of the volume
    dynamic open var volumeDesc = ""
    /// Folder saving all the assets for the issue
    dynamic open var assetFolder = ""
    /// Global id of the asset which is the cover image of the issue
    dynamic open var coverImageId = "" //globalId of asset
    /// Publisher of the volume
    dynamic open var publisher = ""
    /// Published date for the volume
    dynamic open var publishedDate = Date()
    /// Release date for the volume
    dynamic open var releaseDate = ""
    /// Custom metadata of the volume
    dynamic open var metadata = ""
    /// Keywords for the volume
    dynamic open var keywords = ""
    /// Whether the volume is published or not
    dynamic open var published = false
    
    override open class func primaryKey() -> String {
        return "globalId"
    }
    
    //Required for backward compatibility when upgrading to V 0.96.2
    override open class func requiredProperties() -> Array<String> {
        return ["globalId", "title", "subtitle", "volumeDesc", "assetFolder", "coverImageId", "publisher", "publishedDate", "releaseDate", "metadata", "keywords", "published"]
    }
    
    // MARK: Public methods
    
    //MARK: Class methods
    
    /**
    This method uses the global id for a volume and deletes it from the database. All the volume's issues, assets, articles, issue assets, article assets are deleted from the database and the file system
    
    :brief: Delete a volume
    
    - parameter  globalId: The global id for the volume
    */
    open class func deleteVolume(_ globalId: NSString) {
        let realm = RLMRealm.default()
        
        let predicate = NSPredicate(format: "globalId = %@", globalId)
        let volume = Volume.objects(with: predicate)
        
        //Delete all issues, assets and articles for the volume
        if volume.count == 1 {
            //older issue
            let currentVolume = volume.firstObject() as! Volume
            //Delete all articles and assets if the issue already exists
            Issue.deleteIssuesForVolume(currentVolume.globalId as NSString)
            
            //Delete volume
            realm.beginWriteTransaction()
            realm.deleteObjects(currentVolume)
            do {
                try realm.commitWriteTransaction()
            } catch let error {
                NSLog("Error deleting volume: \(error)")
            }
            //realm.commitWriteTransaction()
        }
    }
    
    /**
    This method returns the Volume object for the most recent volume in the database (sorted by publish date)
    
    :brief: Find most recent volume
    
    :return:  Object for most recent volume
    */
    open class func getNewestVolume() -> Volume? {
        _ = RLMRealm.default()
        
        let results = Volume.allObjects().sortedResults(usingProperty: "publishedDate", ascending: false)
        
        if results.count > 0 {
            let newestVolume = results.firstObject() as! Volume
            return newestVolume
        }
        
        return nil
    }
    
    /**
    This method returns all volumes with specific keywords
    
    - parameter  keywords: An array of String values with keywords that the volume should have. If any of the keywords match, the volume will be selected
    
    :return: an array of volumes fulfiling the conditions
    */
    open class func searchVolumesWith(_ keywords: [String]) -> Array<Volume>? {
        _ = RLMRealm.default()
        
        var subPredicates = Array<NSPredicate>()
        
        for keyword in keywords {
            let subPredicate = NSPredicate(format: "keywords CONTAINS %@", keyword)
            subPredicates.append(subPredicate)
        }
        
        if subPredicates.count > 0 {
            let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: subPredicates)
            let volumes: RLMResults = Volume.objects(with: searchPredicate) as RLMResults
            
            if volumes.count > 0 {
                var array = Array<Volume>()
                for object in volumes {
                    let obj: Volume = object as! Volume
                    array.append(obj)
                }
                return array
            }
        }
        
        return nil
    }
    
    /**
    This method returns all volumes
    
    :return: an array of volumes
    */
    open class func getVolumes() -> Array<Volume>? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "published = %@", NSNumber(value: true as Bool))
        
        let volumes: RLMResults = Volume.objects(with: predicate)
        
        if volumes.count > 0 {
            var array = Array<Volume>()
            for object in volumes {
                let obj: Volume = object as! Volume
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    /**
    This method inputs the global id of a volume and returns the Volume object
    
    - parameter  volumeId: The global id for the volume
    
    :return: Volume object for the global id. Returns nil if the volume is not found
    */
    open class func getVolume(_ volumeId: String) -> Volume? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "globalId = %@", volumeId)
        let vols = Volume.objects(with: predicate)
        
        if vols.count > 0 {
            return vols.firstObject() as? Volume
        }
        
        return nil
    }
    
    //MARK: Instance methods
    
    /**
    This method saves a volume back to the database
    
    :brief: Save a volume to the database
    */
    open func saveVolume() {
        let realm = RLMRealm.default()
        
        realm.beginWriteTransaction()
        realm.addOrUpdate(self)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving volume: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    /**
    This method returns the value for a specific key from the custom metadata of the volume
    
    :brief: Get value for a specific key from custom meta of a volume
    
    :return: an object for the key from the custom metadata (or nil)
    */
    open func getValue(_ key: NSString) -> AnyObject? {
        
        let metadata: AnyObject? = Helper.jsonFromString(self.metadata)
        if let metadataDict = metadata as? NSDictionary {
            return metadataDict.value(forKey: key as String) as AnyObject?
        }
        
        return nil
    }
    
    /**
    This method returns all volumes whose publish date is older than the published date of current volume
    
    :brief: Get all volumes older than a specific volume
    
    :return: an array of volumes older than the current volume
    */
    open func getOlderVolumes() -> Array<Volume>? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "publishedDate < %@ AND published = %@", self.publishedDate as CVarArg, NSNumber(value: true as Bool))
        let volumes: RLMResults = Volume.objects(with: predicate) as RLMResults
        
        if volumes.count > 0 {
            var array = Array<Volume>()
            for object in volumes {
                let obj: Volume = object as! Volume
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    /**
    This method returns all volumes whose publish date is newer than the published date of current volume
    
    :brief: Get all volumes newer than a specific volume
    
    :return: an array of volumes newer than the current volume
    */
    open func getNewerVolumes() -> Array<Volume>? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "publishedDate > %@ AND published = %@", self.publishedDate as CVarArg, NSNumber(value: true as Bool))
        let volumes: RLMResults = Volume.objects(with: predicate) as RLMResults
        
        if volumes.count > 0 {
            var array = Array<Volume>()
            for object in volumes {
                let obj: Volume = object as! Volume
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
}
