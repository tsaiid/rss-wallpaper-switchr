//
//  TargetScreens.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/16.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

class TargetScreen {
    var screen:NSScreen? = nil
    var orientation = Orientation.NotApplicable
    var wallpaperPhoto:PhotoRecord? = nil
    var currentTry:Int = 0

    init(screen: NSScreen) {
        self.screen = screen
        calcOrientation()
    }

    func calcOrientation() {
        if screen != nil {
            let width = screen!.frame.width
            let height = screen!.frame.height
            println("TargetScreen.calcOrientation: \(screen) size: \(width) x \(height)")
            if width / height < 1 {
                orientation = .Portrait
            } else {
                orientation = .Landscape
            }
        } else {
            self.orientation = .NotApplicable
        }
    }
}