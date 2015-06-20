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
    var photoPool = [PhotoRecord]()
    var currentTry:Int = 0

    init(screen: NSScreen) {
        self.screen = screen
        calcOrientation()
    }

    func calcOrientation() {
        if screen != nil {
            let width = screen!.frame.width
            let height = screen!.frame.height
            // println("TargetScreen.calcOrientation: \(screen) size: \(width) x \(height)")
            if width / height < 1 {
                orientation = .Portrait
            } else {
                orientation = .Landscape
            }
        } else {
            self.orientation = .NotApplicable
        }
    }

    func size() -> NSSize? {
        if screen != nil {
            return NSSize(width: screen!.frame.width, height: screen!.frame.height)
        }
        return nil
    }

    private func getCenterRect(targetSize: NSSize, sourceSize: NSSize) -> NSRect {
        var width, height, xPos, yPos: CGFloat

        let targetRatio = targetSize.width / targetSize.height
        let sourceRatio = sourceSize.width / sourceSize.height

        if targetRatio >= sourceRatio {
            width = sourceSize.width
            height = targetSize.height * sourceSize.width / targetSize.width
            xPos = 0
            yPos = abs(sourceSize.height - height) / 2
        } else {
            height = sourceSize.height
            width = targetSize.width * sourceSize.height / targetSize.height
            yPos = 0
            xPos = abs(sourceSize.width - width) / 2
        }

        return NSMakeRect(xPos, yPos, width, height)
    }

    private func getTmpFilePath(photoPool: [PhotoRecord]) -> String {
        // join all url for tmp file name
        var allUrlsStr:String = ""
        for photoRecord in photoPool {
            allUrlsStr += photoRecord.url!.absoluteString!
        }

        // set temp files
        var tmpPathStr:String = ""
        let fileManager = NSFileManager.defaultManager()
        let tempDirectoryTemplate = NSTemporaryDirectory().stringByAppendingPathComponent("rws")
        if fileManager.createDirectoryAtPath(tempDirectoryTemplate, withIntermediateDirectories: true, attributes: nil, error: nil) {
            println("tempDir: \(tempDirectoryTemplate)")
            tmpPathStr = "\(tempDirectoryTemplate)/\(allUrlsStr.md5()).jpg"
            println("getTmpFilePath set to \(tmpPathStr)")
        } else {
            println("createDirectoryAtPath NSTemporaryDirectory error.")
        }

        return tmpPathStr
    }

    func mergeFourPhotos() {
        if photoPool.count == 4 {
            var tmpPathStr:String = getTmpFilePath(photoPool)
            let screenSize = size()
            let quarSize = NSSize(width: screenSize!.width / 2, height: screenSize!.height / 2)
            var newImage = NSImage(size: screenSize!)
            let targetFrames = [
                NSMakeRect(0, 0, quarSize.width, quarSize.height),
                NSMakeRect(quarSize.width, 0, quarSize.width, quarSize.height),
                NSMakeRect(0, quarSize.height, quarSize.width, quarSize.height),
                NSMakeRect(quarSize.width, quarSize.height, quarSize.width, quarSize.height),
            ]

            newImage.lockFocus()

            for (index, targetFrame) in enumerate(targetFrames) {
                var fromRect:NSRect = getCenterRect(screenSize!, sourceSize: photoPool[index].size())
                println("targetFrame: \(targetFrame); fromRect: \(fromRect)")
                photoPool[index].image!.drawInRect(targetFrame, fromRect: fromRect, operation: .CompositeCopy, fraction: 1.0)
            }

            newImage.unlockFocus()
            newImage.saveAsJpegWithName(tmpPathStr)
            let tmpPath = NSURL(fileURLWithPath: tmpPathStr)
            println("tmpPath: \(tmpPath)")
            wallpaperPhoto = PhotoRecord(name: "four-image-group", url: tmpPath!, localPathUrl: tmpPath!)
            println("wallpaperPhoto: \(wallpaperPhoto)")
        } else {
            println("No enough photos to merge in the pool. targetScreen: \(self as TargetScreen)")
        }
    }
}