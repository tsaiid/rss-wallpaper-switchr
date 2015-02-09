//
//  debug.swift
//  RSS Wallpaper Switchr
//
//  Created by I-Ta Tsai on 2015/2/6.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//  For debug mode use: http://stackoverflow.com/a/28157546/1576281

import Cocoa

func println(object: Any) {
    #if DEBUG
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        let timestamp = formatter.stringFromDate(date)
        Swift.println("\(timestamp): \(object)")
    #endif
}
