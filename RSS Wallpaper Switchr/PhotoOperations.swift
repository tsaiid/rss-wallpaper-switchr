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
}

func ==(lhs: PhotoRecord, rhs: PhotoRecord) -> Bool {
    return (lhs.name == rhs.name && lhs.url == rhs.url)
}

class PendingOperations {
    lazy var downloadsInProgress = [String:NSOperation]()
    lazy var downloadQueue:NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
        }()
}

class ImageDownloader: NSOperation {
    //1
    let photoRecord: PhotoRecord
    
    //2
    init(photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    //3
    override func main() {
        //4
        if self.cancelled {
            return
        }
        //5
        let imageData = NSData(contentsOfURL:self.photoRecord.url)
        
        //6
        if self.cancelled {
            return
        }
        
        //7
        if imageData?.length > 0 {
            self.photoRecord.image = NSImage(data:imageData!)
            self.photoRecord.state = .Downloaded
        }
        else
        {
            self.photoRecord.state = .Failed
            self.photoRecord.image = NSImage(named: "Failed")
        }
    }
}