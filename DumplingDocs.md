# Dumpling

Dumpling is a framework using which you can publish issues/articles as apps easily by connecting with the Magnet API or using the zip files created by Linechef.

The framework lets you get an issue's details in 2 ways

1. Parse through a zip file for an issue (in the application bundle)
2. Get an issue id (or an individual article's id) and retrieve the information from Magnet

Dumpling has been written with Swift 1.2 and is very easy to use and integrate. This short guide is to help you understand the usage of Dumpling in your projects and the methods available to you with the framework.

## Dependencies

1. The Dumpling framework looks for **AFNetworking** libraries for making calls to the Magnet API. AFNetworking is included as a part of the framework

2. Dumpling uses Realm as the database. The Realm library and headers are included directly inside the framework so publishers do not have to include it separately

3. Dumpling uses ZipArchive for unarchiving zip files. The ZipArchive .a and header file are included in the project


## VolumeHandler

This is the main class and the starting point of Dumpling

###Properties
1. **issueHandler** ```IssueHandler``` An instance of IssueHandler class - this uses the same folder and client key as the VolumeHandler


###Methods
1. **init(folder: NSString)** Initializes the VolumeHander with the given folder. This is where the database and assets will be saved

    **NOTE:** The initializer requires a Client key. If you wish to pass a client key to the initializer, use one of the below initializers. This method will look for a ```String``` with the key ```ClientKey``` in your project's **Info.plist**
```
<key>ClientKey</key>
<string>Your Key Here</string>
```

2. **init(clientkey: NSString)** Initializes the VolumeHandler with the Documents directory. This is where the database and assets will be saved. The key is used for making calls to the Magnet API

3. **init(folder: NSString, clientkey: NSString)** Initializes the VolumeHandler with a custom directory. This is where the database and assets will be saved. The key is your Client API key provided by 29.io

4. **getCurrentSchemaVersion()** ```returns UInt``` Find current schema version

5. **addVolumeFromAPI(globalId: NSString)** The method uses the global id of a volume, gets its content from the Magnet API and adds it to the database

6. **getVolume(volumeId: String)** ```returns Volume or nil``` Get volume details from database for a specific global id

7. **listVolumes()** The method is for testing only. It prints the available volumes for a client api key

8. **addAllVolumes()** This method gets all the volumes for a given client key and adds them to the database


## IssueHandler

This class handles adding issues to the database. If using a VolumeHandler, you do not need to initialize IssueHandler and can use the instance provided by VolumeHandler

###Methods
1. **init(folder: NSString)** Initializes the IssueHandler with the given folder. This is where the database and assets will be saved

    **NOTE:** The initializer requires a Client key. If you wish to pass a client key to the initializer, use one of the below initializers. This method will look for a ```String``` with the key ```ClientKey``` in your project's **Info.plist**
```
<key>ClientKey</key>
<string>Your Key Here</string>
```

2. **init(clientkey: NSString)** Initializes the IssueHandler with the Documents directory. This is where the database and assets will be saved. The key is used for making calls to the Magnet API

3. **init(folder: NSString, clientkey: NSString)** Initializes the IssueHandler with a custom directory. This is where the database and assets will be saved. The key is your Client API key provided by 29.io

4. **addIssueZip(appleId: NSString)** The method uses an Apple id, gets a zip file from the project Bundle with the name appleId.zip, extracts its contents and adds the issue, articles and assets to the database

5. **addIssueFromAPI(issueId: String, volumeId: String)** The method uses the global id of an issue, gets its content from the Magnet API and adds it to the database. The volume id is optional and if provided, saves the global id of the volume this issue is associated with

6. **listIssues()** The method is for testing only. It prints the available issues for a client api key

7. **searchIssueFor(appleId: String)** ```returns Issue or nil``` The method searches for an issue with a specific Apple ID. If the issue is not available in the database, the issue will be downloaded from the Magnet API and added to the DB

8. **getIssue(issueId: NSString)** ```returns Issue or nil``` Get issue details from database for a specific global id

9. **addIssueOnNewsstand(issueId: String)** Add issue on Newsstand

10. **getActiveDownloads()** ```returns NSArray``` Get issue ids whose download not complete yet


## ArticleHandler

This class created for managing independent articles

###Methods
1. **init(folder: NSString)** Initializes the ArticleHandler with the given folder. This is where the database and assets will be saved

    **NOTE:** The initializer requires a Client key. If you wish to pass a client key to the initializer, use one of the below initializers. This method will look for a ```String``` with the key ```ClientKey``` in your project's **Info.plist**
```
<key>ClientKey</key>
<string>Your Key Here</string>
```

2. **init(clientkey: NSString)** Initializes the ArticleHandler with the Documents directory. This is where the database and assets will be saved. The key is used for making calls to the Magnet API

3. **init(folder: NSString, clientkey: NSString)** Initializes the ArticleHandler with a custom directory. This is where the database and assets will be saved. The key is your Client API key provided by 29.io

4. **addArticleFromAPI(globalId: String)** The method uses the global id of an article, gets its content from the Magnet API and adds it to the database as an independent article

5. **addAllArticles()** Gets all the articles for a client key from the API and adds it to the database

7. **getAllArticles(page: Int, count: Int)** ```returns Array<Article> or nil``` The method returns a paginated list of independent articles from the database. If you need all articles, specify count as 0. The page index starts at 0


## Volume

Realm object for Volumes. Also has methods for directly dealing with volumes

###Properties
1. **globalId** ```String``` Global id of a volume - this is unique for each volume

2. **title** ```String``` Title of the volume

3. **subtitle** ```String``` Subtitle of the volume

4. **volumeDesc** ```String``` Description of the volume

5. **assetFolder** ```String``` Folder saving all the assets for the volume

6. **coverImageId** ```String``` Global id of the asset which is the cover image of the volume

7. **publisher** ```String``` Publisher of the volume

8. **publishedDate** ```NSDate``` Published date for the volume

9. **releaseDate** ```String``` Release date for the volume

10. **keywords** ```String``` Keywords for the volume (comma separated string)

11. **metadata** ```String``` Custom metadata of the volume (JSON string - dictionary)

12. **published** ```Bool``` Whether the volume is published or not

###Class methods (public)
1. **deleteVolume(globalId: NSString)** This method uses the global id for a volume and deletes it from the database. All the volume's issues articles, assets, issue assets and article assets are deleted from the database and the file system

2. **getNewestVolume()** ```returns Volume or nil``` This method returns the Volume object for the most recent volume in the database (sorted by publish date)

3. **searchVolumesWith(keywords: [String])** ```returns Array<Volume> or nil``` This method accepts an array of keywords and returns all volumes with specific keywords

4. **getVolumes()** ```returns Array<Volume> or nil``` This method returns all volumes

###Instance methods (public)
1. **getValue(key:)** ```returns AnyObject/id or nil``` This method returns the value for a specific key from the custom metadata of the volume

2. **saveVolume()** This method saves a volume back to the database

3. **getNewerVolumes()** ```returns Array<Issue>``` This method returns all volumes whose publish date is newer than the published date of current volume

4. **getOlderVolumes()** ```returns Array<Issue>``` This method returns all volumes whose publish date is older than the published date of current volume


## Issue

Realm object for Issues. Also has methods for directly dealing with issues

###Properties
1. **globalId** ```String``` Global id of an issue - this is unique for each issue

2. **appleId** ```String``` SKU or Apple Id for an issue

3. **title** ```String``` Title of the issue

4. **issueDesc** ```String``` Description of the issue

5. **assetFolder** ```String``` Folder saving all the assets for the issue

6. **coverImageId** ```String``` Global id of the asset which is the cover image of the issue

7. **iconImageURL** ```String``` File URL for the icon image

8. **publishedDate** ```NSDate``` Published date for the issue

9. **lastUpdateDate** ```String``` Last updated date for the issue

10. **displayDate** ```String``` Display date for an issue

11. **metadata** ```String``` Custom metadata of the issue (JSON string - dictionary)

12. **volumeId** ```String``` Global id of the volume to which the issue belongs (can be blank if this is an independent issue)

###Class methods (public)
1. **deleteIssue(appleId: NSString)** This method uses the SKU/Apple id for an issue and deletes it from the database. All the issue's articles, assets, article assets are deleted from the database and the file system

2. **getNewestIssue()** ```returns Issue or nil``` This method returns the Issue object for the most recent issue in the database (sorted by publish date)

3. **getIssueFor(appleId: String)** ```returns Issue or nil``` This method takes in an SKU/Apple id and returns the Issue object associated with it (or nil if not found in the database)

4. **getIssues(volumeId: String)** ```returns Array<Issue> or nil``` This method takes in the global id of a volume and returns all issues associated with it (or nil if not found in the database)

5. **getIssue(issueId: String)** ```returns Issue or nil``` This method takes in the global id of an issue and returns the Issue object associated with it (or nil if not found in the database)

###Instance methods (public)
1. **getValue(key:)** ```returns AnyObject/id or nil``` This method returns the value for a specific key from the custom metadata of the issue

2. **getOlderIssues()** ```returns Array<Issue>``` This method returns all issues whose publish date is older than the published date of current issue

3. **getNewerIssues()** ```returns Array<Issue>``` This method returns all issues whose publish date is newer than the published date of current issue

4. **saveIssue()** This method saves an issue back to the database


## Article

Realm object for Articles. Also has methods for directly dealing with articles

###Properties
1. **globalId** ```String``` Global id of an article - this is unique for each article 

2. **title** ```String``` Article title

3. **articleDesc** ```String``` Article description

4. **slug** ```String``` Article slug

5. **dek** ```String``` Article dek

6. **body** ```String``` Article content

7. **permalink** ```String``` Permanent link to the article

8. **url** ```String``` Article URL

9. **sourceURL** ```String``` URL to the article's source

10. **authorName** ```String``` Article author's name

11. **authorURL** ```String``` Link to the article author's profile

12. **section** ```String``` Section under which the article falls

13. **articleType** ```String``` Type of article

14. **keywords** ```String``` Keywords which the article falls under (comma separated string)

15. **commentary** ```String``` Article commentary

16. **date** ```NSDate``` Article published date

17. **metadata** ```String``` Article metadata (JSON string - dictionary)

18. **placement** ```Integer``` Placement of the article in an issue

19. **mainImageURL** ```String``` URL for the article's feature image

20. **thumbImageURL** ```String``` URL for the article's thumbnail image

21. **isPublished** ```BOOL``` Whether the article is published or in draft

22. **isFeatured** ```BOOL``` Whether the article is featured for the given issue or not

23. **issueId** ```String``` Global id for the issue the article belongs to. This can be blank for independent articles

24. **appleId** ```String``` Apple id/SKU fir the article. Will be blank if the article cannot be sold individually

###Class methods (public)
1. **deleteArticlesFor(issueId: NSString)** This method accepts an issue's global id and deletes all articles from the database which belong to that issue

2. **getArticlesFor(issueId: String?, type: String?, excludeType: String?, count: Int, page: Int)** ```returns Array<Article>``` This method accepts an issue's global id, type of article to be found and type of article to be excluded. It retrieves all articles which meet these conditions and returns them in an array. All parameters are optional. At least one of the parameters is needed when making this call. The parameters follow AND conditions

3. **issueId: NSString?, key: String, value: String, count: Int, page: Int)** ```returns Array<Article>``` This method accepts an issue's global id, a key and a value to be searched. It retrieves all articles which belong to the issue (or any regardless of issue if nil) and have a specific value for the given key. The key and value params are necessary. If you do not want paginated results, pass count as 0

