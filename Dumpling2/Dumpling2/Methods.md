# Dumpling2 Methods

This document explains the various methods available via the Dumpling2 framework and what each does

## IssueHandler

This is the main class and the starting point of Dumpling2

###Public methods
1. **init()** lets you initialize IssueHandler with data+images stored in the Documents directory and using my API key

2. **init(folder:)** lets you initialize IssueHandler with a specific folder to save data and images and using my API key

3. **init(apikey:)** lets you initialize IssueHandler with data+images stored in the Documents directory. Calls will be made using client's key. This or the next method is what will be predominantly used

4. **init(folder: apikey:)** lets you initialize IssueHandler with a specific folder to save data and images. Calls will be made using client's key

5. **getCurrentSchemaVersion()** gets the current schema version for the Realm database. This may be used by clients or 29.io to find out the schema version in case it is needed for debugging issues

6. **addIssueZip(appleId:)** lets you add an issue to Realm using a zipped file. It will look for a file by the name *appleId*.zip in the project bundle

7. **addIssueFromAPI(issueId:)** lets you request an issue with a specific id (issue id) from the Magnet API

8. **listIssues()** prints all available issues - this is only for debugging purposes but can be extended to return the JSON response to clients for their issues (associated with their client keys)

9. **searchIssueFor(appleId:)** Searches for an issue with a given Apple id/SKU in Realm. If not available, it will get the issue from Magnet and add to Realm

10. **getIssue(issueId:)** retrieves an issue for a specific issue id from the database and returns an *Issue* object

11. **addIssueOnNewsstand(issueId:)** lets the client publish an issue from the database to Newsstand library

12. **getActiveDownloads()** returns an array of issue ids whose downloads are currently going on (not those whose download is complete)

###Private methods
1. **checkAndMigrateData(schemaVersion:)** will let 29.io write the migration code for bringing data saved with older schema up to date when the Realm schema changes

2. **updateIssueMetadata(issue:, globalId:)** adds issue details to the Realm database for a specific issue id (or global id). The issue details are read from the *issue* dictionary. It also initiates the insertion of articles and media files into the database. This method is used when working with zips

3. **updateIssueFromAPI(issue:, globalId:)** does the same function as updateIssueMetadata but is used when using the Magnet API. They are both in different methods since the structure of dictionary for both (zips and APIs) is very different

4. **updateIssueCoverIcon()** is used by *addIssueOnNewsstand* to update the cover image of an issue

5. **updateStatusDictionary(issueId:, url:, status:)** maintains a dictionary used to store the status of all downloads during a single session. It also issues notifications for various stages of an issue download


## Issue

Realm object for Issues. Also has methods for directly dealing with issues

###Class methods (public)
1. **deleteIssue(appleId:)** deletes an issue for a given Apple Id/SKU

2. **getNewestIssue()** returns newest saved issue (sorted by publish date). This is a class function

3. **getIssueFor(appleId:)** returns an issue object for a given Aple id/SKU

###Instance methods (public)
1. **getValue(key:)** returns the value for a specific key from the issue metadata

2. **getOlderIssues()** returns an array of issues whose publish date is before the publish date of current issue

3. **getNewerIssues()** returns an array of issues whose publish date is after the publish date of current issue

4. **saveIssue()** lets you save an Issue object to Realm


## Article

Realm object for Articles. Also has methods for directly dealing with articles

###Private methods
1. **createArticle(article:, issue:, placement:)** adds an article from a dictionary (obtained from an issue zip) to Realm. Also calls appropriate methods for adding article media to the database

2. **createArticleForId(articleId:, issue:, placement:, delegate:)** retrieves an article from Magnet and adds it to Realm along with calling appropriate methods for adding article media to the database

###Class methods (public)
1. **createIndependentArticle(articleId:)** downloads an article (for given article id)

2. **deleteArticlesFor(issueId)** deletes all articles for a given issue. This also calls methods to delete all assets for the articles

