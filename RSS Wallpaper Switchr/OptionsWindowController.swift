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

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        // Load stored options
        println("Loading options")

        // use NSUserDefaults to load Preference
        let defaults = NSUserDefaults.standardUserDefaults()
        if let rssUrl = defaults.stringForKey("rssUrl") {
            rssUrlText.stringValue = rssUrl
            println(rssUrl)
        }

    }
    
    //method called, when "Close" - Button clicked
    @IBAction func closeOptionWindow(sender: AnyObject) {
        // saving options
        println("Try saving options.")
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(rssUrlText.stringValue as String, forKey: "rssUrl")
        
        self.close()
    }
   
}

