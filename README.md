# Dumpling2

Hello there! Dumpling 2 is intended to be compiled into a framework as a client to [Magnet API](https://github.com/29thStPublishing/Magnet-API)

The project has 2 targets - the **Dumpling2** target (the framework) and a **D2consumer** target (which will use the framework)

Right now it parses through a zip file for an issue and adds all the data into a Realm database. The interaction with Magent API is in progress.

### Dependencies

1. The Dumpling2 framework looks for **AFNetworking** libraries for making calls to the Magnet API. We had initially intended to use Cocoapods, but they don't work with frameworks. So have included AFNetworking source files into the framework
2. Dumpling2 uses Realm as the database. The Realm library and headers are included directly inside the framework so publishers do not have to include it separately
3. Dumpling2 uses ZipArchive for unarchiving zip files. The ZipArchive .a and header file are included in the project


### Classes

**Magazine** has the properties associated with a magazine object. This class is currently not used. This is a subclass of RLMObject.

**Issue** has the properties associated with an Issue. This is a subclass of RLMObject.

**Article** stores all the properties of an article (including the issue id) and has methods for creating an article, deleting all articles for an issue and finding out if an article is featured. This is a subclass of RLMObject.

**Asset** stores the proerties and details of an asset (sound or image) associated with an issue or an article. It has methods for creating an asset, deleting assets for an article, deleting assets for an issue and getting the cover asset for an article/issue. This is a subclass of RLMObject.

**IssueHandler** is the main class where all the action happens. The class takes in the Apple id of an issue (also the name of the zip file - available in the app bundle). It extracts the zip file and creates the Issue, Article and Asset objects necessary. The class also lets you get an issue from the database if one exists (search by Apple id)

It provides a default convenience initializer. Optionally you can specify a folder where all assets and the database should be stored and an API key for usage


### Usage

```
//For zipped files
let appleId = "org.bomb.mag.issue.20150101"
var issueHandler = IssueHandler()
issueHandler.addIssueZip(appleId)

//For issues from API
issueHandler.addIssueFromAPI("54c829c639cc76043772948d")
```

### Other points

1. To check whether data was inserted into Realm properly or not, you can use Realm browser. The browser can be found in their [release zip](http://static.realm.io/downloads/cocoa/latest) under browser/. Open the Documents directory for your app on Simulator. You will find the Realm database here (if you have not specified a different folder path when initializing IssueHandler). Open the database with Realm browser and you can browse throguh all the data
2. To see how the framework can be used for adding data to the database (using a zip or from the API), compile and run the D2consumer target
3. To see how the framework can be used for reading data from the database, compile and run the D2Reader target

**NOTE** - D2Reader and D2consumer will only be able to work (and share the Realm database) if they have App Sharing turned on and you use a folder name shared by both when creating IssueHandler object. For that you will need an app id with App Groups enabled and set the app group in Capabilities for both D2consumer and D2Reader. Without these, you will have to use the "Read" call from within the Consumer target.


*The Documents directory is here ~/Library/Developer/CoreSimulator/Devices/Your_simulator_UDID/data/Containers/Data/Application/Your_app_UDID/Documents