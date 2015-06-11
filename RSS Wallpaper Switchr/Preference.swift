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
    
    init() {
        println("Loading stored preference.")

        load()
    }

    func load() {
        let defaults = NSUserDefaults.standardUserDefaults()

        if let tmpRssUrls: AnyObject = defaults.objectForKey("rssUrls") {
            rssUrls = tmpRssUrls.mutableCopy() as! NSMutableArray
            println("option rssUrl: \(rssUrls)")
        }

        fitScreenOrientation = defaults.boolForKey("fitScreenOrientation")
        println("option fitScreenOrientation: \(fitScreenOrientation)")

        switchInterval = defaults.integerForKey("switchInterval")
        println("option switchInterval: \(switchInterval)")

        filterSmallerImages = defaults.boolForKey("filterSmallerImages")
        imageLowerLimitLength = defaults.integerForKey("imageLowerLimitLength")
        println("option filterSmallerImages: \(filterSmallerImages), imageLowerLimitLength: \(imageLowerLimitLength)")
    }

    func save() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(rssUrls, forKey: "rssUrls")
        defaults.setObject(fitScreenOrientation, forKey: "fitScreenOrientation")
        defaults.setObject(switchInterval, forKey: "switchInterval")
        defaults.setObject(filterSmallerImages, forKey: "filterSmallerImages")
        defaults.setObject(imageLowerLimitLength, forKey: "imageLowerLimitLength")
    }
}