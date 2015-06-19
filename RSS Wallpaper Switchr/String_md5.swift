//
//  String_md5.swift
//  RSS Wallpaper Switchr
//
//  Created by I-Ta Tsai on 2015/2/2.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//  From: https://gist.github.com/finder39/f6d71f03661f7147547d
//  Author: finder39

import Foundation

extension String {
    func md5() -> String! {
        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CUnsignedInt(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)

        CC_MD5(str!, strLen, result)

        var hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }

        result.destroy()

        return String(format: hash as String)
    }
}