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
    
    lazy var optWin = OptionsWindowController(windowNibName: "OptionsWindowController")

    @IBAction func btnDetectScreenMode(sender: AnyObject) {
        if let screenList = NSScreen.screens() as? [NSScreen] {
            for screen in screenList {
                let width = screen.frame.width
                let height = screen.frame.height
                println("\(screen) size: \(width) x \(height)")
            }
        }
    }
    
    var rssParserObserver = RssParserObserver()
    
    @IBAction func btnParseRSS(sender: AnyObject) {
        // load rss url
        let defaults = NSUserDefaults.standardUserDefaults()
        if let rssUrl = defaults.stringForKey("rssUrl") {
            println("rss url \(rssUrl) loaded.")
            rssParserObserver.rssParser.parseRssFromUrl(rssUrl)
            imgLinks = rssParserObserver.rssParser.imgLinks
        } else {
            println("No predefined rss url.")
        }
        
    }
    
    @IBAction func btnSetBackground(sender: AnyObject) {
        setDesktopBackgrounds()
    }

    // use NSOperation and NSOperationQueue to handle picture downloading.
    var photos = [PhotoRecord]()
    var photosForWallpaper = [PhotoRecord]()
    var targetAmount:Int = 1    // may be determined by options or screen numbers.
    var pendingOperationsObserver = PendingOperationsObserver()

    func startDownloadForRecord(photoDetails: PhotoRecord, indexPath: String){
        if let downloadOperation = pendingOperationsObserver.pendingOperations.downloadsInProgress[indexPath] {
            return
        }
        
        let downloader = ImageDownloader(photoRecord: photoDetails)

        downloader.completionBlock = {
            if downloader.cancelled {
                return
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.pendingOperationsObserver.pendingOperations.downloadsInProgress.removeValueForKey(indexPath)
                println("dispatch done: \(indexPath). url: \(downloader.photoRecord.url)")
                var count = self.photosForWallpaper.count
                if count < self.targetAmount {
                    self.photosForWallpaper.append(downloader.photoRecord)
                    println("photosForWallpaper: \(self.photosForWallpaper.count)")
                } else {
                    self.pendingOperationsObserver.pendingOperations.downloadQueue.cancelAllOperations()
                }
            }
        }

        pendingOperationsObserver.pendingOperations.downloadsInProgress[indexPath] = downloader

        pendingOperationsObserver.pendingOperations.downloadQueue.addOperation(downloader)
    }
    
    func startOperationsForPhotoRecord(photoDetails: PhotoRecord, indexPath: String){
        switch (photoDetails.state) {
        case .New:
            startDownloadForRecord(photoDetails, indexPath: indexPath)
        case .Downloaded:
            println("downloaded. url: \(photoDetails.url)")
        default:
            println("do nothing")
        }
    }
    
    @IBAction func btnGetImageFromUrl(sender: AnyObject) {
        var count:Int = 0
        var nsImgArr:NSMutableArray = []
        
        determineTargetAmount()
        
        for imgLink in imgLinks {
            let urlStr:String = imgLink["link"] as? String ?? ""
            let name:String = imgLink["name"] as? String ?? ""
            let url = NSURL(string: urlStr)
            if url != nil {
                let photoRecord = PhotoRecord(name:name, url:url!)
                if (find(photos, photoRecord) == nil) {
                    photos.append(photoRecord)
                }
            }
        }
        
        for photo in photos {
            startOperationsForPhotoRecord(photo, indexPath: photo.url.absoluteString!.md5())
        }
    }
    
    func determineTargetAmount() {
        // default set to screen numbers
        if let screenList = NSScreen.screens() as? [NSScreen] {
            targetAmount = screenList.count
            println("targetAmount set to \(targetAmount)")
        }
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
    
    func timerDidFire() {
        //println("times up")
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application

        // by notification, trigger switcher when space changes
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self,
            selector: "changeDesktopAfterSpaceDidChange:",
            name: NSWorkspaceActiveSpaceDidChangeNotification,
            object: NSWorkspace.sharedWorkspace())
        
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timerDidFire"), userInfo: nil, repeats: true)
    }

    func showOptionsWindow(sender: AnyObject){
        optWin.showWindow(sender)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func setDesktopBackgrounds() {
        var workspace = NSWorkspace.sharedWorkspace()
        var error: NSError?
        
        if photosForWallpaper.count > 0 {
            if let screenList = NSScreen.screens() as? [NSScreen] {
                println("Total screen: \(screenList.count)")
                for (scrIndex, screen) in enumerate(screenList) {
                    println("\(scrIndex): \(screen)")
                    if photosForWallpaper.count >= screenList.count {
                        photosForWallpaper[scrIndex].saveToLocalPath()
                        
                        var result:Bool = workspace.setDesktopImageURL(photosForWallpaper[scrIndex].localPathUrl, forScreen: screen, options: nil, error: &error)
                        if result {
                            println("\(screen) set to \(photosForWallpaper[scrIndex].localPath) from \(photosForWallpaper[scrIndex].url)")
                        } else {
                            println("error setDesktopImageURL")
                            return
                        }
                    } else {
                        println("pictures are not enough.")
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


