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

    private let statusBarItem: NSStatusItem
    private let activeIcon: NSImage
    private let deactiveIcon: NSImage
    var imgLinks = [String]()
    var myPreference = Preference()
    var rssParser = RssParserObserver()
    var imageDownload = ImageDownloaderObserver()
    var state = AppState.Ready
    var switchTimer = NSTimer()
    var targetScreens = [TargetScreen]()

    #if DEBUG
    var timeStart: CFAbsoluteTime?
    #endif

    var optWin: OptionsWindowController?
    var aboutWin: AboutWindowController?

    override init() {
        let statusBar = NSStatusBar.systemStatusBar()
        self.statusBarItem = statusBar.statusItemWithLength(-1)

        // init app icon, can switch between active and deactive icons
        self.activeIcon = NSImage(named: "Menu Icon Active")!
        self.activeIcon.setTemplate(true)
        self.deactiveIcon = NSImage(named: "Menu Icon")!
        self.deactiveIcon.setTemplate(true)

        statusBarItem.image = deactiveIcon

        super.init()
    }
    
    func getTargetScreens() {
        targetScreens = [TargetScreen]()
        if let screenList = NSScreen.screens() as? [NSScreen] {
            for screen in screenList {
                var targetScreen = TargetScreen(screen: screen)
                targetScreens.append(targetScreen)
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

    func menuIconDeactivate() {
        statusBarItem.image = deactiveIcon
    }

    func menuIconActivate() {
        statusBarItem.image = activeIcon
    }

    override func awakeFromNib() {
        println("Loading statusBar")

        // Attach the menu from xib. Cannot put in init()
        statusBarItem.menu = statusMenu
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
        println("Force cancelling operation.")
        rssParser.queue.cancelAllOperations()
        imageDownload.queue.cancelAllOperations()
        stateToReady()
        println("queue: \(imageDownload.queue.operations.count)")
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
        statusBarStartEndItem!.title = "Cancel Operations?"
        statusBarStartEndItem!.action = "statusBarCancellingOperations:"
    }

    func statusBarItemStatusToReady() {
        statusBarStartEndItem!.title = "Switch Wallpapers"
        statusBarStartEndItem!.action = "statusBarForceSetWallpapers:"
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