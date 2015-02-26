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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateIssueStatus:", name: "issueAdded", object: nil)
        
        let container = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.Dumpling2Test")
        let directory = container?.path
        
        var issueHandler = IssueHandler(folder: directory)
        
        //When not using shared folders
        //var issueHandler = IssueHandler()
        issueHandler.addIssueFromAPI("54c829c639cc76043772948d")
    }
    
    func updateIssueStatus(notif: NSNotification) {
        let userInfo:Dictionary<String,String!> = notif.userInfo as Dictionary<String,String!>
        let globalId = userInfo["globalId"]
        
        var alert = UIAlertController(title: "Issue downloaded", message: globalId, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}

