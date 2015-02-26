//
//  ConsumerViewController.swift
//  D2Reader
//
//  Created by Lata Rastogi on 24/02/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit
import Dumpling2

class ConsumerViewController: UIViewController {
    
    @IBOutlet weak var issueDetailsLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //Get issue details using global id of an issue
    @IBAction func getIssueDetails() {
        let container = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.Dumpling2Test")
        let directory = container?.path
        
        var issueHandler = IssueHandler(folder: directory!)
        
        //When not using shared folders
        //var issueHandler = IssueHandler()
        var issue: Issue? = issueHandler.getIssue("54c829c639cc76043772948d")?
        
        if let currentIssue = issue {
            self.issueDetailsLabel.text = "Issue id: \(currentIssue.globalId)\nTitle: \(currentIssue.title)\nDisplay date: \(currentIssue.displayDate)"
        }
    }

}

