//
//  DetailViewController.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit


class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!


    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail: AnyObject = self.detailItem {
            //import the zip file, unzip, import issue data
            
            /* Step 1 - import zip file */
            var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            var cacheDir: NSString = docPaths[0] as NSString

            var appPath = NSBundle.mainBundle().bundlePath
            var defaultZipPath = "\(appPath)/\(self.detailItem).zip"
            var newZipDir = "\(cacheDir)/\(self.detailItem)"
            
            var isDir: ObjCBool = false
            if NSFileManager.defaultManager().fileExistsAtPath(newZipDir, isDirectory: &isDir) {
                if isDir {
                    //Issue directory already exists
                    //Read contents and return
                }
            }
            //Issue not copied yet. Unzip and copy
            self.unpackZipFile(defaultZipPath)
            
            //Now insert into the realm db and return contents
            IssueHandler.addIssueToRealm(newZipDir)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func unpackZipFile(filePath: NSString) {
        var zipArchive = ZipArchive()
        
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var cacheDir: NSString = docPaths[0] as NSString
        
        if zipArchive.UnzipOpenFile(filePath) {
            var result = zipArchive.UnzipFileTo(cacheDir, overWrite: true)
            if !result {
                //problem
                return
            }
            
            zipArchive.UnzipCloseFile()
        }
        
        if filePath.hasPrefix(cacheDir) {
            //remove zip file if it was in cache dir
            //planning ahead - this won't be called right now
            NSFileManager.defaultManager().removeItemAtPath(filePath, error: nil)
        }
    }

}

