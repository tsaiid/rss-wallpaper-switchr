//
//  AppDelegate.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/1.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

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
    var myPreference = Preference()
    var state = AppState.Ready
    var currentTry = [Int]()
    var switchTimer = NSTimer()
    var targetScreens = [TargetScreen]()
    
    lazy var optWin = OptionsWindowController(windowNibName: "OptionsWindowController")

    func detectScreenMode() {
        if let screenList = NSScreen.screens() as? [NSScreen] {
            for screen in screenList {
                var targetScreen = TargetScreen(screen: screen)
            }
        }
    }
    
    @IBAction func btnDetectScreenMode(sender: AnyObject) {
        detectScreenMode()
    }
    
    var rssParserSetWallpaperObserver = RssParserSetWallpaperObserver()

    func getTargetScreens() {
        if let screenList = NSScreen.screens() as? [NSScreen] {
            for screen in screenList {
                var targetScreen = TargetScreen(screen: screen)
                self.targetScreens.append(targetScreen)
            }
        }
    }
    
    func sequentSetBackgrounds() {
        if state != .Ready {
            println("A process is running. Please wait.")
            return
        }

        println("start sequence set backgrounds.")
        
        stateToRunning()
        getTargetScreens()

        // clean all var
        photos = [PhotoRecord]()
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
    var pendingOperationsObserver = PendingOperationsObserver()

    func getNoWallpaperScreen() -> TargetScreen? {
        for targetScreen in targetScreens {
            if targetScreen.wallpaperPhoto == nil {
                //println("Some targetScreens have no wallpaperPhoto.")
                return targetScreen
            }
        }
        return nil
    }

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

                let this_photo = downloader.photoRecord
                println("dispatch done: \(indexPath). url: \(this_photo.url)")

                if let targetScreen = self.getNoWallpaperScreen() {
                    let lowerLimit = self.myPreference.imageLowerLimitLength
                    if self.myPreference.fitScreenOrientation {
                        // if no fit, maximal try: 3 downloads.
                        targetScreen.currentTry++
                        if ((targetScreen.orientation == this_photo.orientation) || targetScreen.currentTry > 2)  {
                            if !self.myPreference.filterSmallerImages || lowerLimit <= 0 {
                                targetScreen.wallpaperPhoto = this_photo
                                println("No image size lower limit set. Too much try: \(targetScreen.currentTry). Selected \(this_photo.url)")
                            } else {
                                if this_photo.fitSizeLimitation(lowerLimit) {
                                    targetScreen.wallpaperPhoto = this_photo
                                    println("imageLowerLimitLength is on. Size (\(this_photo.imgRep.pixelsWide) x \(this_photo.imgRep.pixelsHigh)) is more than limitation: \(lowerLimit). Selected \(this_photo.url)")
                                } else {
                                    println("imageLowerLimitLength is on. Size (\(this_photo.imgRep.pixelsWide) x \(this_photo.imgRep.pixelsHigh)) not fit limitation: \(lowerLimit). Not selected.")

                                }
                            }
                        } else {
                            println("Orientation not fit: screen: \(targetScreen.orientation), photo: \(this_photo.orientation). Not selected. currentTry: \(targetScreen.currentTry)")
                        }
                    } else {
                        if !self.myPreference.filterSmallerImages || lowerLimit <= 0 {
                            targetScreen.wallpaperPhoto = this_photo
                            println("No image size lower limit set. Selected \(this_photo.url)")
                        } else {
                            if this_photo.fitSizeLimitation(lowerLimit) {
                                targetScreen.wallpaperPhoto = this_photo
                                println("imageLowerLimitLength is on. Size is more than limitation: \(lowerLimit). Selected \(this_photo.url)")
                            } else {
                                println("imageLowerLimitLength is on. Size \(this_photo.image!.size.width) x \(this_photo.image!.size.height) not fit limitation: \(lowerLimit). Not selected.")

                            }
                        }
                    }

                    // check here to save 1 photo download time.
                    if self.getNoWallpaperScreen() == nil {
                        println("All targetScreens are done. Save 1 download time.")
                    }
                } else {
                    println("All targetScreens are done.")
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

    func menuIconDeactivate() {
        let menuIcon = NSImage(named: "Menu Icon")
        menuIcon?.setTemplate(true)
        statusBarItem.button?.image = menuIcon
        statusBarItem.menu = statusMenu
    }

    func menuIconActivate() {
        let menuIcon = NSImage(named: "Menu Icon Active")
        menuIcon?.setTemplate(true)
        statusBarItem.button?.image = menuIcon
        statusBarItem.menu = statusMenu
    }

    override func awakeFromNib() {
        println("Loading statusBar")

        //Add statusBarItem and attach the menu from xib.
        statusBarItem = statusBar.statusItemWithLength(-1)
        menuIconDeactivate()
    }

    // Timer related
    
    func timerDidFire() {
        println("\(myPreference.switchInterval) minutes passed.")
        sequentSetBackgrounds()
    }

    func stopSwitchTimer() {
        if switchTimer.valid {
            println("Stopping Timer: \(switchTimer) will be invalidated.")
            switchTimer.invalidate()
        }
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

        #if DEBUG
            window.makeKeyAndOrderFront(self)
        #endif

        // by notification, trigger switcher when space changes
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self,
            selector: "changeDesktopAfterSpaceDidChange:",
            name: NSWorkspaceActiveSpaceDidChangeNotification,
            object: NSWorkspace.sharedWorkspace())

        updateSwitchTimer()

        // test notification
        /*
        var notif = NSUserNotification()
        notif.title = "test"
        notif.informativeText = "ttt"
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notif)
        */
    }

    // Menu Item Actions
    @IBAction func statusBarForceSetWallpapers(sender: AnyObject) {
        println("Force set wallpapers.")
        sequentSetBackgrounds()
    }

    @IBAction func showOptionsWindow(sender: AnyObject) {
        optWin.showWindow(sender)
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
    }

    @IBAction func quitApplication(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(sender)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func stateToRunning() {
        state = .Running
        menuIconActivate()
    }

    func stateToReady() {
        state = .Ready
        menuIconDeactivate()
    }

    func setDesktopBackgrounds() {
        var workspace = NSWorkspace.sharedWorkspace()
        var error: NSError?
        
        if getNoWallpaperScreen() == nil {
            for targetScreen in targetScreens {
                let screenList = NSScreen.screens() as? [NSScreen]
                if (find(screenList!, targetScreen.screen!) != nil) {
                    if let photo = targetScreen.wallpaperPhoto {
                    photo.saveToLocalPath()
                    var result:Bool = workspace.setDesktopImageURL(photo.localPathUrl, forScreen: targetScreen.screen!, options: nil, error: &error)
                    if result {
                        println("\(targetScreen.screen!) set to \(photo.localPath) from \(photo.url) fitScreenOrientation: \(myPreference.fitScreenOrientation)")
                    } else {
                        println("error setDesktopImageURL for screen: \(targetScreen.screen!)")
                        return
                    }
                    } else {
                        println("No wallpaper set for \(targetScreen.screen!)")
                    }
                }
            }
        } else {
            println("No image links.")
        }

        stateToReady()
    }

    func changeDesktopAfterSpaceDidChange(aNotification: NSNotification) {
        println("space changed")
        //setDesktopBackgrounds()
    }
}


