//
//  VolumeHandler.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 25/05/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import Foundation

/** Starter class which adds volumes to the database */
public class VolumeHandler: NSObject {
    
    var defaultFolder: NSString!
    /// Instance of IssueHandler class
    public var issueHandler: IssueHandler!
    
    // MARK: Initializers
    
    /**
    Initializes the VolumeHandler with the given folder. This is where the database and assets will be saved. The method expects to find a key `ClientKey` in the project's Info.plist with your client key. If none is found, the method returns a nil
    
    :brief: Initializer object
    
    - parameter folder: The folder where the database and downloaded assets should be saved
    */
    public init?(folder: NSString){
        super.init()
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            let folderPath = folder.stringByReplacingOccurrencesOfString(docsDir as String, withString: "/Documents")
            self.defaultFolder = folderPath
        }
        else {
            self.defaultFolder = folder
        }
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        //RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
        let mainBundle = NSBundle.mainBundle()
        if let key: String = mainBundle.objectForInfoDictionaryKey("ClientKey") as? String {
            clientKey = key
            self.issueHandler = IssueHandler(folder: folder, clientkey: clientKey)
        }
        else {
            return nil
        }
    }
    
    /**
    Initializes the VolumeHandler with the Documents directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
    :brief: Initializer object
    
    - parameter clientkey: Client API key to be used for making calls to the Magnet API
    */
    public init(clientkey: NSString) {
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        self.defaultFolder = "/Documents"
        clientKey = clientKey as String
        self.issueHandler = IssueHandler(folder: docsDir, clientkey: clientKey)
        
        let defaultRealmPath = "\(docsDir)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        //RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
    }
    
    /**
    Initializes the VolumeHandler with a custom directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
    :brief: Initializer object
    
    - parameter folder: The folder where the database and downloaded assets should be saved
    
    - parameter clientkey: Client API key to be used for making calls to the Magnet API
    */
    public init(folder: NSString, clientkey: NSString) {
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            let folderPath = folder.stringByReplacingOccurrencesOfString(docsDir as String, withString: "/Documents")
            self.defaultFolder = folderPath
        }
        else {
            self.defaultFolder = folder
        }
        
        clientKey = clientkey as String
        
        self.issueHandler = IssueHandler(folder: folder, clientkey: clientKey)
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
    }
    
    /**
    Find current schema version
    
    :return: the current schema version for the database
    */
    public class func getCurrentSchemaVersion() -> UInt64 {
        let currentSchemaVersion: UInt64 = RLMRealm.schemaVersionAtPath(RLMRealmConfiguration.defaultConfiguration().path!, error: nil)
        
        if currentSchemaVersion < 0 {
            return 0
        }
        
        return currentSchemaVersion
    }
    
    // MARK: Use API
    
    /**
    The method uses the global id of a volume, gets its content from the Magnet API and adds it to the database
    
    :brief: Get Volume details from API and add to database
    
    - parameter globalId: The global id for the volume
    */
    public func addVolumeFromAPI(globalId: String) {
        
        let requestURL = "\(baseURL)volumes/\(globalId)"
        
        self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: globalId)
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allVolumes: NSArray = response.valueForKey("volumes") as! NSArray
                let volumeDetails: NSDictionary = allVolumes.firstObject as! NSDictionary
                //Update volume now
                self.updateVolumeFromAPI(volumeDetails, globalId: volumeDetails.objectForKey("id") as! String)
            }
            else if let err = error {
                print("Error: " + err.description)
                self.issueHandler.updateStatusDictionary(globalId, issueId: "", url: requestURL, status: 2)
            }
        }
    }
    
    /**
    The method uses the SKU/Apple id of a volume, gets its content from the Magnet API and adds it to the database
    
    - parameter appleId: The Apple id for the volume
    */
    public func addVolumeFor(appleId: String) {
        
        let requestURL = "\(baseURL)volumes/sku/\(appleId)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allVolumes: NSArray = response.valueForKey("volumes") as! NSArray
                let volumeDetails: NSDictionary = allVolumes.firstObject as! NSDictionary
                
                //Update volume now
                let volumeId = volumeDetails.objectForKey("id") as! String
                
                self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: volumeId)
                self.updateVolumeFromAPI(volumeDetails, globalId: volumeId)
            }
            else if let err = error {
                print("Error: " + err.description)
            }
        }
    }
    
    // MARK: Add/Update Volumes, Issues, Assets and Articles
    
    //Add or create volume details (from API)
    func updateVolumeFromAPI(volume: NSDictionary, globalId: String) -> Int {
        let realm = RLMRealm.defaultRealm()
        let results = Volume.objectsWhere("globalId = '\(globalId)'")
        var currentVolume: Volume!
        
        if results.count > 0 {
            //older issue
            currentVolume = results.firstObject() as! Volume
            //Delete all issues, articles and assets if the volume already exists. Then add again
            //Issue.deleteIssuesForVolume(currentVolume.globalId)
        }
        else {
            //Create a new issue
            currentVolume = Volume()
            currentVolume.globalId = globalId
        }
        
        realm.beginWriteTransaction()
        currentVolume.title = volume.valueForKey("title") as! String
        currentVolume.subtitle = volume.valueForKey("subtitle") as! String
        currentVolume.volumeDesc = volume.valueForKey("description") as! String
        
        let meta = volume.valueForKey("meta") as! NSDictionary
        currentVolume.releaseDate = meta.valueForKey("releaseDate") as! String
        if let pubDate = meta.valueForKey("publishedDate") as? String {
            currentVolume.publishedDate = Helper.publishedDateFromISO(pubDate)
        }
        if let publishedVal = meta.valueForKey("published") as? NSNumber {
            currentVolume.published = publishedVal.boolValue
        }
        currentVolume.publisher = meta.valueForKey("publishedBy") as! String
        
        let keywords = volume.objectForKey("keywords") as! NSArray
        if keywords.count > 0 {
            currentVolume.keywords = Helper.stringFromJSON(keywords)!
        }
        
        currentVolume.assetFolder = "\(self.defaultFolder)" ///\(currentVolume.globalId)"
        
        var folderPath: String
        if self.defaultFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            folderPath = currentVolume.assetFolder.stringByReplacingOccurrencesOfString("/Documents", withString: docsDir as String)
        }
        else {
            folderPath = currentVolume.assetFolder
        }
        
        var isDir: ObjCBool = false
        if NSFileManager.defaultManager().fileExistsAtPath(folderPath, isDirectory: &isDir) {
            if isDir {
                //Folder already exists. Do nothing
            }
        }
        else {
            do {
                //Folder doesn't exist, create folder where assets will be downloaded
                try NSFileManager.defaultManager().createDirectoryAtPath(folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
        }
        
        let assetId = volume.valueForKey("featuredImage") as! String
        if !assetId.isEmpty {
            currentVolume.coverImageId = assetId
        }
        
        if let metadata: AnyObject = volume.objectForKey("customMeta") {
            if metadata.isKindOfClass(NSDictionary) {
                currentVolume.metadata = Helper.stringFromJSON(metadata)!
            }
            else {
                currentVolume.metadata = metadata as! String
            }
        }
        
        realm.addOrUpdateObject(currentVolume)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving volume details: \(error)")
        }
        //realm.commitWriteTransaction()
        
        //Add all assets of the volume (which do not have an associated issue/article)
        let volumeMedia = volume.objectForKey("media") as! NSArray
        if volumeMedia.count > 0 {
            for (index, assetDict) in volumeMedia.enumerate() {
                //Download images and create Asset object for volume
                //Add asset to Volume dictionary
                let assetid = assetDict.valueForKey("id") as! NSString
                self.issueHandler.updateStatusDictionary(globalId, issueId: "", url: "\(baseURL)media/\(assetid)", status: 0)
                Asset.downloadAndCreateVolumeAsset(assetid, volume: currentVolume, placement: index+1, delegate: self.issueHandler)
            }
        }
        
        //add all issues into the database
        let issues = volume.objectForKey("issues") as! NSArray
        for (_, issueDict) in issues.enumerate() {
            //Insert issue
            //Add issue to dictionary
            let issueId: String = issueDict.valueForKey("id") as! String
            self.issueHandler.addIssueFromAPI(issueId, volumeId: currentVolume.globalId, withArticles: true)
        }
        
        //Mark volume URL as done
        self.issueHandler.updateStatusDictionary(globalId, issueId: "", url: "\(baseURL)volumes/\(globalId)", status: 1)
        
        return 0
    }
    
    /**
    This method gets last 20 volumes for a client key, downloads it and saves it to the database
    */
    public func addAllVolumes() {
        let requestURL = "\(baseURL)volumes?limit=20"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allVolumes: NSArray = response.valueForKey("volumes") as! NSArray
                if allVolumes.count > 0 {
                    for (_, volumeDict) in allVolumes.enumerate() {
                        let volumeId = volumeDict.valueForKey("id") as! String
                        self.addVolumeFromAPI(volumeId)
                    }
                }
            }
            else if let err = error {
                print("Error: " + err.description)
            }
        }
    }
    
    /**
    This method gets all available volumes for a client key, downloads it and saves it to the database
    
    - parameter page: Page number of articles to fetch. Limit is set to 20. Pagination starts at 0
    
    - parameter limit: Parameter accepting the number of records to fetch at a time. If this is set to 0 or nil, we will fetch 20 records by default
    */
    public func addAllVolumes(page: Int, limit: Int) {
        var requestURL = "\(baseURL)volumes?limit="
        
        if limit > 0 {
            requestURL += "\(limit)"
        }
        else {
            requestURL += "20"
        }

        if page > 0 {
            requestURL = requestURL + "&page=\(page+1)"
        }
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allVolumes: NSArray = response.valueForKey("volumes") as! NSArray
                if allVolumes.count > 0 {
                    for (_, volumeDict) in allVolumes.enumerate() {
                        let volumeId = volumeDict.valueForKey("id") as! String
                        self.addVolumeFromAPI(volumeId)
                    }
                }
            }
            else if let err = error {
                print("Error: " + err.description)
            }
        }
    }
    
    /**
    Get volume details from database for a specific global id
    
    - parameter volumeId: global id of the volume
    
    :return: Volume object or nil if the volume is not in the database
    */
    public func getVolume(volumeId: NSString) -> Volume? {
        
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = %@", volumeId)
        let volumes = Volume.objectsWithPredicate(predicate)
        
        if volumes.count > 0 {
            return volumes.firstObject() as? Volume
        }
        
        return nil
    }
    
    public func listVolumes() {
        
        let requestURL = "\(baseURL)volumes"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.valueForKey("volumes") as! NSArray
                print("VOLUMES: \(allIssues)")
            }
            else if let err = error {
                print("Error: " + err.description)
            }
            
        }
    }
    
}