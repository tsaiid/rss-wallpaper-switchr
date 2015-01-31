//
//  ViewController.swift
//  Background Changer
//
//  Created by I-Ta Tsai on 2015/1/31.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSXMLParserDelegate {
    var strXMLData:String = ""
    var currentElement:String = ""
    var passData:Bool=false
    var passName:Bool=false
    
    @IBOutlet weak var testLabel: NSTextField!

    @IBAction func buttonChange(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        
        appDelegate.setDesktopBackgrounds()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        var rss_url = NSURL(string: "http://feeds.feedburner.com/500pxPopularWallpapers")
        let p : NSXMLParser! = NSXMLParser(contentsOfURL: rss_url)
        p.delegate = self
        var success:Bool = p.parse()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func parser(parser: NSXMLParser!,didStartElement elementName: String!, namespaceURI: String!, qualifiedName : String!, attributes attributeDict: NSDictionary!) {
        currentElement=elementName
        if(elementName=="id" || elementName=="name" || elementName=="cost" || elementName=="description")
        {
            if(elementName=="name"){
                passName=true;
            }
            passData=true;
        }
    }
    
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        currentElement="";
        if(elementName=="id" || elementName=="name" || elementName=="cost" || elementName=="description")
        {
            if(elementName=="name"){
                passName=false;
            }
            passData=false;
        }
    }
    
    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        if(passName){
            strXMLData=strXMLData+"\n\n"+string
        }
        
        if(passData)
        {
            println(string)
        }
    }
    
    func parser(parser: NSXMLParser!, parseErrorOccurred parseError: NSError!) {
        NSLog("failure error: %@", parseError)
    }
}

