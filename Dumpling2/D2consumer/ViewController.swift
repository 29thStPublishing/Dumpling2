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
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if let iHandler = IssueHandler(folder: docsDir) {
            self.issueHandler = iHandler
            //self.issueHandler!.addIssueZip("org.bomb.mag.issue.20150101")
        }
    }
    
    //Add issue details from API
    @IBAction func useAPI () {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "articlesDownloaded:", name: "articlesDownloadComplete", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "issueDownloadComplete:", name: "issueDownloadComplete", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "downloadComplete:", name: "downloadComplete", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "allDownloadsComplete:", name: "allDownloadsComplete", object: nil)
        
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        /*if let vHandler = VolumeHandler(folder: docsDir) {
            self.volumeHandler = vHandler
            self.volumeHandler!.addVolumeFromAPI("555a27de352c7d6d5b888c3e")
        }*/
        
        if let iHandler = IssueHandler(folder: docsDir) {
            self.issueHandler = iHandler
            //self.issueHandler!.addIssueFromAPI("55e56516ada6e21a9f6651f6", volumeId: nil)
            self.issueHandler!.addAllIssues()
        }
        /*if let articleHandler = ArticleHandler(folder: docsDir) {
            //articleHandler.addAllArticles(0, limit: 30)
            articleHandler.addAllPublishedArticles(0, limit: 10)
            //articleHandler.addArticlesFor("ist", value: "LAist", page: 0, limit: 1)
        }*/
    }
    
    func articlesDownloaded(notif: NSNotification) {
        NSLog("###DOWNLOAD ARTICLES###")
    }
    
    func issueDownloadComplete(notif: NSNotification) {
        print("#####ISSUE DOWNLOAD######")
        if let issueId: String = notif.userInfo?["issue"] as? String {
            if issueId == "566ea797ada6e263d36edeb3" {
                if let issue = Issue.getIssue("566ea797ada6e263d36edeb3") {
                    issue.downloadIssueArticles()
                    issue.downloadAllAssets()
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
    
    func downloadComplete(notif: NSNotification) {
        print("#####DOWNLOAD COMP######")
        if let article = Article.getArticle("566ea797ada6e263d36edeb3", appleId: nil) {
            let str = article.replacePatternsWithAssets()
            NSLog("STR: \(str)")
        }
        /*if let issueId: String = notif.userInfo?["issue"] as? String {
            if self.issue == nil {
                return
            }
            if issueId == self.issue!.globalId {
                let dict = self.issueHandler!.findAllDownloads(self.issue!.globalId)
                NSLog("##FROM DOWNLOAD: \(dict)")
            }
        }*/
    }
    
    func allDownloadsComplete(notif: NSNotification) {
        print("#####ALL DOWNLOAD######")
        if self.issue == nil {
            return
        }
        let dict = self.issueHandler!.findAllDownloads(self.issue!.globalId)
        NSLog("##FROM ALL: \(dict)")
    }
}

