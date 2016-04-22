//
//  LRNetworkManager.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 16/03/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit

class LRNetworkManager: AFHTTPSessionManager {
    
    var preview: Bool = false
    
    struct Singleton {
        static let sharedInstance = LRNetworkManager(baseURL: nil)
    }
    
    class var sharedInstance: LRNetworkManager {
        return Singleton.sharedInstance
    }
    
    /*override init(baseURL url: NSURL?) {
        super.init(baseURL: url)
        if let previewApp = NSBundle.mainBundle().objectForInfoDictionaryKey("Preview") as? NSNumber {
            self.preview = previewApp.boolValue
        }
    }
    
    init() {
        super.init(baseURL: nil)
    }*/
    init() {
        super.init(baseURL: nil, sessionConfiguration: nil)
    }
    
    override init(baseURL url: NSURL?, sessionConfiguration configuration: NSURLSessionConfiguration?) {
        super.init(baseURL: url, sessionConfiguration: configuration)
        
        if let previewApp = NSBundle.mainBundle().objectForInfoDictionaryKey("Preview") as? NSNumber {
            self.preview = previewApp.boolValue
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        if let previewApp = NSBundle.mainBundle().objectForInfoDictionaryKey("Preview") as? NSNumber {
            self.preview = previewApp.boolValue
        }
    }

    func requestData(methodType: String, urlString:String, completion:(data:AnyObject?, error:NSError?) -> ()) {
        lLog("URL String:\(urlString)")
        //let authorization = "method=apikey,token=\(apiKey)"
        let authorization = "method=clientkey,token=\(clientKey)"
        self.requestSerializer.setValue(authorization, forHTTPHeaderField: "Authorization")
        if self.preview {
            self.requestSerializer.setValue("preview", forHTTPHeaderField: "X-Preview-App")
        }
        
        if methodType == "GET" {
            _ = self.GET(urlString, parameters: nil, progress: nil,
                success: { (operation, responseObject) -> Void in
                    completion(data: responseObject, error: nil)
                },
                failure: { (operation, error) in
                    completion(data: nil, error: error)
            })
            /*_ = self.GET(urlString,
                parameters: nil,
                success: { (operation, responseObject) -> Void in
                    completion(data: responseObject, error: nil)
                },
                failure: { (operation, error) in
                    completion(data: nil, error: error)
            })*/
        }
        else if methodType == "POST" {
            
            _ = self.POST(urlString, parameters: nil, progress: nil,
                success: { (operation, responseObject) -> Void in
                    completion(data: responseObject, error: nil)
                },
                failure: { (operation, error) in
                    completion(data: nil, error: error)
            })
        }
    }
    
    func downloadFile(fromPath: String, toPath: String, completion:(status:AnyObject?, error:NSError?) -> ()) {
        lLog("Download file:\(fromPath)")
        let url = NSURL(string: fromPath)
        let urlRequest = NSURLRequest(URL: url!)
        
        let downloadTask = self.downloadTaskWithRequest(urlRequest, progress: nil, destination: {(file, responce) in
                let url = NSURL(fileURLWithPath: toPath)
                return url
            }, completionHandler: { response, localfile, error in
                if (error != nil) {
                    completion(status: nil, error: error)
                }
                else {
                    completion(status: NSNumber(bool: true), error: nil)
                }
        })
        downloadTask.resume()
        /*let operation = AFHTTPRequestOperation(request: urlRequest)
        operation.outputStream = NSOutputStream(toFileAtPath: toPath, append: false)
        operation.setCompletionBlockWithSuccess( { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
            
            completion(status: NSNumber(bool: true), error: nil)
            
            }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                completion(status: nil, error: error)
        
        })
        
        operation.start()*/
    }
    
}