4. **searchArticlesWith(keywords: [String], issueId: String?)** ```returns Array<Article>``` This method accepts an issue's global id and returns all articles for an issue (or if nil, all issues) with specific keywords

5. **getFeaturedArticlesFor(issueId: NSString)** ```returns Array<Article>``` This method accepts an issue's global id and returns all articles for the issue which are featured

6. **getArticle(articleId: String?, appleId: String?)** ```returns Article or nil``` This method accepts an article's global id or SKU/Apple id and returns the Article object or nil if not found. At least one of the params should be non-empty

7. **setAssetPattern(newPattern: String)** This method accepts a regular expression which should be used to identify placeholders for assets in an article body.
    The default asset pattern is ```<!-- \\[ASSET: .+\\] -->```

###Instance methods (public)
1. **getValue(key:)** ```returns AnyObject/id or nil``` This method returns the value for a specific key from the custom metadata of the article

2. **replacePatternsWithAssets()** ```returns NSString``` This method replaces the asset placeholders in the body of the Article with actual assets using HTML codes
    Images are replaced with <img> tags, Audio with <audio> tag and videos with <video> tag

3. **getNewerArticles()** ```returns Array<Article>``` This method returns all articles for an issue whose publish date is newer than the published date of current article

4. **getOlderArticles()** ```returns Array<Article>``` This method returns all articles for an issue whose publish date is before the published date of current article

