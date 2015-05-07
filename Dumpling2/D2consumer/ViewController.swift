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
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir: NSString = docPaths[0] as! NSString
        
        if let issueHandler = IssueHandler(folder: docsDir) {
            issueHandler.addIssueZip("org.bomb.mag.issue.20150101")
        }
    }
    
    //Add issue details from API
    @IBAction func useAPI () {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateIssueStatus:", name: "downloadComplete", object: nil)
        
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir: NSString = docPaths[0] as! NSString
        
        if let issueHandler = IssueHandler(folder: docsDir) {
            issueHandler.addIssueFromAPI("551477bfaa93900422037b16")
        }
    }
    
    func updateIssueStatus(notif: NSNotification) {
        println("#####DOWNLOADED######")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