3. **getArticlesFor(issueId:, type:, excludeType:)** returns all articles for an issue (or all issues). The params let you get articles for only specific types, articles excluding specify types - at least one of the params (issue id, type, exclude type) is needed

4. **searchArticlesWith(keywords:, issueId:)** returns all articles for a specific issue (or for all issues if issueId is nil) which maps against specific keywords. The keywords use OR condition when searching

5. **getFeaturedArticlesFor(issueId:)** returns an array with all featured articles for an issue

6. **setAssetPattern(newPattern:)** sets the regex pattern used for searching asset placeholders (predefined as ```<!-- \\[ASSET: .+\\] -->```

###Instance methods (public)
1. **getValue(key:)** returns the value for a specific key from the issue metadata

2. **addArticle(article:)** creates an article not associated with any issue. The structure expected for the dictionary is the same as currently used in Magnet. Images will be stored in Documents folder by default for such articles. The method is used by *createIndependentArticle*

3. **replacePatternsWithAssets()** replaces assetPattern regex in the article body with appropriate HTML tags (for audio, video and images) - this needs to change as per discussion on issue #5

4. **getNewerArticles()** returns an array of articles for the current article's issue whose date is newer than the date of current article

5. **getOlderArticles()** returns an array of articles for the current article's issue whose date is older than the date of current article

6. **saveArticle()** lets you save an Article object to Realm


## Asset

Realm object for Assets. Also has methods for directly dealing with assets

###Private methods
1. **createAsset(asset:, issue:, articleId:, placement:)** adds an image asset for an issue or article

2. **createAsset(asset:, issue:, articleId:, sound:, placement:)** add an image/sound asset for an issue or article

3. **createAsset(asset:, issue:, articleId:, type:, placement:)** add an image/sound/custom type asset for an issue or article

4. **downloadAndCreateAsset(assetId:, issue:, articleId:, placement:, delegate:)** downloads an asset for a specific issue or article from Magnet and adds it to Realm

5. **deleteAssetsFor(articleId:)** deletes all assets for an article

6. **deleteAssetsForArticles(articles:)** deletes assets for all articles whose article id is provided in the incoming array

7. **deleteAssetsForIssue(globalId:)** deletes all assets for an issue

###Class methods (public)
1. **deleteAsset(assetId:)** deletes a specific asset

2. **getFirstAssetFor(issueId:, articleId:)** retrieves first asset for an issue or article

3. **getNumberOfAssetsFor(issueId:, articleId:)** returns number of assets for an issue or article

4. **getAssetsFor(issueId:, articleId:, type:)** returns an array of assets for an issue or article of a specific type. If type is nil, returns all assets for the article/issue

5. **getAsset(assetId:)** returns a specific asset

6. **getPlaylistFor(issueId:, articleId:)** returns an array of all assets for an article/issue which are of type=sound

###Instance methods (public)
1. **saveAsset()** lets you save an Asset object to Realm


## Helper

Helper class

1. **publishedDateFrom(string:)** returns NSDate from string of format MM/dd/yyyy

2. **publishedDateFromISO(string:)** returns NSDate from string in ISO format e.g. ```2015-02-12T20:49:29.213631+00:00```

3. **isiPhone()** is the device an iPhone or iPad

4. **isRetinaDevice()** is the display retina or non-retina

5. **stringFromJSON(object:)** returns string from JSON object (dictionary or array)

6. **jsonFromString(string:)** returns an array or dictionary from JSON string

7. **unpackZipFile(filePath:)** unzips a zip file into the Cache directory


## LRNetworkManager

Network manager for sending out requests and returning a response (subclass of AFHTTPRequestOperationManager)

1. **init()**, **init(baseURL:)** and **init(coder:)** override the default initializers of AFHTTPRequestOperationManager

2. **requestData(methodType:, urlString:, completion:)** sends requests to the Magnet API and returns a response to the completion block

3. **downloadFile(fromPath:, toPath:, completion:)** downloads a file from a given URL and saves to provided path