//
//  debug.swift
//  RSS Wallpaper Switchr
//
//  Created by I-Ta Tsai on 2015/2/6.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//  For debug mode use: http://stackoverflow.com/a/28157546/1576281

import Cocoa

// some debug flags
let DEBUG_DEINIT:Bool = true
let DEBUG_SHOW_TIME_ELAPSED:Bool = true

func println(object: Any) {
    #if DEBUG
        /*
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        let timestamp = formatter.stringFromDate(date)
        //Swift.println("\(timestamp): \(object)")
*/
        NSLog("\(object)")
    #endif
}

func notify(msg: NSString!, title: NSString = "Error"){
    var userNotify = NSUserNotification()
    userNotify.title = title as String
    userNotify.informativeText = msg as String

    #if DEBUG
        NSLog("\(msg)")
    #endif

    NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(userNotify)
}