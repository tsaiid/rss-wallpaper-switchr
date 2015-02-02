//
//  RssParser.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/2.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

class RssParser: NSObject, NSXMLParserDelegate {
    var strXMLData:String = ""
    var currentElement:String = ""
    var elements = NSMutableDictionary()
    var title = NSMutableString()
    var link = NSMutableString()
    var imgLinks = NSMutableArray()
    
    func parseRssFromUrl(rssUrl: String){
        var rss_url = NSURL(string: rssUrl)
        let p : NSXMLParser! = NSXMLParser(contentsOfURL: rss_url)
        p.delegate = self
        imgLinks = []
        var success:Bool = p.parse()
        if success {
            //println(imgLinks)
            println("parse succeeded.")
            // Do shuffle as needed. 
            //imgLinks.shuffle()
            //println(imgLinks[0])
        } else {
            println("parse xml error!")
        }
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