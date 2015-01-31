//
//  AppDelegate.swift
//  Background Changer
//
//  Created by I-Ta Tsai on 2015/1/31.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func setDesktopBackgrounds() {
        var imgurl = NSURL(fileURLWithPath: "/Users/tsaiid/Pictures/Wallpapers/15307243809_b971f2d920_k.jpg")
        var workspace = NSWorkspace.sharedWorkspace()
        var error: NSError?
        
        if let screenList = NSScreen.screens() as? [NSScreen] {
            println(screenList.count)
            for screen in screenList {
//                var result : Bool = workspace.setDesktopImageURL(imgurl!, forScreen: screen, options: nil, error: &error)
                
//                if !result {
                    //testLabel.stringValue = "error"
//                    println("error")
//                    break
//                }
                //let screenOptions:NSDictionary! = workspace.desktopImageOptionsForScreen(screen)
                //let a  = screenOptions.NSWorkspaceDesktopImageScalingKey
                //println(screenOptions[NSWorkspaceDesktopImageScalingKey])
                //println(screenOptions[NSWorkspaceDesktopImageFillColorKey])
            }
            
            //            testLabel.stringValue = "Changed"
        }

        
    }

    func activeSpaceDidChange(aNotification: NSNotification) {
        println("space changed")
        setDesktopBackgrounds()
    }


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self,
            selector: "activeSpaceDidChange:",
            name: NSWorkspaceActiveSpaceDidChangeNotification,
            object: NSWorkspace.sharedWorkspace())
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

