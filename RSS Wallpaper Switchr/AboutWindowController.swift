//
//  AboutWindowController.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/6/12.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

class AboutWindowController: NSWindowController {
    var mainW: NSWindow = NSWindow()

    @IBOutlet weak var labelVersion: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Update version info
        let dictionary = NSBundle.mainBundle().infoDictionary!
        let verText = dictionary["CFBundleShortVersionString"] as! String
        let buildText = dictionary["CFBundleVersion"] as! String
        labelVersion.stringValue += " \(verText) (build \(buildText))"
    }
}