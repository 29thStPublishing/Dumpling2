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
    
    @IBAction func importZip () {
        var issueHandler = IssueHandler()
        issueHandler.addIssueZip("org.bomb.mag.issue.20150101")
    }
    
    @IBAction func useAPI () {
        var issueHandler = IssueHandler()
        issueHandler.addIssueFromAPI("54c829c639cc76043772948d")
    }

}

