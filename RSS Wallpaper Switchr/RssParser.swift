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

    deinit {
        if DEBUG_DEINIT {
            println("ParseRssOperation deinit.")
        }
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
                        var imgLinks = [String]()
                        for item in xml["rss"]["channel"]["item"] {
                            if let link = item["link"].element?.text {
                                if !contains(imgLinks, link) {
                                    imgLinks += [link]
                                }
                            }
                        }

                        self.parseRssCompletionHandler(responseObject: imgLinks, error: error)
                    }
                }

                // however error or succeeded, it should complete.
                self.completeOperation()
        }
    }
    
    override func cancel() {
        request?.cancel()
        super.cancel()
    }
}

class RssParser: NSObject {
    var queue = NSOperationQueue()
    var state = ApiState.Ready
    
    override init() {
        super.init()
    }

    deinit {
        if DEBUG_DEINIT {
            println("RssParser deinit.")
        }
    }

    func cancel() {
        state = .Cancelled
        queue.cancelAllOperations()
    }
}
