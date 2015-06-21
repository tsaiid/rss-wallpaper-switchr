//
//  TestAlamofire.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/6/21.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa
import Alamofire
import SWXMLHash

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
    var imgLinks = [String]()

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

        imgLinks = [String]()
        parseRss()
    }

    func cancelTest() {
        testAlamofireObserver!.queue.cancelAllOperations()
    }

    func parseRss() {
        // load rss url
        let rssUrls = Preference().rssUrls
        if rssUrls.count == 0 {
            notify("No predefined RSS url.")
            return
        }

        for url in rssUrls {
            println(url)
            let operation = TAParseRssOperation(URLString: url as! String) {
                (responseObject, error) in

                if responseObject == nil {
                    // handle error here

                    println("failed: \(error)")
                } else {
                    //println("responseObject=\(responseObject!)")
                    self.imgLinks += responseObject as! [String]
                }
            }
            rssParserObserver!.queue.addOperation(operation)
        }
    }

    func rssDidParse() {
        NSLog("rssDidParse.")
        imgLinks.shuffle()
        //NSLog("\(imgLinks)")
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

class TAParseRssOperation : ConcurrentOperation {
    let URLString: String
    let parseRssCompletionHandler: (responseObject: AnyObject?, error: NSError?) -> ()

    weak var request: Alamofire.Request?

    init(URLString: String, parseRssCompletionHandler: (responseObject: AnyObject?, error: NSError?) -> ()) {
        self.URLString = URLString
        self.parseRssCompletionHandler = parseRssCompletionHandler
        super.init()
    }

    deinit {
    }

    override func main() {
        request = Alamofire.request(.GET, URLString)
            .responseString { (request, response, data, error) in
                if error != nil {
                    println("ParseRss error: \(error)")
                }

                if self.cancelled {
                    println("ParseRssOperation.main() Alamofire.download cancelled while downlading. Not proceed into PhotoRecord.")
                } else {
                    if data != nil {
                        var xml = SWXMLHash.parse(data!)
                        let title = xml["rss"]["channel"]["title"].element?.text
                        println("Feed: \(title) was parsed.")

                        // return a list of image links.
                        var imgLinks = [String]()
                        for item in xml["rss"]["channel"]["item"] {
                            if let link = item["link"].element?.text {
                                if !contains(imgLinks, link) {
                                    imgLinks += [link]
                                }
                            }
                        }

                        self.parseRssCompletionHandler(responseObject: imgLinks, error: error)
                    }
                }

                // however error or succeeded, it should complete.
                self.completeOperation()
        }
    }

    override func cancel() {
        // should also cancel Alamofire request, but it results in strange memory problem!
        request?.cancel()
        super.cancel()
    }
}

protocol TARssParserObserverDelegate {
    func rssDidParse()
}

class TARssParserObserver: NSObject {
    var delegate: TARssParserObserverDelegate?
    var queue = NSOperationQueue()

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
                self.delegate?.rssDidParse()
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}