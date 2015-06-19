//
//  NSImage_saveAsJpegWithName.swift
//  RSS Wallpaper Switchr
//
//  Created by I-Ta Tsai on 2015/2/3.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//  Modified from: http://stackoverflow.com/a/3213017/1576281

import Cocoa

extension NSImage {
    func saveAsJpegWithName(filePath: NSString) {
        var imageData:NSData = self.TIFFRepresentation!
        let imageRep = NSBitmapImageRep(data: imageData)!
        let imageProps = NSDictionary(object: NSNumber(float: 1.0), forKey: NSImageCompressionFactor)
        imageData = imageRep.representationUsingType(NSBitmapImageFileType.NSJPEGFileType, properties: imageProps as [NSObject : AnyObject])!
        imageData.writeToFile(filePath as String, atomically: false)
    }
}