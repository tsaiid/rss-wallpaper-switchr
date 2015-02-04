//
//  RssParser.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/2.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

enum RssParserStatus: Int {
    case Init = 0
    case Done = 1
    case Error = 2
}

class RssParser: NSObject, NSXMLParserDelegate {
    var strXMLData:String = ""
    var currentElement:String = ""
    var elements = NSMutableDictionary()
    var title = NSMutableString()
    var link = NSMutableString()
    var imgLinks = NSMutableArray()
    var status = RssParserStatus.Init
    
    func parseRssFromUrl(rssUrl: String){
        var rss_url = NSURL(string: rssUrl)
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(rss_url!) { data, response, error in
            
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
                //println(self.imgLinks)
                println("parse succeeded.")
                // Do shuffle as needed. 
                //imgLinks.shuffle()
                //println(imgLinks[0])
            } else {
                println("parse xml error!")
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