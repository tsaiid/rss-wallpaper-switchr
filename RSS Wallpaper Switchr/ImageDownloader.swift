//
//  ImageDownloader.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/6/16.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa
import Alamofire

class ImageDownloader: NSObject {
    var queue = NSOperationQueue()

    override init() {
        super.init()
        NSLog("ImageDownloader init.")
    }

    deinit {
        if DEBUG_DEINIT {
            NSLog("ImageDownloader deinit.")
        }
    }
}

class DownloadImageOperation : ConcurrentOperation {
    let URLString: String
    var finalPath: NSURL?
    let downloadImageCompletionHandler: (responseObject: AnyObject?, error: NSError?) -> ()
    weak var request: Alamofire.Request?

    init(URLString: String, downloadImageCompletionHandler: (responseObject: AnyObject?, error: NSError?) -> ()) {
        self.URLString = URLString
        self.downloadImageCompletionHandler = downloadImageCompletionHandler
        super.init()
    }

    deinit {
        request = nil
        if DEBUG_DEINIT {
            println("DownloadImageOperation deinit.")
        }
    }

    override func main() {
        let destination: (NSURL, NSHTTPURLResponse) -> (NSURL) = {
            (temporaryURL, response) in

            let fileName = response.suggestedFilename!
            self.finalPath = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingPathComponent(fileName as String))
            if self.finalPath != nil {
                // check if temp file exists, then remove
                let finalPathStr:String = self.finalPath!.path!.stringByExpandingTildeInPath
                if NSFileManager.defaultManager().fileExistsAtPath(finalPathStr) {
                    var removeFileError: NSError?
                    if NSFileManager.defaultManager().removeItemAtPath(finalPathStr, error: &removeFileError) {
                        println("tmp file: \(finalPathStr) exists and removed.")
                    } else {
                        println("removing tmp file: \(finalPathStr) error: \(removeFileError)")
                    }
                } else {
                    //println("\(finalPathStr) not exists.")
                }
                return self.finalPath!
            }
            return temporaryURL
        }

        request = Alamofire.download(.GET, URLString, destination).response {
            (request, response, responseObject, error) in

            if self.cancelled {
                println("DownloadImageOperation.main() Alamofire.download cancelled while downlading. Not proceed into PhotoRecord.")
            } else {
                self.downloadImageCompletionHandler(responseObject: self.finalPath, error: error)
            }
            self.completeOperation()
        }
    }

    override func cancel() {
        request?.cancel()
        super.cancel()
    }
}