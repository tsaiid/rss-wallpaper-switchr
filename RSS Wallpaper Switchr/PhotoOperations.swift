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

class PhotoRecord: Equatable {
    let name:String
    let url:NSURL
    var state = PhotoRecordState.New
    var image = NSImage(named: "Placeholder")
    
    init(name:String, url:NSURL) {
        self.name = name
        self.url = url
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