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
