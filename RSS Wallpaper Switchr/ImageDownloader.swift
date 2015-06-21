//
//  ImageDownloader.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/6/16.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa
import Alamofire

private var myContext = 0

protocol ImageDownloadDelegate {
    func imagesDidDownload()
}

class ImageDownloadObserver: NSObject {
    var delegate: ImageDownloadDelegate?
    var queue = NSOperationQueue()

    init(delegate: ImageDownloadDelegate) {
        super.init()
        self.delegate = delegate
        queue.addObserver(self, forKeyPath: "operations", options: .New, context: &myContext)
        NSLog("ImageDownloadObserver init.")
    }

    deinit {
        self.queue.removeObserver(self, forKeyPath: "operations", context: &myContext)
        if DEBUG_DEINIT {
            println("ImageDownloadObserver deinit.")
        }
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            if self.queue.operations.count == 0 {
                println("Image Download Complete queue. keyPath: \(keyPath); object: \(object); context: \(context)")

                //let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate

                // set backgrounds.
                self.delegate?.imagesDidDownload()
                //appDelegate.stateToReady()
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}

class DownloadImageOperation : ConcurrentOperation {
    let URLString: String
    let downloadImageCompletionHandler: (responseObject: AnyObject?, error: NSError?) -> ()

    weak var request: Alamofire.Request?
    var finalPath: NSURL?

    init(URLString: String, downloadImageCompletionHandler: (responseObject: AnyObject?, error: NSError?) -> ()) {
        self.URLString = URLString
        self.downloadImageCompletionHandler = downloadImageCompletionHandler
        super.init()
    }

    deinit {
        request = nil
        if DEBUG_DEINIT {
        //    println("DownloadImageOperation deinit.")
        }
    }

    override func main() {
        request = Alamofire.download(.GET, URLString, { (temporaryURL, response) in
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
        }).response { (request, response, responseObject, error) in
            if error != nil {
                println("DownloadImage error: \(error)")
            }

            if self.cancelled {
                println("DownloadImageOperation.main() Alamofire.download cancelled while downlading. Not proceed into PhotoRecord.")
            } else {
                if let finalPath = self.finalPath {
                    var photoRecord = PhotoRecord(name: "test", url: NSURL(string: self.URLString)!, localPathUrl: self.finalPath!)
                    self.downloadImageCompletionHandler(responseObject: photoRecord, error: error)
                }
            }

            self.completeOperation()
        }
    }

    override func cancel() {
        // should also cancel Alamofire request, but it results in strange memory problem!
        request?.cancel()
        super.cancel()
    }
}