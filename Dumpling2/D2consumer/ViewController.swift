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
        var docsDir: NSString = docPaths[0] as! NSString
        
        if let iHandler = IssueHandler(folder: docsDir) {
            self.issueHandler = iHandler
            self.issueHandler!.addIssueZip("org.bomb.mag.issue.20150101")
        }
    }
    
    //Add issue details from API
    @IBAction func useAPI () {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateArticleStatus:", name: "allDownloadsComplete", object: nil)
        
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir: NSString = docPaths[0] as! NSString
        
        /*if let vHandler = VolumeHandler(folder: docsDir) {
            self.volumeHandler = vHandler
            self.volumeHandler!.addVolumeFromAPI("555a27de352c7d6d5b888c3e")
        }*/
        
        /*if let iHandler = IssueHandler(folder: docsDir) {
            self.issueHandler = iHandler
            self.issueHandler!.addIssueFromAPI("555cbf28ae2eea2ae23783b3", volumeId: nil)
        }*/
        if let articleHandler = ArticleHandler(folder: docsDir) {
            articleHandler.addAllArticles()
        }
    }
    
    func updateArticleStatus(notif: NSNotification) {
        println("#####DOWNLOADED######")
        //NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

