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

class ImageDownloaderObserver: NSObject {
    var queue = NSOperationQueue()

    override init() {
        super.init()
        queue.addObserver(self, forKeyPath: "operations", options: .New, context: &myContext)
    }
    deinit {
        queue.removeObserver(self, forKeyPath: "operations", context: &myContext)
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate

            if self.queue.operations.count == 0 {
                println("Image Download Complete queue.")

                // set backgrounds.
                appDelegate.setDesktopBackgrounds()
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

    override func main() {
        request = Alamofire.download(.GET, URLString, { (temporaryURL, response) in
            let fileName = response.suggestedFilename!
            self.finalPath = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingPathComponent(fileName as String))
            if self.finalPath != nil {
                //println(finalPath)
                return self.finalPath!
            }
            return temporaryURL
        }).response { (request, response, responseObject, error) in
            if error != nil {
                println("DownloadImage error: \(error)")
            }

            if let finalPath = self.finalPath {
                var photoRecord = PhotoRecord(name: "test", url: NSURL(string: self.URLString)!, localPathUrl: self.finalPath!)
                self.downloadImageCompletionHandler(responseObject: photoRecord, error: error)
            }
            self.completeOperation()
        }
    }

    override func cancel() {
        request?.cancel()
        super.cancel()
    }
}