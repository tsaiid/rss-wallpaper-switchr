//
//  Array_shuffle.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/6/10.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Foundation

extension Array {
    mutating func shuffle() {
        if count > 0 {
            for i in 0..<(count - 1) {
                let j = Int(arc4random_uniform(UInt32(count - i))) + i
                swap(&self[i], &self[j])
            }
        }
    }
}