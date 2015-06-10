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

enum RssParserStatus: String {
    case Init = "Init"
    case Done = "Done"
    case Error = "Error"
}

class RssParser: NSObject {
    var elements = NSMutableDictionary()
    var imgLinks = NSMutableArray()
    dynamic private(set) var statusRaw: String?
    var status:RssParserStatus? {
        didSet {
            statusRaw = status?.rawValue
        }
    }
    
    func parseRssFromUrl(rssUrl: String){
        var rss_url = NSURL(string: rssUrl)

        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        println("timeout: \(configuration.timeoutIntervalForResource)")
        configuration.timeoutIntervalForResource = 1 // seconds

        Alamofire.request(.GET, rss_url!)
            .responseString { (request, response, data, error) in
                if error != nil {
                    println("Error: \(error)")
                    println("Data: \(data)")
                    self.status = .Error
                    return
                }

                // check for fundamental network issues (e.g. no internet, etc.)
                if data == nil {
                    println("dataTaskWithURL error: \(error)")
                    return
                }
            
                // make sure web server returned 200 status code (and not 404 for bad URL or whatever)
                if let httpResponse = response as NSHTTPURLResponse? {
                    let statusCode = httpResponse.statusCode
                    if statusCode != 200 {
                        println("NSHTTPURLResponse.statusCode = \(statusCode)")
                        println("Text of response = \(data)")
                        return
                    }
                }
            
                // parse data
                self.imgLinks = []
                let xml = SWXMLHash.lazy(data!)
                for item in xml["rss"]["channel"]["item"] {
                    self.elements = NSMutableDictionary.alloc()
                    self.elements = [:]
                    if let imgUrl = item["link"].element?.text {
                        if let imgTitle = item["title"].element?.text {
                            if !imgTitle.isEqual(nil) {
                                self.elements.setObject(imgTitle, forKey: "title")
                            }
                            if !imgUrl.isEqual(nil) {
                                self.elements.setObject(imgUrl, forKey: "link")
                            }
                            self.imgLinks.addObject(self.elements)
                        }
                    }
                }
                self.status = .Done
        }
    }
}

private var myContext = 0   // for KVO

class RssParserObserver: NSObject {
    var rssParser = RssParser()
    var queue = NSOperationQueue()
    
    override init() {
        super.init()
        rssParser.addObserver(self, forKeyPath: "statusRaw", options: .New, context: &myContext)
        queue.addObserver(self, forKeyPath: "operations", options: .New, context: &myContext)
    }
    deinit {
        rssParser.removeObserver(self, forKeyPath: "statusRaw", context: &myContext)
        queue.removeObserver(self, forKeyPath: "operations", context: &myContext)
        println("deinit")
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            if (self.queue.operations.count == 0) {
                println("queue completed.")
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}

class RssParserSetWallpaperObserver: RssParserObserver {
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate

            switch rssParser.status! {
            case .Done:
                println("RSS Parser done!")
                //println("\(rssParser.imgLinks.count) images from RSS feed.")
                println(rssParser.imgLinks)
                appDelegate.imgLinks = rssParser.imgLinks
                appDelegate.imgLinks.shuffle()
                
                // get image from url
                appDelegate.getImageFromUrl()
                
                // set background will be done after getImageFromUrl queue done. 
            case .Error:
                println("RSS Parser error!")
                appDelegate.stateToReady()
            default:
                println("Unknown status!?")
                appDelegate.stateToReady()
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}
