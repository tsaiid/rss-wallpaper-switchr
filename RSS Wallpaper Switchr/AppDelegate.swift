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
    var imgLinks = [String]()
    var state = AppState.Ready
    var switchTimer = NSTimer()

    #if DEBUG
    var timeStart: CFAbsoluteTime?
    #endif

    override func awakeFromNib() {
        println("Loading statusBar")

        // Attach the menu from xib. Cannot put in init()
        //statusBarItem.menu = statusMenu
    }

    // Timer related
    
    func timerDidFire() {
        println("\(Preference().switchInterval) minutes passed.")
        let switchrAPI = SwitchrAPI()
        switchrAPI.switchWallpapers()
    }

    func stopSwitchTimer() {
        if switchTimer.valid {
            println("Stopping Timer: \(switchTimer) will be invalidated.")
            switchTimer.invalidate()
        }
    }

    func updateSwitchTimer(){
        let forMinutes = Preference().switchInterval
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

    // Menu Item Actions
    @IBOutlet weak var statusBarStartEndItem: NSMenuItem!

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
        //menuIconActivate()
        //statusBarItemStatusToRunning()
    }

    func stateToReady() {
        state = .Ready
        //menuIconDeactivate()
        //statusBarItemStatusToReady()
    }


    //
    // notification handlers
    //
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