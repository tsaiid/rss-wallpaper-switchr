//
//  NSMutableArray_Shiffle.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/2.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//  Modified From: http://qiita.com/kiiita/items/65630e8c06eea4811122

import Foundation

extension NSMutableArray {
    func shuffle() {
        for i in 0..<self.count {
            var nElements: Int = self.count - i
            var n: Int = Int(arc4random_uniform(UInt32(nElements))) + i
            self.exchangeObjectAtIndex(i, withObjectAtIndex: n)
        }
    }
}