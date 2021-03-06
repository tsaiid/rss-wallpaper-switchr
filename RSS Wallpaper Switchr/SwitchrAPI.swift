//
//  SwitchrAPI.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/6/18.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

protocol SwitchrAPIDelegate {
    func switchrWillStart() -> Bool
    func switchrDidEnd(apiState: ApiState)
}

enum ApiState:String {
    case Ready = "Ready"
    case Successful = "Successful"
    case Cancelled = "Cancelled"
    case Error = "Error"
}

class SwitchrAPI: NSObject {
    var delegate: SwitchrAPIDelegate?
    var rssParser: RssParser?
    var imageDownloader: ImageDownloader?

    var targetScreens = [TargetScreen]()
    var imgLinks = [String]()

    //
    // Init
    //

    init(delegate: SwitchrAPIDelegate) {
        super.init()
        self.delegate = delegate
    }

    deinit {
        if DEBUG_DEINIT {
            println("SwitchrAPI deinit.")
        }
    }

    //
    // API entry points
    //

    func switchWallpapers() {
        getTargetScreens()
        imgLinks = [String]()

        rssParser = RssParser()
        parseRss()
    }

    func cancelOperations() {
        rssParser?.cancel()
        imageDownloader?.cancel()
    }

    //
    // 1. parse rss
    //

    func parseRss() {
        if rssParser!.state == .Cancelled {
            NSLog("rssParser cancelled early.")
            return rssDidParse()
        }

        let parseRssCompletionOperation = NSBlockOperation() {
            NSLog("parseRssCompletionOperation.")
            self.rssParser!.state = .Successful
            self.rssDidParse()
        }


        // load rss url
        let rssUrls = Preference().rssUrls
        if rssUrls.count == 0 {
            notify("No predefined RSS url.")
            return
        }

        for url in rssUrls {
            println(url)
            let operation = ParseRssOperation(URLString: url as! String) {
                (responseObject, error) in

                if responseObject == nil {
                    // handle error here

                    println("failed: \(error)")
                } else {
                    //println("responseObject=\(responseObject!)")
                    self.imgLinks += responseObject as! [String]
                }
            }
            parseRssCompletionOperation.addDependency(operation)
            rssParser!.queue.addOperation(operation)
        }

        NSOperationQueue.mainQueue().addOperation(parseRssCompletionOperation)
    }

    func rssDidParse() {
        NSLog("rssDidParse.")

        if rssParser?.state == .Successful {
            imgLinks.shuffle()

            imageDownloader = ImageDownloader()
            downloadImages(imgLinks)
        } else {
            NSLog("rssParser not successful. \(rssParser?.state.rawValue)")
            delegate?.switchrDidEnd(rssParser!.state)
        }

        rssParser = nil
    }

    //
    // 2. download images
    //

    func downloadImages(imgLinks: [String]?) {
        if imageDownloader!.state == .Cancelled {
            NSLog("imageDownloader cancelled early.")
            return imagesDidDownload()
        }

        let downloadImagesCompletionOperation = NSBlockOperation() {
            NSLog("downloadImagesCompletionOperation.")
            self.imagesDidDownload()
        }

        switch Preference().wallpaperMode {
        case 2:     // four-image group
            imageDownloader!.queue.maxConcurrentOperationCount = 6
        default:    // single image
            imageDownloader!.queue.maxConcurrentOperationCount = 2
        }

        for imgLink in imgLinks! {
            let operation = DownloadImageOperation(URLString: imgLink) {
                (responseObject, error) in

                if error != nil {
                    if error!.code == NSURLErrorCancelled && error!.domain == NSURLErrorDomain {
                        println("everything OK, just canceled.")
                    } else {
                        println("error=\(error)")
                    }
                }

                if responseObject == nil {
                    // handle error here

                    println("failed: \(error)")
                } else {
                    if let targetScreen = self.getNoWallpaperScreen() {
                        let url:NSURL = responseObject as! NSURL
                        let downloadedPhoto = PhotoRecord(name: "", url: url, localPathUrl: url)
                        if downloadedPhoto.isSuitable(targetScreen, preference: Preference()) {
                            switch Preference().wallpaperMode {
                            case 2: // four-image group
                                if targetScreen.photoPool.count < 4 {
                                    targetScreen.photoPool.append(downloadedPhoto)
                                    targetScreen.currentTry = 0 // every grid can have tries.

                                    if targetScreen.photoPool.count == 4 {    // photo count is 4
                                        targetScreen.mergeFourPhotos()
                                    }
                                }
                            default:    // single image
                                targetScreen.wallpaperPhoto = downloadedPhoto
                            }
                        }
                    } else {
                        self.imageDownloader!.state = .Successful
                        self.imageDownloader!.queue.cancelAllOperations()
                    }
                }
            }
            downloadImagesCompletionOperation.addDependency(operation)
            imageDownloader!.queue.addOperation(operation)
        }

        NSOperationQueue.mainQueue().addOperation(downloadImagesCompletionOperation)
    }

    func imagesDidDownload() {
        NSLog("imagesDidDownload.")

        if imageDownloader?.state == .Successful {
            // set desktop image options
            var options = getDesktopImageOptions(Preference().scalingMode)
            var error: NSError?

            if getNoWallpaperScreen() == nil {
                for targetScreen in targetScreens {
                    if let localPathUrl = targetScreen.wallpaperPhoto?.localPathUrl {
                        NSWorkspace.sharedWorkspace().setDesktopImageURL(localPathUrl, forScreen: targetScreen.screen!, options: options, error: &error)
                        if error != nil {
                            NSLog("\(error)")
                        }
                    }
                }
            } else {
                println("getNoWallpaperScreen incomplete.")
            }
        } else {
            NSLog("imageDownloader not successful. \(imageDownloader?.state.rawValue)")
        }

        delegate?.switchrDidEnd(imageDownloader!.state)
        imageDownloader = nil
    }

    //
    // Private func
    //

    private func getTargetScreens() {
        targetScreens = [TargetScreen]()
        if let screenList = NSScreen.screens() as? [NSScreen] {
            for screen in screenList {
                var targetScreen = TargetScreen(screen: screen)
                targetScreens.append(targetScreen)
            }
        }
    }

    private func getNoWallpaperScreen() -> TargetScreen? {
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

    private func getDesktopImageOptions(scalingMode: Int) -> [NSObject : AnyObject]? {
        var options: [NSObject : AnyObject]?
        var scaling: NSImageScaling

        switch scalingMode {
        case 1: // fill the screen
            scaling = .ImageScaleProportionallyUpOrDown
            options = [
                "NSWorkspaceDesktopImageScalingKey": NSImageScaling.ImageScaleProportionallyUpOrDown.rawValue,
                "NSWorkspaceDesktopImageAllowClippingKey": true
            ]
        case 2: // fit screen size
            options = [
                "NSWorkspaceDesktopImageScalingKey": NSImageScaling.ImageScaleProportionallyUpOrDown.rawValue,
                "NSWorkspaceDesktopImageAllowClippingKey": false
            ]
        case 3: // centering
            options = [
                "NSWorkspaceDesktopImageScalingKey": NSImageScaling.ImageScaleNone.rawValue,
                "NSWorkspaceDesktopImageAllowClippingKey": false
            ]
        default:
            return nil
        }

        return options
    }
}