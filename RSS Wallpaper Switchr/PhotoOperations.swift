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

enum Orientation: Int {
    case Portrait = 0
    case Landscape = 1
    case Square = 2
    case NotApplicable = 3
}

class PhotoRecord: Equatable {
    let name:String
    var url:NSURL?
    var state = PhotoRecordState.New
    var image = NSImage(named: "Placeholder")
    var imgRep = NSImageRep()
    var orientation = Orientation.NotApplicable
    var localPath:String = ""
    var localPathUrl = NSURL()

    init(name:String, url:NSURL) {
        self.name = name
        self.url = url
    }

    init(name:String, url:NSURL, localPathUrl:NSURL) {
        self.name = name
        self.url = url
        self.localPathUrl = localPathUrl
        self.localPath = localPathUrl.absoluteString!
        if let image = NSImage(contentsOfURL: localPathUrl) {
            self.image = image
            calcOrientation()
            self.imgRep = image.representations.first as! NSImageRep
        }
    }
    
    func saveToLocalPath() {
        // set temp files
        if localPath == "" {
            let fileManager = NSFileManager.defaultManager()
            let tempDirectoryTemplate = NSTemporaryDirectory().stringByAppendingPathComponent("rws")
            if fileManager.createDirectoryAtPath(tempDirectoryTemplate, withIntermediateDirectories: true, attributes: nil, error: nil) {
                println("tempDir: \(tempDirectoryTemplate)")
                if let imgUrl:String = self.url!.absoluteString {
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

    func fitSizeLimitation(limit: Int) -> Bool {
        let height = self.imgRep.pixelsHigh
        let width = self.imgRep.pixelsWide

        return height > limit && width > limit ? true : false
    }
    
    func isSuitable(targetScreen: TargetScreen, preference: Preference) -> Bool {
        let lowerLimit = preference.imageLowerLimitLength

        if preference.fitScreenOrientation {
            // if no fit, maximal try: 3 downloads.
            targetScreen.currentTry++
            if ((targetScreen.orientation == orientation) || targetScreen.currentTry > 2)  {
                if !preference.filterSmallerImages || lowerLimit <= 0 {
                    println("No image size lower limit set. Too much try: \(targetScreen.currentTry). Selected \(url)")
                    return true
                } else {
                    if fitSizeLimitation(lowerLimit) {
                        println("imageLowerLimitLength is on. Size (\(imgRep.pixelsWide) x \(imgRep.pixelsHigh)) is more than limitation: \(lowerLimit). Selected \(url)")
                        return true
                    } else {
                        println("imageLowerLimitLength is on. Size (\(imgRep.pixelsWide) x \(imgRep.pixelsHigh)) not fit limitation: \(lowerLimit). Not selected.")
                        return false
                    }
                }
            } else {
                println("Orientation not fit: screen: \(targetScreen.orientation.rawValue), photo: \(orientation.rawValue). Not selected. currentTry: \(targetScreen.currentTry)")
            }
        } else {
            if !preference.filterSmallerImages || lowerLimit <= 0 {
                println("No image size lower limit set. Selected \(url)")
                return true
            } else {
                if fitSizeLimitation(lowerLimit) {
                    println("imageLowerLimitLength is on. Size is more than limitation: \(lowerLimit). Selected \(url)")
                    return true
                } else {
                    println("imageLowerLimitLength is on. Size \(image!.size.width) x \(image!.size.height) not fit limitation: \(lowerLimit). Not selected.")
                    return false
                }
            }
        }

        return false
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
        queue.maxConcurrentOperationCount = 4

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

                let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate

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

        var error:NSError?
        let imageData = NSData(contentsOfURL:self.photoRecord.url!, options: nil, error: &error)
        if (error != nil) {
            self.photoRecord.state = .Failed
            self.photoRecord.image = NSImage(named: "Failed")
            println("NSData contentsOfURL error: \(error)")
            return
        }

        if self.cancelled {
            return
        }
        
        if imageData?.length > 0 {
            self.photoRecord.image = NSImage(data:imageData!)
            self.photoRecord.state = .Downloaded
            self.photoRecord.calcOrientation()
            self.photoRecord.imgRep = self.photoRecord.image!.representations.first as! NSImageRep
        }
        else
        {
            self.photoRecord.state = .Failed
            self.photoRecord.image = NSImage(named: "Failed")
        }
    }
}