5. **saveArticle()** This method can be called on an Article object to save it back to the database


## Asset

Realm object for Assets. Also has methods for directly dealing with assets

###Properties
1. **globalId** ```String``` Global id of an asset - this is unique for each asset

2. **caption** ```String``` Caption for the asset - used in the final rendered HTML

3. **source** ```String``` Source attribution for the asset

4. **squareURL** ```String``` File URL for the asset's square thumbnail

5. **originalURL** ```String``` File URL for the original asset

6. **mainPortraitURL** ```String``` File URL for the portrait image of the asset

7. **mainLandscapeURL** ```String``` File URL for the landscape image of the asset

8. **iconURL** ```String``` File URL for the icon image

9. **metadata** ```String``` Custom metadata for the asset

10. **type** ```String``` Asset type. Defaults to a photo. Can be *image*, *sound*, *video* or *custom*

11. **placement** ```Integer``` Placement of an asset for an article or issue

12. **articleId** ```String``` Global id for the article with which the asset is associated. Can be blank if this is an issue's asset

13. **issue** ```Issue``` Issue object for the issue with which the asset is associated. Can be a default Issue object if the asset is for an independent article

14. **volumeId** ```String``` Global id of the volume with which the asset is associated. Can be blank if this is an issue or article asset

###Class methods (public)
1. **deleteAsset(assetId: NSString)** This method accepts the global id of an asset and deletes it from the database. The file for the asset is also deleted

