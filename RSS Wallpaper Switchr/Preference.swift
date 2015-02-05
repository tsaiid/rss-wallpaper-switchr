//
//  Preference.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/5.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Foundation

class Preference {
    var rssUrl:String = ""
    var switchInterval:Int = 0
    var fitScreenOrientation:Bool = true
    
    init() {
        println("Loading stored preference.")

        load()
    }

    func load() {
        let defaults = NSUserDefaults.standardUserDefaults()

        rssUrl = defaults.stringForKey("rssUrl")!
        println("option rssUrl: \(rssUrl)")

        fitScreenOrientation = defaults.boolForKey("fitScreenOrientation")
        println("option fitScreenOrientation: \(fitScreenOrientation)")
    }

    func save() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(rssUrl, forKey: "rssUrl")
        defaults.setObject(fitScreenOrientation, forKey: "fitScreenOrientation")
    }
}