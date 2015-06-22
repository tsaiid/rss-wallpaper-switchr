//
//  AboutWindowController.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/6/12.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

protocol AboutWindowDelegate {
    func aboutDidClose()
}

class AboutWindow: NSWindowController, NSWindowDelegate {
    var delegate: AboutWindowDelegate?

    @IBOutlet weak var labelVersion: NSTextField!

    deinit {
        if DEBUG_DEINIT {
            println("AboutWindow deinit.")
        }
    }

    override var windowNibName : String! {
        return "AboutWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Update version info
        let dictionary = NSBundle.mainBundle().infoDictionary!
        let verText = dictionary["CFBundleShortVersionString"] as! String
        let buildText = dictionary["CFBundleVersion"] as! String
        labelVersion.stringValue += " \(verText) (build \(buildText))"
    }

    func windowWillClose(notification: NSNotification) {
        delegate?.aboutDidClose()
    }
}