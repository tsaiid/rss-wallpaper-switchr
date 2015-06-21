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
    var preferencesWindow: PreferencesWindow!
    var aboutWindow: AboutWindow!
    var statusBarStartEndItem: NSMenuItem!

    private let activeIcon: NSImage
    private let deactiveIcon: NSImage

    var appDelegate: AppDelegate!
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1) // NSVariableStatusItemLength

    var testAlamofire: TestAlamofire?
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

        preferencesWindow = PreferencesWindow()
        preferencesWindow.delegate = self

        aboutWindow = AboutWindow()
        aboutWindow.delegate = self

        appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.statusMenuController = self
    }

    //
    // Menu Item Linked Func
    //

    @IBAction func switchWallpapersClicked(sender: NSMenuItem) {
        switch appDelegate.state {
        case .Ready:
            println("Force set wallpapers.")
            updateWallpapers()
        case .Running:
            println("Force cancelling operation.")
            cancelUpdate()
        default:
            println("Strange AppState: \(appDelegate.state)")
        }
    }

    @IBAction func preferencesClicked(sender: NSMenuItem) {
        preferencesWindow.showWindow(self)
        NSApp.activateIgnoringOtherApps(true)
    }

    @IBAction func aboutClicked(sender: NSMenuItem) {
        aboutWindow.showWindow(self)
    }

    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }

    private func updateWallpapers() {
        /*
        if appDelegate.switchrAPI == nil {
            appDelegate.switchrAPI = SwitchrAPI()
        }
*/
        appDelegate.switchrAPI.switchWallpapers()
    }

    private func cancelUpdate() {
//        if let switchrAPI = appDelegate.switchrAPI {
            appDelegate.switchrAPI.rssParser?.queue.cancelAllOperations()
            appDelegate.switchrAPI.imageDownload?.queue.cancelAllOperations()
//        }
//        appDelegate.switchrAPI = nil
        appDelegate.stateToReady()
    }

    @IBAction func testAlamofire(sender: AnyObject) {
        testAlamofire = TestAlamofire()
        testAlamofire!.test()
    }

    @IBAction func cancelAlamofire(sender: AnyObject) {
        testAlamofire!.cancelTest()
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
    }

    func aboutDidClose() {
        NSLog("About did close.")
    }
}