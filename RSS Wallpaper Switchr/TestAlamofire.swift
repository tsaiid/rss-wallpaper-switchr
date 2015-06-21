//
//  TestAlamofire.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/6/21.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa
import Alamofire

protocol TARssParserObserverDelegate {
    func rssDidParse(imgLinks: [String]?)
}

class TestAlamofireOperation : ConcurrentOperation {
    let URLString: String
    var finalPath: NSURL?
    let downloadImageCompletionHandler: (responseObject: AnyObject?, error: NSError?) -> ()
    weak var request: Alamofire.Request?

    init(URLString: String, downloadImageCompletionHandler: (responseObject: AnyObject?, error: NSError?) -> ()) {
        self.URLString = URLString
        self.downloadImageCompletionHandler = downloadImageCompletionHandler
        super.init()
    }

    deinit {
        //println("TestAlamofireOperation deinit")
    }

    override func main() {
        let destination: (NSURL, NSHTTPURLResponse) -> (NSURL) = {
            (temporaryURL, response) in

            let fileName = response.suggestedFilename!
            self.finalPath = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingPathComponent(fileName as String))
            if self.finalPath != nil {
                // check if temp file exists, then remove
                let finalPathStr:String = self.finalPath!.path!.stringByExpandingTildeInPath
                if NSFileManager.defaultManager().fileExistsAtPath(finalPathStr) {
                    var removeFileError: NSError?
                    if NSFileManager.defaultManager().removeItemAtPath(finalPathStr, error: &removeFileError) {
                        println("tmp file: \(finalPathStr) exists and removed.")
                    } else {
                        println("removing tmp file: \(finalPathStr) error: \(removeFileError)")
                    }
                } else {
                    //println("\(finalPathStr) not exists.")
                }
                return self.finalPath!
            }
            return temporaryURL
        }

        request = Alamofire.download(.GET, URLString, destination).response { (request, response, responseObject, error) in
            if self.cancelled {
                println("Alamofire.download cancelled while downlading. Not proceed.")
            } else {
                self.downloadImageCompletionHandler(responseObject: self.finalPath, error: error)
            }
            self.completeOperation()
        }
    }

    override func cancel() {
        request?.cancel()
        super.cancel()
    }
}

private var testAlamofireContext = 0

class TestAlamofireObserver: NSObject {
    var delegate: ImageDownloadDelegate?
    var queue = NSOperationQueue()

    init(delegate: ImageDownloadDelegate) {
        super.init()
        self.delegate = delegate
        queue.addObserver(self, forKeyPath: "operations", options: .New, context: &testAlamofireContext)
    }

