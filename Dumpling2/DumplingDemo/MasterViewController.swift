//
//  MasterViewController.swift
//  DumplingDemo
//
//  Created by Lata Rastogi on 22/04/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit
import CloudKit
import Dumpling2

class MasterViewController: UITableViewController {

    var objects = NSMutableArray()
    var articles = Array<Article>()
    var issueHandler = IssueHandler(apikey: "19dc497bc4d6481cb827dd3e4637a8e3")
    let issueId = "5500918839cc7634055faf68"


    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "issueDownloadComplete:", name: "downloadComplete", object: nil)
        
        if issueHandler.getIssue(issueId) == nil {
            issueHandler.addIssueFromAPI(issueId)
        }
        else {
            self.updateIssueDetails()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Issue download complete
    func issueDownloadComplete(notif: NSNotification) {
        self.updateIssueDetails()
        issueHandler.addIssueOnNewsstand(issueId)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func updateIssueDetails() {
        if let addedIssue: Issue = issueHandler.getIssue(issueId) as Issue! {
            self.navigationItem.title = addedIssue.title
        }
        
        if let results = Article.getArticlesFor(issueId, type: nil, excludeType: nil) {
            for article in results {
                let obj: Article = article as Article
                objects.addObject(obj.title)
                articles.append(obj)
            }
        }
        
        //Save issue id to user defaults
        ReaderHelper.saveIssue(issueId)
        self.loadFromiCloud()
        tableView.reloadData()
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let article = articles[indexPath.row] as Article
                (segue.destinationViewController as! DetailViewController).detailItem = article
            }
        }
    }
    
    //MARK: - Load status from iCloud
    func loadFromiCloud() {
        //Get all saved values for read sync from iCloud in a dictionary
        var cloudStore = NSUbiquitousKeyValueStore.defaultStore()
        if let dictionary: Dictionary<String, AnyObject> = cloudStore.dictionaryForKey("ReadingSync") as? Dictionary<String, AnyObject> {
            //Save dictionary values from iCloud to user defaults - to be used while app is active
            ReaderHelper.saveDictionaryToUserDefaults(dictionary)
        }
        
        //Load next view with appropriate article and position - if applicable
        if let articleId = ReaderHelper.retrieveCurrentArticle() {
            for (index, article: Article) in enumerate(articles) {
                if articleId == article.globalId {
                    var rowToSelect: NSIndexPath = NSIndexPath(forRow: index, inSection: 0)
                    self.tableView.selectRowAtIndexPath(rowToSelect, animated: false, scrollPosition: UITableViewScrollPosition.None)
                    self.performSegueWithIdentifier("showDetail", sender: nil)
                }
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell

        cell.textLabel!.text = objects[indexPath.row] as? String
        return cell
    }

}

