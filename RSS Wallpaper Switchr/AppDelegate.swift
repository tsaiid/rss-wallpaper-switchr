//
//  AppDelegate.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/1.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var myButton: NSButton!

    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItem : NSMenuItem = NSMenuItem()

    override func awakeFromNib() {
        //theLabel.stringValue = "You've pressed the button \n \(buttonPresses) times!"

        println(statusBar)

        //Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        statusBarItem.title = "Presses"
        
        //Add menuItem to menu
        menuItem.title = "Clicked"
        menuItem.action = Selector("setWindowVisible:")
        menuItem.keyEquivalent = ""
        menu.addItem(menuItem)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application

        // by notification, trigger switcher when space changes
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self,
            selector: "changeDesktopAfterSpaceDidChange:",
            name: NSWorkspaceActiveSpaceDidChangeNotification,
            object: NSWorkspace.sharedWorkspace())

        //self.window!.orderOut(self)

    }

    func setWindowVisible(sender: AnyObject){
        //self.window!.orderFront(self)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func setDesktopBackgrounds() {
        var imgurl = NSURL(fileURLWithPath: "/Users/tsaiid/git/rss-wallpaper-switchr/15526028562_197501ee89_o.jpg")
        var workspace = NSWorkspace.sharedWorkspace()
        var error: NSError?
        
        if let screenList = NSScreen.screens() as? [NSScreen] {
            println(screenList.count)
            for screen in screenList {
                //                var result : Bool = workspace.setDesktopImageURL(imgurl!, forScreen: screen, options: nil, error: &error)
                
                //                if !result {
                //testLabel.stringValue = "error"
                //                    println("error")
                //                    break
                //                }
                //let screenOptions:NSDictionary! = workspace.desktopImageOptionsForScreen(screen)
                //let a  = screenOptions.NSWorkspaceDesktopImageScalingKey
                //println(screenOptions[NSWorkspaceDesktopImageScalingKey])
                //println(screenOptions[NSWorkspaceDesktopImageFillColorKey])
            }
            
            //            testLabel.stringValue = "Changed"
        }
        
        
    }

    func changeDesktopAfterSpaceDidChange(aNotification: NSNotification) {
        println("space changed")
        //setDesktopBackgrounds()
    }
}

class RssParser: NSObject, NSXMLParserDelegate {
    var strXMLData:String = ""
    var currentElement:String = ""
    var passData:Bool=false
    var passName:Bool=false

    func parseRssFromUrl(){
        var rss_url = NSURL(string: "http://feeds.feedburner.com/500pxPopularWallpapers")
        let p : NSXMLParser! = NSXMLParser(contentsOfURL: rss_url)
        p.delegate = self
        var success:Bool = p.parse()
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

