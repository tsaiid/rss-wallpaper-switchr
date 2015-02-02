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

    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItem : NSMenuItem = NSMenuItem()
    
    var optWin = OptionsWindowController(windowNibName: "OptionsWindowController")

    @IBAction func btnParseRSS(sender: AnyObject) {
        // load rss url
        let defaults = NSUserDefaults.standardUserDefaults()
        if let rssUrl = defaults.stringForKey("rssUrl") {
            println("rss url \(rssUrl) loaded.")
            var rp: RssParser = RssParser()
            rp.parseRssFromUrl(rssUrl)
            
        } else {
            println("No predefined rss url.")
        }
        
    }

    @IBAction func btnLoad(sender: AnyObject) {
        println("Load")

        // use NSUserDefaults to load Preference
        let defaults = NSUserDefaults.standardUserDefaults()
        if let rssUrl = defaults.stringForKey("rssUrl") {
            println(rssUrl)
        }
        
    }
    @IBAction func btnSave(sender: AnyObject) {
        println("Save")

        // use NSUserDefaults to save Preference
        let defaults = NSUserDefaults.standardUserDefaults()
        let rssUrls = "http://feeds.feedburner.com/500pxPopularWallpapers"
        defaults.setObject(rssUrls, forKey: "rssUrl")
        
        println("Saved")
    }
    
    override func awakeFromNib() {
        //theLabel.stringValue = "You've pressed the button \n \(buttonPresses) times!"

        println(statusBar)

        //Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        statusBarItem.title = "Presses"
        
        //Add menuItem to menu
        menuItem.title = "Options"
        menuItem.action = Selector("showOptionsWindow:")
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
    }

    func showOptionsWindow(sender: AnyObject){
        //self.window!.orderFront(self)
        optWin.beginSheet(self.window)
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


