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
        var issueHandler = IssueHandler()
        issueHandler.addIssueZip("org.bomb.mag.issue.20150101")
    }
    
    //Add issue details from API
    @IBAction func useAPI () {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateIssueStatus:", name: "downloadComplete", object: nil)
        
        let container = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.Dumpling2Test")
        let directory = container?.path
        
        //Uncomment when using a shared folder
        //var issueHandler = IssueHandler(folder: directory!)
        
        //Uncomment when not using shared folders
        var issueHandler = IssueHandler(apikey: "19dc497bc4d6481cb827dd3e4637a8e3")
        issueHandler.addIssueFromAPI("551477bfaa93900422037b16")
    }
    
    func updateIssueStatus(notif: NSNotification) {
        println("#####DOWNLOADED######")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //Get issue details
    func readIssueDetails () {
        var issueHandler = IssueHandler()
        var issue: Issue? = issueHandler.getIssue("54c829c639cc76043772948d")?
        
        if let currentIssue = issue {
            var message = "Issue id: \(currentIssue.globalId)\nTitle: \(currentIssue.title)\nDisplay date: \(currentIssue.displayDate)"
            
            var alert = UIAlertController(title: "Issue details", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //Get articles array for an issue
    func getArticlesForIssue () {
        var articlesArray: NSArray? = Article.getArticlesFor("54c829c639cc76043772948d", type: nil, excludeType: nil)
        
        if (articlesArray != nil) {
            //Iterate through the array and view each article's details
        }
    }

}

