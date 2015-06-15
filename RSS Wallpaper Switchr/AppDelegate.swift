//
//  AppDelegate.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/1.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa
import Alamofire
import SWXMLHash

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
    var imgLinks = [String]()
    var myPreference = Preference()
    let rssParser = RssParserObserver()
    let imageDownload = ImageDownloadObserver()
    var state = AppState.Ready
    var switchTimer = NSTimer()
    var targetScreens = [TargetScreen]()

    #if DEBUG
    var timeStart: CFAbsoluteTime?
    #endif

    var optWin: OptionsWindowController?
    var aboutWin: AboutWindowController?

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
    
    func getTargetScreens() {
        targetScreens = [TargetScreen]()
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

        #if DEBUG
        timeStart = CFAbsoluteTimeGetCurrent()
        #endif

        stateToRunning()

        // clean all var
        getTargetScreens()
        imgLinks = [String]()

        // load rss url
        let rssUrls = myPreference.rssUrls
        println(rssUrls.count)
        if rssUrls.count == 0 {
            notify("No predefined RSS url.")
            stateToReady()
            return
        }
        
        for url in rssUrls {
            println(url)
            let operation = ParseRssOperation(URLString: url as! String) {
                (responseObject, error) in
                
                if responseObject == nil {
                    // handle error here
                    
                    println("failed: \(error)")
                } else {
                    //println("responseObject=\(responseObject!)")
                    self.imgLinks += responseObject as! [String]
                }
            }
            rssParser.queue.addOperation(operation)
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

    func getNoWallpaperScreen() -> TargetScreen? {
        for targetScreen in targetScreens {
            if targetScreen.wallpaperPhoto == nil {
                //println("Some targetScreens have no wallpaperPhoto.")
                return targetScreen
            }
        }
        return nil
    }

    func getImageFromUrl() {
        imageDownload.queue.maxConcurrentOperationCount = 2

        println("image queue: \(imageDownload.queue.operations.count)")
        
        for imgLink in imgLinks {
            let urlStr:String = imgLink as String

            let operation = DownloadImageOperation(URLString: urlStr) {
                (responseObject, error) in
                
                if responseObject == nil {
                    // handle error here
                    
                    println("failed: \(error)")
                } else {
                    println("responseObject=\(responseObject!)")
                    if let targetScreen = self.getNoWallpaperScreen() {
                        var this_photo: PhotoRecord? = responseObject as? PhotoRecord
                        if this_photo!.isSuitable(targetScreen, preference: self.myPreference) {
                            targetScreen.wallpaperPhoto = this_photo
                        }
                    } else {
                        println("All targetScreens are done.")
                        self.imageDownload.queue.cancelAllOperations()
                    }
                }
            }
            imageDownload.queue.addOperation(operation)
        }
    }
    
    @IBAction func btnGetImageFromUrl(sender: AnyObject) {
    }
    
    @IBAction func btnShowQueue(sender: AnyObject) {
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
    
    @IBAction func btnTestAlamofire(sender: AnyObject) {
        rssParser.queue.maxConcurrentOperationCount = 1
        imgLinks = [String]()

        #if DEBUG
            timeStart = CFAbsoluteTimeGetCurrent()
        #endif
        
        var rssUrl = ["http://feed.tsai.it/500px/popular.rss", "http://feed.tsai.it/flickr/interestingness.rss"]
        
        for url in rssUrl {
            println(url)
            let operation = ParseRssOperation(URLString: url) {
                (responseObject, error) in

                if responseObject == nil {
                    // handle error here
                    
                    println("failed: \(error)")
                } else {
                    //println("responseObject=\(responseObject!)")
                    self.imgLinks += responseObject as! [String]
                }
            }
            rssParser.queue.addOperation(operation)
        }
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
    
    // App init
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application

        #if DEBUG
            window.makeKeyAndOrderFront(self)
        #endif

        // for notification of space changes
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self,
            selector: "changeDesktopAfterSpaceDidChange:",
            name: NSWorkspaceActiveSpaceDidChangeNotification,
            object: NSWorkspace.sharedWorkspace())

        // for notification of screensavor and screen lock
        /*
            // do not need to handle with screensaver, it also trigger screenIsLocked and screenIsUnlocked
            name: "com.apple.screensaver.didstart",
            name: "com.apple.screensaver.didstop",
        */

        NSDistributedNotificationCenter.defaultCenter().addObserver(self,
            selector: "screenLockHandler:",
            name: "com.apple.screenIsLocked",
            object: nil)

        NSDistributedNotificationCenter.defaultCenter().addObserver(self,
            selector: "screenLockHandler:",
            name: "com.apple.screenIsUnlocked",
            object: nil)

        updateSwitchTimer()
    }

    func notify(msg: NSString!, title: NSString = "Error"){
        var userNotify = NSUserNotification()
        userNotify.title = title as String
        userNotify.informativeText = msg as String
        
        #if DEBUG
            println(msg)
        #endif

        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(userNotify)
    }

    // Menu Item Actions
    @IBOutlet weak var statusBarStartEndItem: NSMenuItem!
    @IBAction func statusBarForceSetWallpapers(sender: AnyObject) {
        println("Force set wallpapers.")
        updateSwitchTimer()
        sequentSetBackgrounds()
    }

    func statusBarCancellingOperations(sender: AnyObject) {
        println("self: \(self)")
        println("Force cancelling operation.")
        rssParser.queue.cancelAllOperations()
        imageDownload.queue.cancelAllOperations()
        stateToReady()
        println("queue: \(imageDownload.queue.operations.count)")
        println("self: \(self)")
    }

    @IBAction func showOptionsWindow(sender: AnyObject) {
        optWin = OptionsWindowController(windowNibName: "OptionsWindow")
        optWin!.showWindow(sender)
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
    }

    @IBAction func showAboutWindow(sender: AnyObject) {
        aboutWin = AboutWindowController(windowNibName: "AboutWindow")
        aboutWin!.showWindow(sender)
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
    }

    @IBAction func quitApplication(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(sender)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func statusBarItemStatusToRunning() {
        statusBarStartEndItem.title = "Cancel Operations?"
        statusBarStartEndItem.action = "statusBarCancellingOperations:"
    }

    func statusBarItemStatusToReady() {
        statusBarStartEndItem.title = "Switch Wallpapers"
        statusBarStartEndItem.action = "statusBarForceSetWallpapers:"
    }

    func stateToRunning() {
        state = .Running
        menuIconActivate()
        statusBarItemStatusToRunning()
    }

    func stateToReady() {
        state = .Ready
        menuIconDeactivate()
        statusBarItemStatusToReady()
    }

    private func getDesktopImageOptions(scalingMode: Int) -> [NSObject : AnyObject]? {
        var options: [NSObject : AnyObject]?
        var scaling: NSImageScaling

        switch scalingMode {
        case 1: // fill the screen
            scaling = .ImageScaleProportionallyUpOrDown
            options = [
                "NSWorkspaceDesktopImageScalingKey": NSImageScaling.ImageScaleProportionallyUpOrDown.rawValue,
                "NSWorkspaceDesktopImageAllowClippingKey": true
            ]
        case 2: // fit screen size
            options = [
                "NSWorkspaceDesktopImageScalingKey": NSImageScaling.ImageScaleProportionallyUpOrDown.rawValue,
                "NSWorkspaceDesktopImageAllowClippingKey": false
            ]
        case 3: // centering
            options = [
                "NSWorkspaceDesktopImageScalingKey": NSImageScaling.ImageScaleNone.rawValue,
                "NSWorkspaceDesktopImageAllowClippingKey": false
            ]
        default:
            return nil
        }

        return options
    }

    func setDesktopBackgrounds() {
        var workspace = NSWorkspace.sharedWorkspace()
        var error: NSError?

        // set desktop image options
        var options = getDesktopImageOptions(myPreference.scalingMode)
        //println("scaling options: \(options)")

        if getNoWallpaperScreen() == nil {
            for targetScreen in targetScreens {
                let screenList = NSScreen.screens() as? [NSScreen]
                if (find(screenList!, targetScreen.screen!) != nil) {
                    if let photo = targetScreen.wallpaperPhoto {
                        var result:Bool = workspace.setDesktopImageURL(photo.localPathUrl, forScreen: targetScreen.screen!, options: options, error: &error)
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
            println("Wallpaper changes!", title: "Successful")
        } else {
            println("getNoWallpaperScreen incomplete.")
        }

        #if DEBUG
        let timeElapsed = CFAbsoluteTimeGetCurrent() - timeStart!
        println("time used: \(timeElapsed)")
        #endif

        stateToReady()
    }

    func changeDesktopAfterSpaceDidChange(aNotification: NSNotification) {
        println("space changed")
        //setDesktopBackgrounds()
    }
    
    func screenLockHandler(aNotification: NSNotification) {
        println("screen status: \(aNotification.name)")
        if aNotification.name == "com.apple.screenIsLocked" {
            stopSwitchTimer()
        } else {
            updateSwitchTimer()
        }
    }
}