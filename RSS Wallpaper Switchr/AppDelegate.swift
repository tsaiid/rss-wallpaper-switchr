//
//  AppDelegate.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/1.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

struct ScreenOrientation {
    var landscape = 0
    var portrait = 0
}

enum AppState {
    case Ready
    case Running
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!

    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var imgLinks = NSMutableArray()
    var screenOrientation = ScreenOrientation()
    var myPreference = Preference()
    var state = AppState.Ready
    var currentTry = [Int]()
    var switchTimer = NSTimer()
    
    lazy var optWin = OptionsWindowController(windowNibName: "OptionsWindowController")

    func detectScreenMode() {
        if let screenList = NSScreen.screens() as? [NSScreen] {
            screenOrientation = ScreenOrientation()
            
            for screen in screenList {
                let width = screen.frame.width
                let height = screen.frame.height
                println("\(screen) size: \(width) x \(height)")
                if width / height < 1 {
                    screenOrientation.portrait++
                } else {
                    screenOrientation.landscape++
                }
            }
        }
        
        println("\(screenOrientation)")
    }
    
    @IBAction func btnDetectScreenMode(sender: AnyObject) {
        detectScreenMode()
    }
    
    var rssParserSetWallpaperObserver = RssParserSetWallpaperObserver()
    
    func sequentSetBackgrounds() {
        if state != .Ready {
            println("A process is running. Please wait.")
            return
        }

        println("start sequence set backgrounds.")
        
        state = .Running

        // clean all var
        photos = [PhotoRecord]()
        photosForWallpaper = [PhotoRecord]()
        pendingOperationsObserver = PendingOperationsObserver()
        
        // load rss url
        let defaults = NSUserDefaults.standardUserDefaults()
        if let rssUrl = defaults.stringForKey("rssUrl") {
            println("rss url \(rssUrl) loaded.")
            rssParserSetWallpaperObserver.rssParser.parseRssFromUrl(rssUrl)
            
            // get image will be done after parseRssFromUrl done.
            // set background will be done after getImageFromUrl queue done.
        } else {
            println("No predefined rss url.")
        }
    }
    
    @IBAction func btnSequentSetBackgrounds(sender: AnyObject) {
        sequentSetBackgrounds()
    }
    
