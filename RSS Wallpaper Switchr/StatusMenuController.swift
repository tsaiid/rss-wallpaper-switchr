//
//  StatusMenuController.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/6/18.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject, PreferencesWindowDelegate, AboutWindowDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    var preferencesWindow: PreferencesWindow?
    var aboutWindow: AboutWindow?
    var statusBarStartEndItem: NSMenuItem!

    private let activeIcon: NSImage
    private let deactiveIcon: NSImage

    var appDelegate: AppDelegate!
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1) // NSVariableStatusItemLength

    //var switchrAPI: SwitchrAPI?

    //
    // Init
    //

    override init() {
        // init app icon, can switch between active and deactive icons
        self.activeIcon = NSImage(named: "Menu Icon Active")!
        self.activeIcon.setTemplate(true)
        self.deactiveIcon = NSImage(named: "Menu Icon")!
        self.deactiveIcon.setTemplate(true)

        super.init()
    }

    deinit {
        if DEBUG_DEINIT {
            println("StatusMenuController deinit.")
        }
    }

    override func awakeFromNib() {
        statusItem.image = deactiveIcon
        statusItem.menu = statusMenu
        statusBarStartEndItem = statusItem.menu?.itemWithTag(1)

        appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.statusMenuController = self
    }

    //
    // Menu Item Linked Func
    //

    @IBAction func switchWallpapersClicked(sender: NSMenuItem) {
        if !appDelegate.switchrWillStart() {
            appDelegate.switchrAPI!.cancelOperations()
            NSLog("Force cancel SwitchrAPI operations.")
        }
    }

    @IBAction func preferencesClicked(sender: NSMenuItem) {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindow()
            preferencesWindow!.delegate = self
        }
        preferencesWindow!.showWindow(self)
        NSApp.activateIgnoringOtherApps(true)
        preferencesWindow!.window!.makeKeyAndOrderFront(self)
    }

    @IBAction func aboutClicked(sender: NSMenuItem) {
        if aboutWindow == nil {
            aboutWindow = AboutWindow()
            aboutWindow!.delegate = self
        }
        aboutWindow!.showWindow(self)
        NSApp.activateIgnoringOtherApps(true)
        aboutWindow!.window!.makeKeyAndOrderFront(self)
    }

    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }

    //
    // Control menu item
    //

    func menuIconDeactivate() {
        statusItem.image = deactiveIcon
    }

    func menuIconActivate() {
        statusItem.image = activeIcon
    }

    func statusBarItemStatusToRunning() {
        statusBarStartEndItem!.title = "Cancel Operations?"
    }

    func statusBarItemStatusToReady() {
        statusBarStartEndItem!.title = "Switch Wallpapers"
    }

    //
    // Preserved Delegate Implamentation.
    //

    func preferencesDidUpdate() {
        NSLog("Preferences did update.")
        preferencesWindow = nil
    }

    func aboutDidClose() {
        NSLog("About did close.")
        aboutWindow = nil
    }
}