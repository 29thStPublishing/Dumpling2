# Dumpling

Dumpling is a framework using which you can publish issues/articles as apps easily by connecting with the Magnet API.

Dumpling has been written with Swift 1.2 and is very easy to use and integrate. This short guide is to help you understand the methods available to you with Dumpling framework.


## IssueHandler

This is the main class and the starting point of Dumpling

###Methods
1. **init()** Initializes the IssueHandler with the Documents directory. This is where the database and assets will be saved

2. **init(folder: NSString)** Initializes the IssueHandler with the given folder. This is where the database and assets will be saved

3. **init(apikey: NSString)** Initializes the IssueHandler with the Documents directory. This is where the database and assets will be saved. The API key is used for making calls to the Magnet API

4. **init(folder: NSString, apikey: NSString)** Initializes the IssueHandler with a custom directory. This is where the database and assets will be saved. The API key is your Client API key provided by 29.io

5. **getCurrentSchemaVersion()** ```returns UInt``` Find current schema version

6. **addIssueZip(appleId: NSString)** The method uses an Apple id, gets a zip file from the project Bundle with the name appleId.zip, extracts its contents and adds the issue, articles and assets to the database

7. **addIssueFromAPI(issueId: String)** The method uses the global id of an issue, gets its content from the Magnet API and adds it to the database

8. **listIssues()** The method is for testing only. It prints the available issues for a client api key

9. **searchIssueFor(appleId: String)** ```returns Issue or nil``` The method searches for an issue with a specific Apple ID. If the issue is not available in the database, the issue will be downloaded from the Magnet API and added to the DB

10. **getIssue(issueId: NSString)** ```returns Issue or nil``` Get issue details from database for a specific global id

11. **addIssueOnNewsstand(issueId: String)** Add issue on Newsstand

12. **getActiveDownloads()** ```returns NSArray``` Get issue ids whose download not complete yet


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

###Class methods (public)
1. **deleteIssue(appleId: NSString)** This method uses the SKU/Apple id for an issue and deletes it from the database. All the issue's articles, assets, article assets are deleted from the database and the file system

2. **getNewestIssue()** ```returns Issue or nil``` This method returns the Issue object for the most recent issue in the database (sorted by publish date)

3. **getIssueFor(appleId: String)** ```returns Issue or nil``` This method takes in an SKU/Apple id and returns the Issue object associated with it (or nil if not found in the database)

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

21. **isFeatured** ```BOOL``` Whether the article is featured for the given issue or not

22. **issueId** ```String``` Global id for the issue the article belongs to. This can be blank for independent articles

###Class methods (public)
1. **createIndependentArticle(articleId: String)** This method accepts an article's global id, gets its details from Magnet API and adds it to the database

2. **deleteArticlesFor(issueId: NSString)** This method accepts an issue's global id and deletes all articles from the database which belong to that issue

3. **getArticlesFor(issueId: String?, type: String?, excludeType: String?)** ```returns Array<Article>``` This method accepts an issue's global id, type of article to be found and type of article to be excluded. It retrieves all articles which meet these conditions and returns them in an array. All parameters are optional. At least one of the parameters is needed when making this call. The parameters follow AND conditions

4. **searchArticlesWith(keywords: [String], issueId: String?)** ```returns Array<Article>``` This method accepts an issue's global id and returns all articles for an issue (or if nil, all issues) with specific keywords

5. **getFeaturedArticlesFor(issueId: NSString)** ```returns Array<Article>``` This method accepts an issue's global id and returns all articles for the issue which are featured

6. **setAssetPattern(newPattern: String)** This method accepts a regular expression which should be used to identify placeholders for assets in an article body.
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

12. **fullFolderPath** ```String``` Folder which stores the asset files - downloaded or unzipped

13. **articleId** ```String``` Global id for the article with which the asset is associated. Can be blank if this is an issue's asset

14. **issue** ```Issue``` Issue object for the issue with which the asset is associated. Can be a default Issue object if the asset is for an independent article

###Class methods (public)
1. **deleteAsset(assetId: NSString)** This method accepts the global id of an asset and deletes it from the database. The file for the asset is also deleted

2. **getFirstAssetFor(issueId: String, articleId: String)** ```returns Asset``` This method uses the global id for an issue and/or article and returns its first image asset (i.e. placement = 1, type = image)

3. **getNumberOfAssetsFor(issueId: String, articleId: String)** ```returns UInt``` This method uses the global id for an issue and/or article and returns the number of assets it has

4. **getAssetsFor(issueId: String, articleId: String, type: String?)** ```returns Array<Asset>``` This method uses the global id for an issue and/or article and the assets in an array. It takes in an optional type parameter. If specified, only assets of that type will be returned

5. **getAsset(assetId: String)** ```returns Asset or nil``` This method inputs the global id of an asset and returns the Asset object

6. **getPlaylistFor(issueId: String, articleId: String)** ```returns Array<Asset>``` This method inputs the global id of an issue and/or article and returns all sound assets for it in an array

###Instance methods (public)
1. **saveAsset()** This method lets you save an Asset object back to the database in case some changes are made to it