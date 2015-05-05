//
//  LRNetworkManager.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 16/03/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit

class LRNetworkManager: AFHTTPRequestOperationManager {
    
    struct Singleton {
        static let sharedInstance = LRNetworkManager()
    }
    
    class var sharedInstance: LRNetworkManager {
        return Singleton.sharedInstance
    }
    
    override init(baseURL:NSURL) {
        super.init(baseURL: baseURL)
    }
    
    init() {
        super.init(baseURL: nil)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func requestData(methodType: String, urlString:String, completion:(data:AnyObject?, error:NSError?) -> ()) {
        //let authorization = "method=apikey,token=\(apiKey)"
        let authorization = "method=clientkey,token=\(apiKey)"
        self.requestSerializer.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        if methodType == "GET" {
        
            var operation = self.GET(urlString,
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    completion(data: responseObject, error: nil)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    completion(data: nil, error: error)
            })
        }
        else if methodType == "POST" {
            
            var operation = self.POST(urlString,
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    completion(data: responseObject, error: nil)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    completion(data: nil, error: error)
            })
        }
    }
    
    func downloadFile(fromPath: String, toPath: String, completion:(status:AnyObject?, error:NSError?) -> ()) {
        var url = NSURL(string: fromPath)
        var urlRequest = NSURLRequest(URL: url!)
        
        var operation = AFHTTPRequestOperation(request: urlRequest)
        operation.outputStream = NSOutputStream(toFileAtPath: toPath, append: false)
        operation.setCompletionBlockWithSuccess( { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
            
            completion(status: NSNumber(bool: true), error: nil)
            
            }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                completion(status: nil, error: error)
        
        })
        
        operation.start()
    }
    
    func findAllActiveOperations() -> NSArray {
        var operations = self.operationQueue.operations
        return operations
    }
    
}