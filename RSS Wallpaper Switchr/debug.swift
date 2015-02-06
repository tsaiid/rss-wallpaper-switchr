//
//  debug.swift
//  RSS Wallpaper Switchr
//
//  Created by I-Ta Tsai on 2015/2/6.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//  For debug mode use: http://stackoverflow.com/a/28157546/1576281

func println(object: Any) {
    #if DEBUG
        Swift.println(object)
    #endif
}
