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
    var imgLinks = NSMutableArray()
    
    var optWin = OptionsWindowController(windowNibName: "OptionsWindowController")

    @IBAction func btnParseRSS(sender: AnyObject) {
        // load rss url
        let defaults = NSUserDefaults.standardUserDefaults()
        if let rssUrl = defaults.stringForKey("rssUrl") {
            println("rss url \(rssUrl) loaded.")
            var rp: RssParser = RssParser()
            rp.parseRssFromUrl(rssUrl)
            imgLinks = rp.imgLinks
        } else {
            println("No predefined rss url.")
        }
        
    }
    
    @IBAction func btnSetBackground(sender: AnyObject) {
        setDesktopBackgrounds()
    }

    @IBAction func btnLoad(sender: AnyObject) {
        println("Load")

        // use NSUserDefaults to load Preference
        let defaults = NSUserDefaults.standardUserDefaults()
        if let rssUrl = defaults.stringForKey("rssUrl") {
            println(rssUrl)
            println(rssUrl.hash)
            println(rssUrl.md5())
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
        var workspace = NSWorkspace.sharedWorkspace()
        var error: NSError?
        
        if imgLinks.count > 0 {
            if let screenList = NSScreen.screens() as? [NSScreen] {
                println("Total screen: \(screenList.count)")
                for screen in screenList {
                    // set temp files
                    let fileManager = NSFileManager.defaultManager()
                    let tempDirectoryTemplate = NSTemporaryDirectory().stringByAppendingPathComponent("rws")
                    if fileManager.createDirectoryAtPath(tempDirectoryTemplate, withIntermediateDirectories: true, attributes: nil, error: nil) {
                        println("tempDir: \(tempDirectoryTemplate)")
                        imgLinks.shuffle()
                        var imgUrl = imgLinks[0]["link"] as String
                        var imgPath = "\(tempDirectoryTemplate)/\(imgUrl.md5()).jpg"
                        if let nsurl = NSURL(string: imgUrl) {
                            if let imageData = NSData(contentsOfURL: nsurl) {
                                if fileManager.createFileAtPath(imgPath, contents: imageData, attributes: nil) {
                                    println(imgPath)

                                    var nsImgPath = NSURL(fileURLWithPath: imgPath)
                                    var result: Bool = workspace.setDesktopImageURL(nsImgPath!, forScreen: screen, options: nil, error: &error)
                                    if result {
                                        println("\(screen) set to \(imgPath) from \(imgUrl)")
                                    } else {
                                        println("error")
                                        break
                                    }
                                }
                            }
                        }
                    } else {
                        println("createDirectoryAtPath NSTemporaryDirectory error.")
                    }

                    //let screenOptions:NSDictionary! = workspace.desktopImageOptionsForScreen(screen)
                    //let a  = screenOptions.NSWorkspaceDesktopImageScalingKey
                    //println(screenOptions[NSWorkspaceDesktopImageScalingKey])
                    //println(screenOptions[NSWorkspaceDesktopImageFillColorKey])
                }
            }
        } else {
            println("No image links.")
        }
        
    }

    func changeDesktopAfterSpaceDidChange(aNotification: NSNotification) {
        println("space changed")
        //setDesktopBackgrounds()
    }
}


