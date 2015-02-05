//
//  OptionsWindowController.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/1.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

class OptionsWindowController: NSWindowController {

    var mainW: NSWindow = NSWindow()

    @IBOutlet weak var rssUrlText: NSTextField!
    @IBOutlet weak var chkboxFitScreenOrientation: NSButton!

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        // Load stored options
        println("Loading options in Option Window")

        // use Preference class to load Preference
        let appDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        let myPref = appDelegate.myPreference
        rssUrlText.stringValue = myPref.rssUrl
        if myPref.fitScreenOrientation {
            chkboxFitScreenOrientation.state = NSOnState
        }
    }
    
    //method called, when "Close" - Button clicked
    @IBAction func closeOptionWindow(sender: AnyObject) {
        // saving options
        println("Try saving options.")

        let appDelegate = NSApplication.sharedApplication().delegate as AppDelegate
        let myPref = appDelegate.myPreference
        myPref.rssUrl = rssUrlText.stringValue
        myPref.fitScreenOrientation = (chkboxFitScreenOrientation.state == NSOnState ? true : false)

        myPref.save()
        
        self.close()
    }
   
}

