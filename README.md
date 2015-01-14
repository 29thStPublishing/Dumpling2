# Dumpling2

Hello there! Dumpling 2 is intended to be compiled into a framework as a client to [Magnet API](https://github.com/29thStPublishing/Magnet-API)

Currently in its PoC state, the project is set up as a navigation-based project.

Right now it parses through a zip file for an issue and adds all the data into a Realm database. Eventually it will interact with the Magnet API and any hard-codings will be removed.


### Classes

**Magazine** has the properties associated with a magazine object. This class is currently not used. This is a subclass of RLMObject.

**Issue** has the properties associated with an Issue. This is a subclass of RLMObject.

**Article** stores all the properties of an article (including the issue id) and has methods for creating an article, deleting all articles for an issue and finding out if an article is featured. This is a subclass of RLMObject.

**Asset** stores the proerties and details of an asset (sound or image) associated with an issue or an article. It has methods for creating an asset, deleting assets for an article, deleting assets for an issue and getting the cover asset for an article/issue. This is a subclass of RLMObject.

**IssueHandler** is the main class where all the action happens. The class takes in the Apple id of an issue (also the name of the zip file - available in the app bundle). It extracts the zip file and creates the Issue, Article and Asset objects necessary. The class also lets you get an issue from the database if one exists (search by Apple id)


### Usage

```
let appleId = "org.bomb.mag.issue.20150101"
var issueHandler = IssueHandler()
issueHandler.addIssueToRealm(appleId)
```

***Using a custom path for storing the unzipped Issue details and images as well as the realm database is in progress***
