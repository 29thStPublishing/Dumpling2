//
//  DetailViewController.swift
//  DumplingDemo
//
//  Created by Lata Rastogi on 22/04/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit
import CloudKit
import Dumpling2

class DetailViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate {

    @IBOutlet weak var articleView: UIWebView!
    var containerScrollView: UIScrollView?
    var webViewHeight: Float = 0.0

    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail: Article = self.detailItem as? Article {

            //Save article id to user defaults
            ReaderHelper.saveArticle(detail.globalId)
            
            if let webView = self.articleView {
                if self.containerScrollView == nil {
                    //get container scroll view
                    for subView in webView.subviews as! [UIView] {
                        if subView.isKindOfClass(UIScrollView) {
                            self.containerScrollView = subView as? UIScrollView
                            self.containerScrollView?.delegate = self
                            
                            if let offsetHeight: String = webView.stringByEvaluatingJavaScriptFromString("document.body.offsetHeight;") {
                                self.webViewHeight = NSString(string: offsetHeight).floatValue
                            }
                        }
                    }
                }
                var updatedText = self.getUpdatedText()
                webView.loadHTMLString(updatedText as! String, baseURL: nil)
            }
        }
    }
    
    func getUpdatedText() -> NSString? {
        let article = self.detailItem as! Article
        var updatedBody = article.replacePatternsWithAssets()
        
        return updatedBody
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        
        //Get scroll view of the web view
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //Remove article from saved values - this will no longer be the current article
        ReaderHelper.saveArticle(nil);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UIWebViewDelegate
    func webViewDidFinishLoad(webView: UIWebView) {
        //load reading position of scrollview if any
        let article = self.detailItem as! Article
        var progress: Float = ReaderHelper.getReadingPercentageFor(article.globalId) * self.webViewHeight
        self.containerScrollView?.contentOffset = CGPoint(x: 0, y: CGFloat(progress))
    }

    //MARK: - UIScrollViewDelegate
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let detail: Article = self.detailItem as! Article
        ReaderHelper.saveReadingPercentageFor(detail.globalId, readingPercentage: Float(self.articleView.scrollView.contentOffset.y)/self.webViewHeight)
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            let detail: Article = self.detailItem as! Article
            ReaderHelper.saveReadingPercentageFor(detail.globalId, readingPercentage: Float(self.articleView.scrollView.contentOffset.y)/self.webViewHeight)
        }
    }

}

