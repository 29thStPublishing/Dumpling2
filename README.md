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

### Note for this release
Use this version of Dumpling2 **ONLY** for projects which are using Dumpling2 for the first time. **DO NOT** use them for apps which have used an older version of Dumpling2.


## Dependencies

1. The Dumpling2 framework looks for **AFNetworking** libraries for making calls to the Magnet API. We had initially intended to use Cocoapods, but they don't work with frameworks. So have included AFNetworking source files into the framework. The current Dumpling2 version as of September 2015 uses [AFNetworking v2.6.0](https://github.com/AFNetworking/AFNetworking/releases/tag/2.6.0)

2. Dumpling2 uses Realm as the database. The Realm library and headers are included directly inside the framework so publishers do not have to include it separately.
The current Dumpling2 version as of September 2015 uses [Realm v0.98.2](https://github.com/realm/realm-cocoa/releases/download/v0.98.2/realm-objc-0.98.2.zip)

3. Dumpling2 uses ZipArchive for unarchiving zip files. The ZipArchive .a and header file are included in the project

###Updating Realm in Dumpling2
1. To update Realm in Dumpling 2, download the relevant Obj-c package from the [Realm git repo](https://github.com/realm/realm-cocoa/releases/download/v0.98.2/realm-objc-0.98.2.zip)

2. From the Realm.framework **ios/static** folder, copy the `Headers`, `Modules`, `PrivateHeaders` and `Realm` executable in *Dumpling2/Dumpling2/Headers*. You must use the static directory, you cannot have one dynamic framework inside another.

3. Make sure *Realm* is added to *Linked Frameworks & Libraries* for Dumpling2 target

4. All the `.h` files added **should** have public access (can be checked in the File Inspector)

5. Change all references to `#import <Realm/file_name.h>` to `#import file_name.h`

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

## Building for iTunes Connect / Testflight
To build your app (using Dumpling2) for submission to iTunes Connect or for distribution via Testflight, we need to strip the fat framework to support just arm64 and armv7 (and remove i386 and x86_64 needed for running the app on simulators).

To do this, follow these steps

1. Add `Dumpling2.framework` in your project

2. In `Build Phases` for your project's target, add a new `Run Script` phase after `Embed Frameworks`

3. Add the following command to the `Run Script`
```
/bin/sh "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/Dumpling2.framework/strip-frameworks.sh"
```

## Logging
Dumpling2 prints logs in the console when running an app on a simulator or using a developer mobileprovision (on a device). You can disable logging in two ways

1. Run the app using an adhoc or App Store mobile provision on a device

2. Set an environment variable named `LLOG` with value = `1` for `Debug` configuration (under `Run`)

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
