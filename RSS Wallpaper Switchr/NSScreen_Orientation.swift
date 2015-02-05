//
//  NSScreen_Orientation.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/5.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

extension NSScreen {
    func orientation() -> PhotoRecordOrientation {
        let height = self.frame.height
        let width = self.frame.width
        
        return ( height / width > 1 ? .Portrait : .Landscape )
    }
}