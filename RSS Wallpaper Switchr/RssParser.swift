//
//  RssParser.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/2.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

enum RssParserStatus: String {
    case Init = "Init"
    case Done = "Done"
    case Error = "Error"
}

class RssParser: NSObject, NSXMLParserDelegate {
    var strXMLData:String = ""
    var currentElement:String = ""
    var elements = NSMutableDictionary()
    var title = NSMutableString()
    var link = NSMutableString()
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

        let task = NSURLSession.sharedSession().dataTaskWithURL(rss_url!) { data, response, error in
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
            if let httpResponse = response as? NSHTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if statusCode != 200 {
                    println("NSHTTPURLResponse.statusCode = \(statusCode)")
                    println("Text of response = \(NSString(data: data, encoding: NSUTF8StringEncoding))")
                    return
                }
            }
            
            // parse data
            let p : NSXMLParser! = NSXMLParser(data: data)
            p.delegate = self
            self.imgLinks = []
            var success:Bool = p.parse()
            if success {
                println("parse succeeded.")
                self.status = .Done
            } else {
                println("parse xml error!")
                self.status = .Error
            }
        }
        task.resume()
    }
    
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName : String!, attributes attributeDict: NSDictionary!) {
        currentElement = elementName
        if elementName == "item" {
            elements = NSMutableDictionary.alloc()
            elements = [:]
            link = NSMutableString.alloc()
            link = ""
            title = NSMutableString.alloc()
            title = ""
        }
    }

    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        if currentElement == "title" {
            title.appendString(string)
        } else if currentElement == "link" {
            var trimmedString = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            link.appendString(trimmedString)
        }
    }

    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        if elementName == "item" {
            if !title.isEqual(nil) {
                elements.setObject(title, forKey: "title")
            }
            if !link.isEqual(nil) {
                elements.setObject(link, forKey: "link")
            }
            imgLinks.addObject(elements)
        }

    }
    
   
    func parser(parser: NSXMLParser!, parseErrorOccurred parseError: NSError!) {
        NSLog("failure error: %@", parseError)
    }
    
}

private var myContext = 0   // for KVO

class RssParserObserver: NSObject {
    var rssParser = RssParser()
    override init() {
        super.init()
        rssParser.addObserver(self, forKeyPath: "statusRaw", options: .New, context: &myContext)
    }
    deinit {
        rssParser.removeObserver(self, forKeyPath: "statusRaw", context: &myContext)
    }
}

class RssParserSetWallpaperObserver: RssParserObserver {
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            let appDelegate = NSApplication.sharedApplication().delegate as AppDelegate

            switch rssParser.status! {
            case .Done:
                println("RSS Parser done!")
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

class RssParserValidateObserver: RssParserObserver {
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            switch rssParser.status! {
            case .Done:
                println("RSS Parser validation done!")
                println("\(rssParser.imgLinks.count) images found.")
            case .Error:
                println("RSS Parser error!")
            default:
                println("Unknown status!?")
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}
