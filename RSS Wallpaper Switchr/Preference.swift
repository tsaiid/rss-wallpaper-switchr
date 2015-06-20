//
//  Preference.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/5.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Foundation

class Preference {
    var rssUrls = NSMutableArray()
    var switchInterval:Int = 0
    var fitScreenOrientation:Bool = true
    var filterSmallerImages:Bool = false
    var imageLowerLimitLength:Int = 1024
    var scalingMode:Int = 1
    var wallpaperMode:Int = 1
    
    init() {
        //println("Loading stored preference.")
        load()
    }

    func load() {
        let defaults = NSUserDefaults.standardUserDefaults()

        if let tmpRssUrls: AnyObject = defaults.objectForKey("rssUrls") {
            rssUrls = tmpRssUrls.mutableCopy() as! NSMutableArray
        }

        fitScreenOrientation = defaults.boolForKey("fitScreenOrientation")
        switchInterval = defaults.integerForKey("switchInterval")
        filterSmallerImages = defaults.boolForKey("filterSmallerImages")
        imageLowerLimitLength = defaults.integerForKey("imageLowerLimitLength")
        scalingMode = defaults.integerForKey("scalingMode")
        wallpaperMode = defaults.integerForKey("wallpaperMode")
    }

    func save() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(rssUrls, forKey: "rssUrls")
        defaults.setObject(fitScreenOrientation, forKey: "fitScreenOrientation")
        defaults.setObject(switchInterval, forKey: "switchInterval")
        defaults.setObject(filterSmallerImages, forKey: "filterSmallerImages")
        defaults.setObject(imageLowerLimitLength, forKey: "imageLowerLimitLength")
        defaults.setObject(scalingMode, forKey: "scalingMode")
        defaults.setObject(wallpaperMode, forKey: "wallpaperMode")
    }
}