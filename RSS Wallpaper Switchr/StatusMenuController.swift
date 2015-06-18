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

    private let activeIcon: NSImage
    private let deactiveIcon: NSImage

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1) // NSVariableStatusItemLength
    var switchrAPI = SwitchrAPI()

    override init() {
        // init app icon, can switch between active and deactive icons
        self.activeIcon = NSImage(named: "Menu Icon Active")!
        self.activeIcon.setTemplate(true)
        self.deactiveIcon = NSImage(named: "Menu Icon")!
        self.deactiveIcon.setTemplate(true)

        super.init()
    }

    override func awakeFromNib() {
        statusItem.image = deactiveIcon
        statusItem.menu = statusMenu

        preferencesWindow = PreferencesWindow()
        preferencesWindow.delegate = self

        aboutWindow = AboutWindow()
        aboutWindow.delegate = self
    }

    func updateWallpapers() {
        switchrAPI.switchWallpapers()
    }

    @IBAction func switchWallpapersClicked(sender: NSMenuItem) {
        NSLog("Force set wallpapers.")
        updateWallpapers()
    }

    func cancellingClicked(sender: NSMenuItem) {
        println("Force cancelling operation.")
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate

        switchrAPI.rssParser.queue.cancelAllOperations()
        switchrAPI.imageDownload.queue.cancelAllOperations()
        appDelegate.stateToReady()
        println("queue: \(switchrAPI.imageDownload.queue.operations.count)")
    }

    @IBAction func preferencesClicked(sender: NSMenuItem) {
        preferencesWindow.showWindow(self)
    }

    func preferencesDidUpdate() {
        NSLog("Preferences did update.")
    }

    func aboutDidClose() {
        NSLog("About did close.")
    }

    @IBAction func aboutClicked(sender: NSMenuItem) {
        aboutWindow.showWindow(self)
    }

    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }

    private func menuIconDeactivate() {
        statusItem.image = deactiveIcon
    }

    private func menuIconActivate() {
        statusItem.image = activeIcon
    }

}