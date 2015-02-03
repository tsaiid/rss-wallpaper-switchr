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

    @IBAction func btnDetectScreenMode(sender: AnyObject) {
        if let screenList = NSScreen.screens() as? [NSScreen] {
            for screen in screenList {
                let width = screen.frame.width
                let height = screen.frame.height
                println("\(screen) size: \(width) x \(height)")
            }
        }
    }
    
    
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
                    imgLinks.shuffle()
                    var imgUrl = imgLinks[0]["link"] as String
                    var nsurl = NSURL(string: imgUrl)

                    let task = NSURLSession.sharedSession().dataTaskWithURL(nsurl!) {
                        data, response, error in
                        
                        // check for fundamental network issues (e.g. no internet, etc.)
                        if data == nil {
                            //handle error here
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
                        
                        // see if it is an image, and if so, save it and set as background
                        if let image = NSImage(data: data) as NSImage? {
                            
                            // set temp files
                            let fileManager = NSFileManager.defaultManager()
                            let tempDirectoryTemplate = NSTemporaryDirectory().stringByAppendingPathComponent("rws")
                            if fileManager.createDirectoryAtPath(tempDirectoryTemplate, withIntermediateDirectories: true, attributes: nil, error: nil) {
                                println("tempDir: \(tempDirectoryTemplate)")
                                var imgPath = "\(tempDirectoryTemplate)/\(imgUrl.md5()).jpg"
                                if fileManager.createFileAtPath(imgPath, contents: data, attributes: nil) {
                                    var error: NSError?
                                    var nsImgPath = NSURL(fileURLWithPath: imgPath)
                                    var result: Bool = workspace.setDesktopImageURL(nsImgPath!, forScreen: screen, options: nil, error: &error)
                                    if result {
                                        println("\(screen) set to \(imgPath) from \(imgUrl)")
                                    } else {
                                        println("error setDesktopImageURL")
                                        return
                                    }
                                }
                            } else {
                                println("createDirectoryAtPath NSTemporaryDirectory error.")
                            }
                        } else {
                            println("payload was not image!")
                        }
                    }
                    
                    task.resume()
                    
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


