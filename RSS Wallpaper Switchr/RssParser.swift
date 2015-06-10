//
//  RssParser.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/2.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa
import Alamofire
import SWXMLHash

class ParseRss : ConcurrentOperation {
    let URLString: String
    let parseRssCompletionHandler: (responseObject: AnyObject?, error: NSError?) -> ()
    
    weak var request: Alamofire.Request?
    
    init(URLString: String, parseRssCompletionHandler: (responseObject: AnyObject?, error: NSError?) -> ()) {
        self.URLString = URLString
        self.parseRssCompletionHandler = parseRssCompletionHandler
        super.init()
    }
    
    override func main() {
        request = Alamofire.request(.GET, URLString)
            .responseString { (request, response, data, error) in
                //println(request)
                //println(response)
                //println(error)
                //println(data)
                var xml = SWXMLHash.parse(data!)
                let title = xml["rss"]["channel"]["title"].element?.text
                println("Feed: \(title) was parsed.")
                
                // return a list of image links.
                var imgLinkList = [String]()
                for item in xml["rss"]["channel"]["item"] {
                    if let link = item["link"].element?.text {
                        if !contains(imgLinkList, link) {
                            imgLinkList += [link]
                        }
                    }
                }
                
                self.parseRssCompletionHandler(responseObject: imgLinkList, error: error)
                self.completeOperation()
        }
    }
    
    override func cancel() {
        request?.cancel()
        super.cancel()
    }
}

private var myContext = 0   // for KVO

class RssParserObserver: NSObject {
    var queue = NSOperationQueue()
    
    override init() {
        super.init()
        queue.addObserver(self, forKeyPath: "operations", options: .New, context: &myContext)
    }
    deinit {
        queue.removeObserver(self, forKeyPath: "operations", context: &myContext)
        println("deinit")
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate

            if (self.queue.operations.count == 0) {
                println("queue completed.")
                //println(appDelegate.newImgLinks)
                if (appDelegate.imgLinks.count > 0) {
                    appDelegate.imgLinks.shuffle()
                    appDelegate.getImageFromUrl()
                } else {
                    println("No image link found")
                    appDelegate.notify("No image link found")
                    appDelegate.stateToReady()
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}
