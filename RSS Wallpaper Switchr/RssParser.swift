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

class ParseRssOperation : ConcurrentOperation {
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
                if error != nil {
                    println("ParseRss error: \(error)")
                }
                //println(data)

                if self.cancelled {
                    println("ParseRssOperation.main() Alamofire.download cancelled while downlading. Not proceed into PhotoRecord.")
                } else {
                    if data != nil {
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
                    }
                }

                // however error or succeeded, it should complete.
                self.completeOperation()
        }
    }
    
    override func cancel() {
        // should also cancel Alamofire request, but it results in strange memory problem!
        //request?.cancel()
        super.cancel()
    }
}

private var myContext = 0   // for KVO

protocol RssParserObserverDelegate {
    func rssDidParse()
}

class RssParserObserver: NSObject {
    var delegate: RssParserObserverDelegate?
    var queue = NSOperationQueue()
    
    init(delegate: RssParserObserverDelegate) {
        super.init()
        self.delegate = delegate
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
                if (appDelegate.imgLinks.count > 0) {
                    appDelegate.imgLinks.shuffle()
                    self.delegate?.rssDidParse()
                } else {
                    println("No image link found")
                    notify("No image link found")
                    appDelegate.stateToReady()
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}
