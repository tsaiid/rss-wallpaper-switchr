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
class AppDelegate: NSObject, NSApplicationDelegate, SwitchrAPIDelegate {
    var statusMenuController: StatusMenuController!
    var state = AppState.Ready
    var switchTimer = NSTimer()
    var switchrAPI: SwitchrAPI?

    #if DEBUG
    var timeStart: CFAbsoluteTime?  // DEBUG_SHOW_TIME_ELAPSED
    #endif

    //
    // Init
    //

    override func awakeFromNib() {
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application

        // for notification of space changes
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self,
            selector: "changeDesktopAfterSpaceDidChange:",
            name: NSWorkspaceActiveSpaceDidChangeNotification,
            object: NSWorkspace.sharedWorkspace())

        // for notification of screensavor and screen lock
        // Both NSWorkspace and NSDistributedNotificationCenter need to exist.
        // Different version osx sends different notification.
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self,
            selector: "screenLockHandler:",
            name: NSWorkspaceScreensDidWakeNotification,
            object: NSWorkspace.sharedWorkspace())

        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self,
            selector: "screenLockHandler:",
            name: NSWorkspaceScreensDidSleepNotification,
            object: NSWorkspace.sharedWorkspace())

        NSDistributedNotificationCenter.defaultCenter().addObserver(self,
            selector: "screenLockHandler:",
            name: "com.apple.screensaver.didstart",
            object: nil)

        NSDistributedNotificationCenter.defaultCenter().addObserver(self,
            selector: "screenLockHandler:",
            name: "com.apple.screensaver.didstop",
            object: nil)

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

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    //
    // SwitchrAPI delegate protocol
    //
    func switchrWillStart() -> Bool {
        if stateToRunning() {
            #if DEBUG
            if DEBUG_SHOW_TIME_ELAPSED {
                timeStart = CFAbsoluteTimeGetCurrent()
            }
            #endif

            switchrAPI = SwitchrAPI(delegate: self)
            switchrAPI!.switchWallpapers()
            return true
        } else {
            NSLog("Another process is running. Please wait.")
            return false
        }
    }

    func switchrDidEnd() {
        switchrAPI = nil
        stateToReady()

        #if DEBUG
        if DEBUG_SHOW_TIME_ELAPSED {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - timeStart!
            NSLog("time used: \(timeElapsed)")
        }
        #endif
    }

    //
    // Timer related
    //

    func timerDidFire() {
        println("\(Preference().switchInterval) minutes passed.")
        switchrWillStart()
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

    //
    // App State Control
    //
    func stateToRunning() -> Bool {
        if state == .Ready {
            state = .Running
            statusMenuController.menuIconActivate()
            statusMenuController.statusBarItemStatusToRunning()
            return true
        }
        return false
    }

    func stateToReady() {
        state = .Ready
        statusMenuController.menuIconDeactivate()
        statusMenuController.statusBarItemStatusToReady()
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
        let appNeedToStopNotifications = [
            NSWorkspaceScreensDidSleepNotification,
            "com.apple.screensaver.didstart",
            "com.apple.screenIsLocked"
        ]

        if contains(appNeedToStopNotifications, aNotification.name) {
            stopSwitchTimer()
        } else {
            updateSwitchTimer()
        }
    }
}