2. **getFirstAssetFor(issueId: String, articleId: String, volumeId: String)** ```returns Asset``` This method uses the global id for a volume and/or issue and/or article and returns its first image asset (i.e. placement = 1, type = image)

3. **getNumberOfAssetsFor(issueId: String, articleId: String, volumeId: String?)** ```returns UInt``` This method uses the global id for a volume and/or issue and/or article and returns the number of assets it has

4. **getAssetsFor(issueId: String, articleId: String, volumeId: String?, type: String?)** ```returns Array<Asset>``` This method uses the global id for a volume and/or issue and/or article and the assets in an array. It takes in an optional type parameter. If specified, only assets of that type will be returned

5. **getAsset(assetId: String)** ```returns Asset or nil``` This method inputs the global id of an asset and returns the Asset object

6. **getPlaylistFor(issueId: String, articleId: String)** ```returns Array<Asset>``` This method inputs the global id of an issue and/or article and returns all sound assets for it in an array

###Instance methods (public)
1. **saveAsset()** This method lets you save an Asset object back to the database in case some changes are made to it

2. **getAssetPath()** ```returns String``` This method returns the path of the asset file (using the ```originalURL``` property) for the current object. Use this method to access the file path instead of directly using ```originalURL```


## ReaderHelper

Class which helps store and retrieve user reading status

###Class methods (public)
1. **saveVolume(volumeId: String)** This method accepts the global id of a volume and saves it to user defaults. If nil, will remove saved volume (used when switching between volumes or you want to remove saved state)

2. **saveIssue(issueId: String)** This method accepts the global id of an issue and saves it to user defaults. If nil, will remove saved issue (used when switching between issues or you want to remove saved state)

3. **saveArticle(articleId: String)** This method accepts the global id of an article and saves it to user defaults. If nil, will remove saved article (used when switching between articles or user is not viewing any article as of now)

4. **saveAsset(assetId: String)** This method accepts the global id of an asset and saves it to user defaults. If nil, will remove saved asset (used when moving away from viewing an asset or if you wish to remove saved state)

5. **saveReadingPercentageFor(articleId: String, readingPercentage: Float)** This method saves the reading status for given article in percentage. The percentage value is calculated as current *y* position of article content (scroll position) / height of article container

6. **retrieveCurrentVolume()** ```returns String``` returns the global id of the current volume

7. **retrieveCurrentIssue()** ```returns String``` returns the global id of the current issue

8. **retrieveCurrentArticle()** ```returns String``` returns the global id of the current article

9. **retrieveCurrentAsset()** ```returns String``` returns the global id of the current active asset

10. **getReadingPercentageFor(articleId: String)** ```returns Float``` retrieves last saved reading percentage for given article. To use this value, multiply the return value with the article content height and set it as the content offset for the view holding the content

11. **getDictionaryForCloud()** ```returns Dictionary<String, AnyObject>``` This method returns a dictionary containing saved values for current issue, article, asset and reading percentage for an article. The keys used are *CurrentVolume*, *CurrentIssue*, *CurrentArticle*, *CurrentAsset* and *ArticlePercent-<article_id_here>*

12. **saveDictionaryToUserDefaults(savedValues: Dictionary<String, AnyObject>)** saves specific values from a key for current issue, current article, current asset and article reading percentage back to user defaults (for using while app is active). The keys used should be the same as above


## Notifications

Dumpling issues notifications at various stages of a download. This information can be used by apps to update progress and app data. The notifications issued by Dumpling include

1. **issueDownloadComplete** This notification is fired when an issue's data is downloaded from Magnet and saved back to the database. The articles and assets might still be downloading at this stage

2. **articlesDownloadComplete** This notification is fired when the data for all articles in an issue are downloaded and saved back to the database. It is not necessary that all assets have been downloaded at this point

3. **downloadComplete** This notification is fired when everthing related to a volume or an independent issue is downloaded (issues, articles, assets)


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

1. If you wish to publish your issue on Newsstand, make sure your project's plist has the *UINewsstandApp* key with a *true* value. You will also need to add NewsstandKit.framework to your project

2. In order to use iCloud for syncing reading status, add CloudKit.framework to your project, turn on iCloud in the target's *Capabilities* section for *Key-value storage*. The sample project (**DumplingDemo**) uses the default container for storing and retrieving values. If you wish to use a custom container, the code will change accordingly

3. If you turn on App Groups for multiple projects and instantiate **IssueHandler**, **VolumeHandler** and **ArticleHandler** with the appropriate shared folder, you can read the data across multiple apps. To do this, you will need an app id with *App Groups* enabled and set the app group in *Capabilities* for all projects sharing the data