    @IBAction func btnParseRSS(sender: AnyObject) {
        
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

            // sometimes, the downloaded content is not a image.
            if downloader.photoRecord.state != .Downloaded {
                println("downloader.completionBlock: no downloaded image.")
                return
            }

            dispatch_async(dispatch_get_main_queue()) {
                let pendingOperations = self.pendingOperationsObserver.pendingOperations
                pendingOperations.downloadsInProgress.removeValueForKey(indexPath)
                println("dispatch done: \(indexPath). url: \(downloader.photoRecord.url)")
                var count = self.photosForWallpaper.count
                if count < self.targetAmount {
                    let screenLists = NSScreen.screens() as? [NSScreen]
                    let forScreen = screenLists![count]
                    if self.myPreference.fitScreenOrientation {
                        // if no fit, maximal try: 3 downloads.
                        println("currentTry: \(self.currentTry[count])")
                        if forScreen.orientation() == downloader.photoRecord.orientation || self.currentTry[count] > 2  {
                            downloader.photoRecord.forScreen = forScreen
                            self.photosForWallpaper.append(downloader.photoRecord)
                            println("photosForWallpaper: \(self.photosForWallpaper.count) for screen: \(forScreen)")
                        }
                        self.currentTry[count]++
                    } else {
                        downloader.photoRecord.forScreen = forScreen
                        self.photosForWallpaper.append(downloader.photoRecord)
                        println("photosForWallpaper: \(self.photosForWallpaper.count)")
                    }
                } else {
                    pendingOperations.downloadQueue.cancelAllOperations()
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
    
    func getImageFromUrl() {
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
    
    @IBAction func btnGetImageFromUrl(sender: AnyObject) {
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
    
    @IBAction func btnShowQueue(sender: AnyObject) {
        //println(pendingOperationsObserver.pendingOperations.downloadQueue.operationCount)
        println(imgLinks)
    }
    
    func determineTargetAmount() {
        // default set to screen numbers
        if let screenList = NSScreen.screens() as? [NSScreen] {
            targetAmount = screenList.count
            println("targetAmount set to \(targetAmount)")

            // init currentTry dictionary
            currentTry = [Int](count: targetAmount, repeatedValue: 0)
        }
    }

    @IBAction func btnLoad(sender: AnyObject) {
        /*
        println("Load")

        // use NSUserDefaults to load Preference
        let defaults = NSUserDefaults.standardUserDefaults()
        if let rssUrl = defaults.stringForKey("rssUrl") {
            println("option rssUrl: \(rssUrl)")
        }
        if let fitScreenOrientation = defaults.stringForKey("fitScreenOrientation") {
            println("option fitScreenOrientation: \(fitScreenOrientation)")
        }
        */
        println("preference: \(myPreference)")
    }
    
    @IBAction func btnSave(sender: AnyObject) {
        println("Save")

        // use NSUserDefaults to save Preference
        let defaults = NSUserDefaults.standardUserDefaults()
        let rssUrls = "http://feeds.feedburner.com/500pxPopularWallpapers"
        defaults.setObject(rssUrls, forKey: "rssUrl")
        defaults.setObject(false, forKey: "fitScreenOrientation")
        
        println("Saved")
    }
    
    override func awakeFromNib() {
        println("Loading statusBar")

        //Add statusBarItem and attach the menu from xib.
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = statusMenu
        statusBarItem.title = "RWS"
    }
    
    func timerDidFire() {
        println("\(myPreference.switchInterval) minutes passed.")
        //sequentSetBackgrounds()
    }

    func updateSwitchTimer(){
        let forMinutes = myPreference.switchInterval
        if switchTimer.valid {
            println("Timer: \(switchTimer) will be invalidated.")
            switchTimer.invalidate()
        }
        let switchInterval:NSTimeInterval = (Double(forMinutes) * 60)
        if  switchInterval > 0 {
            switchTimer = NSTimer.scheduledTimerWithTimeInterval(switchInterval, target: self, selector: Selector("timerDidFire"), userInfo: nil, repeats: true)
            println("Timer is set: \(switchTimer) for interval: \(forMinutes) minutes.")
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application

        // by notification, trigger switcher when space changes
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self,
            selector: "changeDesktopAfterSpaceDidChange:",
            name: NSWorkspaceActiveSpaceDidChangeNotification,
            object: NSWorkspace.sharedWorkspace())

        updateSwitchTimer()
    }

    // Menu Item Actions
    @IBAction func showOptionsWindow(sender: AnyObject) {
        optWin.showWindow(sender)
    }

    @IBAction func quitApplication(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(sender)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func setDesktopBackgrounds() {
        var workspace = NSWorkspace.sharedWorkspace()
        var error: NSError?
        
        if photosForWallpaper.count > 0 {
            for photo in photosForWallpaper {
                let screenList = NSScreen.screens() as? [NSScreen]
                if (find(screenList!, photo.forScreen!) != nil) {
                    photo.saveToLocalPath()
                    var result:Bool = workspace.setDesktopImageURL(photo.localPathUrl, forScreen: photo.forScreen!, options: nil, error: &error)
                    if result {
                        println("\(photo.forScreen!) set to \(photo.localPath) from \(photo.url) fitScreenOrientation: \(myPreference.fitScreenOrientation)")
                    } else {
                        println("error setDesktopImageURL for screen: \(photo.forScreen!)")
                        return
                    }
                }
            }
        } else {
            println("No image links.")
        }

        state = .Ready
    }

    func changeDesktopAfterSpaceDidChange(aNotification: NSNotification) {
        println("space changed")
        //setDesktopBackgrounds()
    }
}