    deinit {
        queue.removeObserver(self, forKeyPath: "operations", context: &testAlamofireContext)
        if DEBUG_DEINIT {
            //println("TestAlamofireObserver deinit.")
        }
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &testAlamofireContext {
            if self.queue.operations.count == 0 {
                println("Image Download Complete queue. keyPath: \(keyPath); object: \(object); context: \(context)")
                self.delegate?.imagesDidDownload()
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}

class TestAlamofire: NSObject, ImageDownloadDelegate, TARssParserObserverDelegate {
    var testAlamofireObserver: TestAlamofireObserver?
    var rssParserObserver: TARssParserObserver?
    //var finalPath: NSURL?
    var targetScreens = [TargetScreen]()

    override init() {
        super.init()
        testAlamofireObserver = TestAlamofireObserver(delegate: self)
        rssParserObserver = TARssParserObserver(delegate: self)
    }

    func getTargetScreens() {
        targetScreens = [TargetScreen]()
        if let screenList = NSScreen.screens() as? [NSScreen] {
            for screen in screenList {
                var targetScreen = TargetScreen(screen: screen)
                targetScreens.append(targetScreen)
            }
        }
    }

    func getNoWallpaperScreen() -> TargetScreen? {
        for targetScreen in targetScreens {
            if targetScreen.wallpaperPhoto == nil {
                switch Preference().wallpaperMode {
                case 2: // four-image group
                    if targetScreen.photoPool.count < 4 {
                        return targetScreen
                    }
                default:    // single image
                    return targetScreen
                }
            }
        }
        return nil
    }

    func test() {
        getTargetScreens()

        let imgLinks = [
        "https://farm4.staticflickr.com/3925/18769503068_1fc09427ec_k.jpg",
        "https://farm1.staticflickr.com/338/18933828356_4f57420df7_k.jpg",
        "https://farm4.staticflickr.com/3776/18945113685_ccec89d67a_o.jpg",
        "https://farm1.staticflickr.com/366/18333992053_725f21166e_k.jpg",
        "https://farm4.staticflickr.com/3777/18962702032_086453ee7a_k.jpg",
        "https://farm1.staticflickr.com/373/18930501406_4753ac021a_k.jpg",
        "https://farm1.staticflickr.com/283/18772907409_56ffbe573b_k.jpg",
        "https://farm1.staticflickr.com/314/18940901785_b0564b1c9b_o.jpg",
        "https://farm1.staticflickr.com/502/18949263495_88d75d2d2f_k.jpg",
        "https://farm4.staticflickr.com/3912/18938184302_6e0ca9ad31_k.jpg",
        "https://farm1.staticflickr.com/356/18957923475_3dc9df7634_k.jpg",
        "https://farm1.staticflickr.com/378/18925014986_e87feca9c7_o.jpg",
        "https://farm1.staticflickr.com/461/18949863812_ddf700bd03_o.jpg",
        "https://farm1.staticflickr.com/303/18920711216_4684ff4295_k.jpg",
        "https://farm1.staticflickr.com/558/18935058546_fc10d10855_k.jpg",
        "https://farm1.staticflickr.com/384/18955290345_fb93d17828_o.jpg",
        "https://farm1.staticflickr.com/266/18956724112_6e61a743a5_k.jpg"
        ]

        rssDidParse(imgLinks)
    }

    func cancelTest() {
        testAlamofireObserver!.queue.cancelAllOperations()
    }

    func rssDidParse(imgLinks: [String]?) {
        downloadImages(imgLinks)
    }

    func downloadImages(imgLinks: [String]?) {
        for imgLink in imgLinks! {
            let operation = TestAlamofireOperation(URLString: imgLink) {
                (responseObject, error) in

                if responseObject == nil {
                    // handle error here

                    println("failed: \(error)")
                } else {
                    //println("responseObject=\(responseObject!)")
                    if let targetScreen = self.getNoWallpaperScreen() {
                        let url:NSURL = responseObject as! NSURL
                        targetScreen.wallpaperPhoto = PhotoRecord(name: "", url: url, localPathUrl: url)
                    } else {
                        self.testAlamofireObserver!.queue.cancelAllOperations()
                    }
                }
            }
            testAlamofireObserver!.queue.addOperation(operation)
        }
    }

    func imagesDidDownload() {
        NSLog("imagesDidDownload.")
        // set desktop image options
        let scalingMode = Preference().scalingMode
        //var options = getDesktopImageOptions(scalingMode)
        //println("scaling options: \(options)")
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate

        var workspace = NSWorkspace.sharedWorkspace()
        var error: NSError?
        let myPreference = Preference()

        for targetScreen in targetScreens {
            if let localPathUrl = targetScreen.wallpaperPhoto?.localPathUrl {
                NSWorkspace.sharedWorkspace().setDesktopImageURL(localPathUrl, forScreen: targetScreen.screen!, options: nil, error: &error)

                if error != nil {
                    NSLog("\(error)")
                }
            }
        }
    }
}

class TARssParserObserver: NSObject {
    var delegate: TARssParserObserverDelegate?
    var queue = NSOperationQueue()
    var imgLinks: [String]?

    init(delegate: TARssParserObserverDelegate) {
        super.init()
        self.delegate = delegate
        queue.addObserver(self, forKeyPath: "operations", options: .New, context: &testAlamofireContext)
    }

    deinit {
        queue.removeObserver(self, forKeyPath: "operations", context: &testAlamofireContext)
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &testAlamofireContext {
            if (self.queue.operations.count == 0) {
                println("queue completed.")
                if (self.imgLinks?.count > 0) {
                    self.imgLinks?.shuffle()
                    self.delegate?.rssDidParse(self.imgLinks)
                } else {
                    println("No image link found")
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}