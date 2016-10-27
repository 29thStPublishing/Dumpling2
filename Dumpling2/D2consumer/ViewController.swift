//
//  ViewController.swift
//  D2consumer
//
//  Created by Lata Rastogi on 28/01/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit
import Dumpling2

class ViewController: UIViewController {

    var issueHandler: IssueHandler?
    var volumeHandler: VolumeHandler?
    var issue: Issue?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Add issue details using bundled zip
    @IBAction func importZip () {
        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if let iHandler = IssueHandler(folder: docsDir) {
            self.issueHandler = iHandler
            //self.issueHandler!.addIssueZip("org.bomb.mag.issue.20150101")
        }
    }
    
    //Add issue details from API
    @IBAction func useAPI () {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.articlesDownloaded(_:)), name: NSNotification.Name(rawValue: "articlesDownloadComplete"), object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "issueDownloadComplete:", name: "issueDownloadComplete", object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "downloadComplete:", name: "downloadComplete", object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "allDownloadsComplete:", name: "allDownloadsComplete", object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.mediaDownloaded(_:)), name: NSNotification.Name(rawValue: "mediaDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.imageDownloaded(_:)), name: NSNotification.Name(rawValue: "imageDownloaded"), object: nil)
        
        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        /*if let vHandler = VolumeHandler(folder: docsDir) {
            self.volumeHandler = vHandler
            self.volumeHandler!.addVolumeFromAPI("555a27de352c7d6d5b888c3e")
        }*/
        
        /*if let iHandler = IssueHandler(folder: docsDir) {
            self.issueHandler = iHandler
            //iHandler.addPreviewIssues()
            //iHandler.addOnlyIssuesWithoutArticles()
            iHandler.addIssueFromAPI("555b76d9ada6e27ef3d5680a", volumeId: nil, withArticles: false)
        }*/
        if let articleHandler = ArticleHandler(folder: docsDir) {
            //articleHandler.addAllArticles(0, limit: 5, timestamp: "2016-05-01T14:13:12Z")
            articleHandler.addAllArticles(0, limit: 50)
        }
    }
    
    func articlesDownloaded(_ notif: Notification) {
        //NSLog("###DOWNLOAD ARTICLES###")
        if let articleId: String = (notif as NSNotification).userInfo?["issue"] as? String {
            if let article = Article.getArticle(articleId, appleId: nil) {
                article.downloadArticleAssets(nil)
            }
        }
    }
    
    func issueDownloadComplete(_ notif: Notification) {
        print("#####ISSUE DOWNLOAD######")
        /*if let issueId: String = notif.userInfo?["issue"] as? String {
            if let issue = Issue.getIssue(issueId) {
                //self.issueHandler!.downloadArticlesFor(issue.globalId)
                if self.issue == nil && issueId == "577f5c3bada6e205954ecb40" {
                    self.issue = issue
                    //issue.downloadIssueArticles()
                    issue.downloadIssueArticles()
                }
            }
        }*/
        /*if let issueId: String = notif.userInfo?["issue"] as? String {
            let newIssue = Issue.getIssue(issueId)
            if issueId == "5631a4b9ada6e225e83c0338" {
                self.issue = newIssue
                self.issue!.downloadAllAssets()
            }
        }*/
    }
    
    func downloadComplete(_ notif: Notification) {
        /*print("#####DOWNLOAD COMP######")
        if let articles = Article.getArticlesFor("56fc3999ada6e22ac9d16b98", type: "ad", excludeType: nil, count: 0, page: 0) {
            NSLog("ARTICLES: \(articles.count)::: \(articles)")
        }*/
        
    }
    
    func mediaDownloaded(_ notif: Notification) {
        //print("#####MEDIA DOWNLOAD######")
        if let articleId: String = (notif as NSNotification).userInfo?["issue"] as? String {
            if let assetId: String = (notif as NSNotification).userInfo?["media"] as? String {
                if let asset = Asset.getAsset(assetId) {
                    if let firstAsset = Asset.getFirstAssetFor("", articleId: articleId, volumeId: nil) {
                        if firstAsset.globalId == assetId {
                            asset.getThumbImageForAsset(articleId, issue: nil)
                        }
                    }
                    asset.getOriginalImageForAsset(articleId, issue: nil)
                    //asset.getOriginalImageForAsset(notif.userInfo?["issue"] as? String, issue: nil)
                    //asset.getThumbImageForAsset(notif.userInfo?["issue"] as? String, issue: nil)
                }
            }
        }
        /*if let issueId: String = notif.userInfo?["issue"] as? String {
         let newIssue = Issue.getIssue(issueId)
         if issueId == "5631a4b9ada6e225e83c0338" {
         self.issue = newIssue
         self.issue!.downloadAllAssets()
         }
         }*/
    }
    
    func imageDownloaded(_ notif: Notification) {
        NSLog("IMAGE DOWNLOADED: \((notif as NSNotification).userInfo!)")
    }
    
    func allDownloadsComplete(_ notif: Notification) {
        print("#####ALL DOWNLOAD######")
    }
}

