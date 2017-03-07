//
//  VolumeHandler.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 25/05/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import Foundation

/** Starter class which adds volumes to the database */
open class VolumeHandler: NSObject {
    
    var defaultFolder: NSString!
    /// Instance of IssueHandler class
    open var issueHandler: IssueHandler!
    
    // MARK: Initializers
    
    /**
    Initializes the VolumeHandler with the given folder. This is where the database and assets will be saved. The method expects to find a key `ClientKey` in the project's Info.plist with your client key. If none is found, the method returns a nil
    
    :brief: Initializer object
    
    - parameter folder: The folder where the database and downloaded assets should be saved
    */
    public init?(folder: NSString){
        super.init()
        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            let folderPath = folder.replacingOccurrences(of: docsDir as String, with: "/Documents")
            self.defaultFolder = folderPath as NSString!
        }
        else {
            self.defaultFolder = folder
        }
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.default()
        realmConfiguration.fileURL = NSURL.fileURL(withPath: defaultRealmPath)
        RLMRealmConfiguration.setDefault(realmConfiguration)
        //RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
        let mainBundle = Bundle.main
        if let key: String = mainBundle.object(forInfoDictionaryKey: "ClientKey") as? String {
            clientKey = key
            self.issueHandler = IssueHandler(folder: folder, clientkey: clientKey as NSString)
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
        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        self.defaultFolder = "/Documents"
        clientKey = clientKey as String
        self.issueHandler = IssueHandler(folder: docsDir, clientkey: clientKey as NSString)
        
        let defaultRealmPath = "\(docsDir)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.default()
        realmConfiguration.fileURL = NSURL.fileURL(withPath: defaultRealmPath)
        RLMRealmConfiguration.setDefault(realmConfiguration)
        //RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
    }
    
    /**
    Initializes the VolumeHandler with a custom directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API
    
    :brief: Initializer object
    
    - parameter folder: The folder where the database and downloaded assets should be saved
    
    - parameter clientkey: Client API key to be used for making calls to the Magnet API
    */
    public init(folder: NSString, clientkey: NSString) {
        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            let folderPath = folder.replacingOccurrences(of: docsDir as String, with: "/Documents")
            self.defaultFolder = folderPath as NSString!
        }
        else {
            self.defaultFolder = folder
        }
        
        clientKey = clientkey as String
        
