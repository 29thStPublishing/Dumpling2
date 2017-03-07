//
//  LRNetworkManager.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 16/03/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import UIKit

class LRNetworkManager: AFHTTPRequestOperationManager {
    
    var preview: Bool = false
    
    struct Singleton {
        static let sharedInstance = LRNetworkManager(baseURL: nil)
    }
    
    class var sharedInstance: LRNetworkManager {
        return Singleton.sharedInstance
    }
    
    override init(baseURL url: URL?) {
        super.init(baseURL: url)
        if let previewApp = Bundle.main.object(forInfoDictionaryKey: "Preview") as? NSNumber {
            self.preview = previewApp.boolValue
        }
    }
    
    init() {
        super.init(baseURL: nil)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        if let previewApp = Bundle.main.object(forInfoDictionaryKey: "Preview") as? NSNumber {
            self.preview = previewApp.boolValue
        }
    }

    func requestData(_ methodType: String, urlString:String, completion:@escaping (_ data:AnyObject?, _ error:NSError?) -> ()) {
        lLog("URL String:\(urlString)")
        //let authorization = "method=apikey,token=\(apiKey)"
        let authorization = "method=clientkey,token=\(clientKey)"
        self.requestSerializer.setValue(authorization, forHTTPHeaderField: "Authorization")
        if self.preview {
            self.requestSerializer.setValue("preview", forHTTPHeaderField: "X-Preview-App")
        }
        
        if methodType == "GET" {
        
            _ = self.get(urlString,
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: Any!) in
                    completion(responseObject as AnyObject, nil)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: Error!) in
                    completion(nil, error as NSError)
            })
        }
        else if methodType == "POST" {
            
            _ = self.post(urlString,
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: Any!) in
                    completion(responseObject as AnyObject, nil)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: Error!) in
                    completion(nil, error as NSError)
            })
        }
    }
    
    func downloadFile(_ fromPath: String, toPath: String, completion:@escaping (_ status:AnyObject?, _ error:NSError?) -> ()) {
        lLog("Download file:\(fromPath)")
        let url = URL(string: fromPath)
        let urlRequest = URLRequest(url: url!)
        
        let operation = AFHTTPRequestOperation(request: urlRequest)
        operation.outputStream = OutputStream(toFileAtPath: toPath, append: false)
        operation.setCompletionBlockWithSuccess( { (operation: AFHTTPRequestOperation!, responseObject: Any!) in
            
            completion(NSNumber(value: true as Bool), nil)
            
            }, failure: { (operation: AFHTTPRequestOperation!, error: Error!) in
                completion(nil, error as NSError)
        
        })
        
        operation.start()
    }
    
    func findAllActiveOperations() -> NSArray {
        let operations = self.operationQueue.operations
        return operations as NSArray
    }
    
}
