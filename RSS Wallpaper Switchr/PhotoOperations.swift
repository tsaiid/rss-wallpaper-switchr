//
//  PhotoOperations.swift
//  RSS Wallpaper Switchr
//
//  Created by I-Ta Tsai on 2015/2/3.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

// This enum contains all the possible states a photo record can be in
enum PhotoRecordState {
    case New, Downloaded, Filtered, Failed
}

enum PhotoRecordOrientation: Int {
    case Portrait = 0
    case Landscape = 1
    case Square = 2
    case NA = 3
}

class PhotoRecord: Equatable {
    let name:String
    let url:NSURL
    var state = PhotoRecordState.New
    var image = NSImage(named: "Placeholder")
    var orientation = PhotoRecordOrientation.NA
    var localPath:String = ""
    var localPathUrl = NSURL()
    var forScreen:NSScreen? = nil
    
    init(name:String, url:NSURL) {
        self.name = name
        self.url = url
    }
    
    func saveToLocalPath() {
        // set temp files
        let fileManager = NSFileManager.defaultManager()
        let tempDirectoryTemplate = NSTemporaryDirectory().stringByAppendingPathComponent("rws")
        if fileManager.createDirectoryAtPath(tempDirectoryTemplate, withIntermediateDirectories: true, attributes: nil, error: nil) {
            println("tempDir: \(tempDirectoryTemplate)")
            if let imgUrl:String = self.url.absoluteString {
                var imgPath = "\(tempDirectoryTemplate)/\(imgUrl.md5()).jpg"
                self.image!.saveAsJpegWithName(imgPath)
                self.localPath = imgPath
                self.localPathUrl = NSURL(fileURLWithPath: imgPath)!
                println("localPath set to \(imgPath) from \(imgUrl)")
            }
        } else {
            println("createDirectoryAtPath NSTemporaryDirectory error.")
        }

    }
    
    func calcOrientation() {
        if let nsImg = self.image {
            let ratio = nsImg.size.width / nsImg.size.height
            if ratio > 1 {
                self.orientation = .Landscape
            } else if ratio < 1 {
                self.orientation = .Portrait
            } else {
                self.orientation = .Square
            }
        } else {
            println("calcOrientation: no image ?!")
        }
    }

    func fitSizeLimitation(limit: Float) -> Bool {
        let height = Float(self.image!.size.height)
        let width = Float(self.image!.size.width)

        return height > limit && width > limit ? true : false
    }
}

func ==(lhs: PhotoRecord, rhs: PhotoRecord) -> Bool {
    return (lhs.name == rhs.name && lhs.url == rhs.url)
}

class PendingOperations:NSObject {
    lazy var downloadsInProgress = [String:NSOperation]()
    dynamic var downloadQueue:NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Download queue"
        queue.maxConcurrentOperationCount = 1

        return queue
        }()
}

private var myContext = 0

class PendingOperationsObserver: NSObject {
    var pendingOperations = PendingOperations()
    override init() {
        super.init()
        pendingOperations.addObserver(self, forKeyPath: "downloadQueue.operationCount", options: .New, context: &myContext)
    }
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            if pendingOperations.downloadQueue.operationCount == 0 {
                println("Complete queue.")

                let appDelegate = NSApplication.sharedApplication().delegate as AppDelegate

                // set backgrounds.
                appDelegate.setDesktopBackgrounds()
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    deinit {
        pendingOperations.removeObserver(self, forKeyPath: "downloadQueue.operationCount", context: &myContext)
    }
}

class ImageDownloader: NSOperation {
    let photoRecord: PhotoRecord
    
    init(photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        if self.cancelled {
            return
        }

        let imageData = NSData(contentsOfURL:self.photoRecord.url)
        
        if self.cancelled {
            return
        }
        
        if imageData?.length > 0 {
            self.photoRecord.image = NSImage(data:imageData!)
            self.photoRecord.state = .Downloaded
            self.photoRecord.calcOrientation()
        }
        else
        {
            self.photoRecord.state = .Failed
            self.photoRecord.image = NSImage(named: "Failed")
        }
    }
}