        self.issueHandler = IssueHandler(folder: folder, clientkey: clientKey as NSString)
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.default()
        realmConfiguration.fileURL = NSURL.fileURL(withPath: defaultRealmPath)
        RLMRealmConfiguration.setDefault(realmConfiguration)
    }
    
    /**
    Find current schema version
    
    :return: the current schema version for the database
    */
    open class func getCurrentSchemaVersion() -> UInt64 {
        var currentSchemaVersion: UInt64 = 0
        do {
            currentSchemaVersion = try RLMRealm.schemaVersion(at: RLMRealmConfiguration.default().fileURL!)
        } catch {}
        
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
    open func addVolumeFromAPI(_ globalId: String) {
        let requestURL = "\(baseURL)volumes/\(globalId)"
        
        //self.issueHandler.updateStatusDictionary(nil, issueId: globalId, url: requestURL, status: 0)
        self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(value: false as Bool) , forKey: requestURL as NSCopying), forKey: globalId as NSCopying)
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allVolumes: NSArray = response.value(forKey: "volumes") as! NSArray
                let volumeDetails: NSDictionary = allVolumes.firstObject as! NSDictionary
                //Update volume now
                self.updateVolumeFromAPI(volumeDetails, globalId: volumeDetails.object(forKey: "id") as! String)
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
    open func addVolumeFor(_ appleId: String) {
        
        let requestURL = "\(baseURL)volumes/sku/\(appleId)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allVolumes: NSArray = response.value(forKey: "volumes") as! NSArray
                let volumeDetails: NSDictionary = allVolumes.firstObject as! NSDictionary
                
                //Update volume now
                let volumeId = volumeDetails.object(forKey: "id") as! String
                
                //self.issueHandler.updateStatusDictionary(nil, issueId: volumeId, url: requestURL, status: 0)
                self.issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(value: false as Bool) , forKey: requestURL as NSCopying), forKey: volumeId as NSCopying)
                self.updateVolumeFromAPI(volumeDetails, globalId: volumeId)
            }
            else if let err = error {
                print("Error: " + err.description)
            }
        }
    }
    
    // MARK: Add/Update Volumes, Issues, Assets and Articles
    
    //Add or create volume details (from API)
    func updateVolumeFromAPI(_ volume: NSDictionary, globalId: String) -> Int {
        let realm = RLMRealm.default()
        let results = Volume.objects(where: "globalId = '\(globalId)'")
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
        currentVolume.title = volume.value(forKey: "title") as! String
        currentVolume.subtitle = volume.value(forKey: "subtitle") as! String
        currentVolume.volumeDesc = volume.value(forKey: "description") as! String
        
        let meta = volume.value(forKey: "meta") as! NSDictionary
        currentVolume.releaseDate = meta.value(forKey: "releaseDate") as! String
        if let pubDate = meta.value(forKey: "publishedDate") as? String {
            currentVolume.publishedDate = Helper.publishedDateFromISO(pubDate)
        }
        if let publishedVal = meta.value(forKey: "published") as? NSNumber {
            currentVolume.published = publishedVal.boolValue
        }
        currentVolume.publisher = meta.value(forKey: "publishedBy") as! String
        
        let keywords = volume.object(forKey: "keywords") as! NSArray
        if keywords.count > 0 {
            currentVolume.keywords = Helper.stringFromJSON(keywords)!
        }
        
        currentVolume.assetFolder = "\(self.defaultFolder)/\(currentVolume.globalId)"
        
        var folderPath: String
        if self.defaultFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            folderPath = currentVolume.assetFolder.replacingOccurrences(of: "/Documents", with: docsDir as String)
        }
        else {
            folderPath = currentVolume.assetFolder
        }
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: folderPath, isDirectory: &isDir) {
            if isDir.boolValue {
                //Folder already exists. Do nothing
            }
        }
        else {
            do {
                //Folder doesn't exist, create folder where assets will be downloaded
                try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
        }
        
        let assetId = volume.value(forKey: "featuredImage") as! String
        if !assetId.isEmpty {
            currentVolume.coverImageId = assetId
        }
        
        if let metadata: AnyObject = volume.object(forKey: "customMeta") as AnyObject? {
            if metadata is NSDictionary {
                currentVolume.metadata = Helper.stringFromJSON(metadata)!
            }
            else {
                currentVolume.metadata = metadata as! String
            }
        }
        
        realm.addOrUpdate(currentVolume)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving volume details: \(error)")
        }
        //realm.commitWriteTransaction()
        
        //Add all assets of the volume (which do not have an associated issue/article)
        let volumeMedia = volume.object(forKey: "media") as! NSArray
        if volumeMedia.count > 0 {
            for (index, assetDict) in volumeMedia.enumerated() {
                //Download images and create Asset object for volume
                //Add asset to Volume dictionary
                let assetid = (assetDict as AnyObject).value(forKey: "id") as! NSString
                self.issueHandler.updateStatusDictionary(globalId, issueId: "", url: "\(baseURL)media/\(assetid)", status: 0)
                Asset.downloadAndCreateVolumeAsset(assetid, volume: currentVolume, placement: index+1, delegate: self.issueHandler)
            }
        }
        
        //add all issues into the database
        let issues = volume.object(forKey: "issues") as! NSArray
        for (_, issueDict) in issues.enumerated() {
            //Insert issue
            //Add issue to dictionary
            let issueId: String = (issueDict as AnyObject).value(forKey: "id") as! String
            self.issueHandler.addIssueFromAPI(issueId, volumeId: currentVolume.globalId, withArticles: true)
        }
        
        //Mark volume URL as done
        self.issueHandler.updateStatusDictionary(globalId, issueId: "", url: "\(baseURL)volumes/\(globalId)", status: 1)
        
        return 0
    }
    
    /**
    This method gets last 20 volumes for a client key, downloads it and saves it to the database
    */
    open func addAllVolumes() {
        let requestURL = "\(baseURL)volumes?limit=20"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allVolumes: NSArray = response.value(forKey: "volumes") as! NSArray
                if allVolumes.count > 0 {
                    for (_, volumeDict) in allVolumes.enumerated() {
                        let volumeDictionary = volumeDict as! NSDictionary
                        let volumeId = volumeDictionary.value(forKey: "id") as! String
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
    open func addAllVolumes(_ page: Int, limit: Int) {
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
                let allVolumes: NSArray = response.value(forKey: "volumes") as! NSArray
                if allVolumes.count > 0 {
                    for (_, volumeDict) in allVolumes.enumerated() {
                        let volumeDictionary = volumeDict as! NSDictionary
                        let volumeId = volumeDictionary.value(forKey: "id") as! String
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
    open func getVolume(_ volumeId: NSString) -> Volume? {
        
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "globalId = %@", volumeId)
        let volumes = Volume.objects(with: predicate)
        
        if volumes.count > 0 {
            return volumes.firstObject() as? Volume
        }
        
        return nil
    }
    
    open func listVolumes() {
        
        let requestURL = "\(baseURL)volumes"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.value(forKey: "volumes") as! NSArray
                print("VOLUMES: \(allIssues)")
            }
            else if let err = error {
                print("Error: " + err.description)
            }
            
        }
    }
    
}
