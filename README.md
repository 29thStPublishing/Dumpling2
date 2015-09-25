# Dumpling2

Hello there! Dumpling 2 is intended to be compiled into a framework as a client to [Magnet API](https://github.com/29thStPublishing/Magnet-API)

The framework lets you get an issue's details in 2 ways
1. Parse through a zip file for an issue (in the application bundle)
2. Get an issue id (or an individual article's id) and retrieve the information from Magnet

The information from both is added into a Realm database.

## Building Dumpling2

There are two targets which will be used with Dumpling2 - **Dumpling2** and **Dumpling-Universal**

1. If you wish to get a framework which can run on both phone and simulator, build the **Dumpling-Universal** target. In the build folder, under **Products** you will find 3 folders - one which has the framework for devices (*Debug-iphoneos*), one for simulators (*Debug-iphonesimulator*) and one which has the universal framework (*Debug-iphoneuniversal*).

2. To get a framework which works with just phones or just simulators, you can use the framework from the folders above

3. When submitting the app to the App Store or uploading to iTunes Connect for testing or submitting, use the framework from the Phone OS folder (*Debug-iphoneos*)

## Dependencies

1. The Dumpling2 framework looks for **AFNetworking** libraries for making calls to the Magnet API. We had initially intended to use Cocoapods, but they don't work with frameworks. So have included AFNetworking source files into the framework
2. Dumpling2 uses Realm as the database. The Realm library and headers are included directly inside the framework so publishers do not have to include it separately
3. Dumpling2 uses ZipArchive for unarchiving zip files. The ZipArchive .a and header file are included in the project


## Classes

**Volume** has the properties associated with a volume object. This is a subclass of RLMObject.

**Issue** has the properties associated with an Issue. This is a subclass of RLMObject.

**Article** stores all the properties of an article (including the issue id) and has methods for creating an article, deleting all articles for an issue and finding out if an article is featured. This is a subclass of RLMObject.

**Asset** stores the proerties and details of an asset (sound or image) associated with an issue or an article. It has methods for creating an asset, deleting assets for an article, deleting assets for an issue and getting the cover asset for an article/issue. This is a subclass of RLMObject.

**VolumeHandler** is the main class where all the action happens. The class takes in the global id of a volume, retrieves its data from the server and saves it to the database (issues, assets, articles)

You need to provide a client key for the API calls to work

**IssueHandler** is the class which deals with issues, their articles and assets. It also takes in the Apple id of an issue (also the name of the zip file - available in the app bundle), extracts the zip file and creates the Issue, Article and Asset objects necessary.

**ArticleHandler** is the class which deals with articles and their assets. It lets you retrieve paginated list of articles from the API and save to the database

**Helper** class stores the various functions used throughout the framework like finding the device type and resolution, getting string from date (and other way round), getting JSON object from string (and other way round). It also stores the constants in the project like the base URL for Magnet and notification names (for download completion)

**LRNetworkManager** is a singleton subclass of AFHTTPRequestOperationManager. All network operations should be through this file. It sends requests to the Magnet API and downloads data as well as files

**ReaderHelper** has methods to save reading status of articles (issue, current article or asset, reading position) and retrieve them


## Usage

```
//For zipped files
let appleId = "org.bomb.mag.issue.20150101"

var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
var docsDir: NSString = docPaths[0] as! NSString
        
var volumeHandler = VolumeHandler(folder: docsDir)

//This nil check is needed. The initializer might return a nil if it doesn't find 
//"ClientKey" in Info.plist
if volumeHandler != nil {
	//Issue from a ZIP
    volumeHandler.issueHandler.addIssueZip(appleId)

    //For volumes from API
    volumeHandler.addVolumeFromAPI("555a27de352c7d6d5b888c3e") //The volume's global id
}
```

## Additional notes

1. To check whether data was inserted into Realm properly or not, you can use Realm browser. The browser can be found in their [release zip](http://static.realm.io/downloads/cocoa/latest) under browser/. Open the Documents directory for your app on Simulator. You will find the Realm database here (if you have not specified a different folder path when initializing IssueHandler). Open the database with Realm browser and you can browse throguh all the data

2. If you wish to publish your issue on Newsstand, make sure your project's plist has the *UINewsstandApp* key with a *true* value. Make sure you add NewsstandKit.framework to your project

3. In order to use iCloud for syncing reading status, add CloudKit.framework to your project, turn on iCloud in the target's Capabilities section for Key-value storage. The sample project uses the default container for storing and retrieving values. If you wish to use a custom container, the code will change accordingly

4. If you turn on App Groups for multiple projects and instantiate **VolumeHandler**, **IssueHandler** and **ArticleHandler** with the appropriate folder, you can read the data across multiple apps. To do this, you will need an app id with App Groups enabled and set the app group in Capabilities for all projects sharing the data.


*The Documents directory is here ~/Library/Developer/CoreSimulator/Devices/Your_simulator_UDID/data/Containers/Data/Application/Your_app_UDID/Documents