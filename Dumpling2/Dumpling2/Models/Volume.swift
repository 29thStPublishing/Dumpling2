//
//  Volume.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 25/05/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit

/** A model object for Volumes */
public class Volume: RLMObject {
    /// Global id of a volume - this is unique for each volume
    dynamic public var globalId = ""
    /// Title of the volume
    dynamic public var title = ""
    /// Subtitle of the volume
    dynamic public var subtitle = ""
    /// Description of the volume
    dynamic public var volumeDesc = ""
    /// Folder saving all the assets for the issue
    dynamic public var assetFolder = ""
    /// Global id of the asset which is the cover image of the issue
    dynamic public var coverImageId = "" //globalId of asset
    /// Publisher of the volume
    dynamic public var publisher = ""
    /// Published date for the volume
    dynamic public var publishedDate = NSDate()
    /// Release date for the volume
    dynamic public var releaseDate = ""
    /// Custom metadata of the volume
    dynamic public var metadata = ""
    /// Keywords for the volume
    dynamic public var keywords = ""
    /// Whether the volume is published or not
    dynamic public var published = false
    
    override public class func primaryKey() -> String {
        return "globalId"
    }
    
    // MARK: Public methods
    
    //MARK: Class methods
    
    /**
    This method uses the global id for a volume and deletes it from the database. All the volume's issues, assets, articles, issue assets, article assets are deleted from the database and the file system
    
    :brief: Delete a volume
    
    - parameter  globalId: The global id for the volume
    */
    public class func deleteVolume(globalId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = %@", globalId)
        let volume = Volume.objectsWithPredicate(predicate)
        
        //Delete all issues, assets and articles for the volume
        if volume.count == 1 {
            //older issue
            let currentVolume = volume.firstObject() as! Volume
            //Delete all articles and assets if the issue already exists
            Issue.deleteIssuesForVolume(currentVolume.globalId)
            
            //Delete volume
            realm.beginWriteTransaction()
            realm.deleteObjects(currentVolume)
            do {
                try realm.commitWriteTransaction()
            } catch let error {
                NSLog("Error deleting volume: \(error)")
            }
        }
    }
    
    /**
    This method returns the Volume object for the most recent volume in the database (sorted by publish date)
    
    :brief: Find most recent volume
    
    :return:  Object for most recent volume
    */
    public class func getNewestVolume() -> Volume? {
        _ = RLMRealm.defaultRealm()
        
        let results = Volume.allObjects().sortedResultsUsingProperty("publishedDate", ascending: false)
        
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
    public class func searchVolumesWith(keywords: [String]) -> Array<Volume>? {
        _ = RLMRealm.defaultRealm()
        
        var subPredicates = Array<NSPredicate>()
        
        for keyword in keywords {
            let subPredicate = NSPredicate(format: "keywords CONTAINS %@", keyword)
            subPredicates.append(subPredicate)
        }
        
        if subPredicates.count > 0 {
            let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: subPredicates)
            let volumes: RLMResults = Volume.objectsWithPredicate(searchPredicate) as RLMResults
            
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
    public class func getVolumes() -> Array<Volume>? {
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "published = %@", NSNumber(bool: true))
        
        let volumes: RLMResults = Volume.objectsWithPredicate(predicate)
        
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
    public class func getVolume(volumeId: String) -> Volume? {
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = %@", volumeId)
        let vols = Volume.objectsWithPredicate(predicate)
        
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
    public func saveVolume() {
        let realm = RLMRealm.defaultRealm()
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(self)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving volume: \(error)")
        }
    }
    
    /**
    This method returns the value for a specific key from the custom metadata of the volume
    
    :brief: Get value for a specific key from custom meta of a volume
    
    :return: an object for the key from the custom metadata (or nil)
    */
    public func getValue(key: NSString) -> AnyObject? {
        
        let metadata: AnyObject? = Helper.jsonFromString(self.metadata)
        if let metadataDict = metadata as? NSDictionary {
            return metadataDict.valueForKey(key as String)
        }
        
        return nil
    }
    
    /**
    This method returns all volumes whose publish date is older than the published date of current volume
    
    :brief: Get all volumes older than a specific volume
    
    :return: an array of volumes older than the current volume
    */
    public func getOlderVolumes() -> Array<Volume>? {
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "publishedDate < %@ AND published = %@", self.publishedDate, NSNumber(bool: true))
        let volumes: RLMResults = Volume.objectsWithPredicate(predicate) as RLMResults
        
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
    public func getNewerVolumes() -> Array<Volume>? {
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "publishedDate > %@ AND published = %@", self.publishedDate, NSNumber(bool: true))
        let volumes: RLMResults = Volume.objectsWithPredicate(predicate) as RLMResults
        
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
