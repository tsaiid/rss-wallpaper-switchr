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
    func switchrDidEnd()
}

class SwitchrAPI: NSObject, RssParserObserverDelegate, ImageDownloadDelegate {
    var delegate: SwitchrAPIDelegate?
    var rssParser: RssParserObserver?
    var imageDownload: ImageDownloadObserver?

    var targetScreens = [TargetScreen]()
    var imgLinks = [String]()

    init(delegate: SwitchrAPIDelegate) {
        super.init()
        self.delegate = delegate
        rssParser = RssParserObserver(delegate: self)
        imageDownload = ImageDownloadObserver(delegate: self)
    }

    deinit {
        if DEBUG_DEINIT {
            //println("SwitchrAPI deinit.")
        }
    }

    func downloadImages(imgLinks: [String]?) {
        for imgLink in imgLinks! {
            let operation = DownloadImageOperation(URLString: imgLink) {
                (responseObject, error) in

                if responseObject == nil {
                    // handle error here

                    println("failed: \(error)")
                } else {
                    if let targetScreen = self.getNoWallpaperScreen() {
                        let url:NSURL = responseObject as! NSURL
                        let downloadedPhoto = PhotoRecord(name: "", url: url, localPathUrl: url)
                        /*
                        if this_photo!.isSuitable(targetScreen, preference: Preference()) {
                        */
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
                        /*
                        }
                        */
                    } else {
                        self.imageDownload!.queue.cancelAllOperations()
                    }
                }
            }
            imageDownload!.queue.addOperation(operation)
        }
    }

    func imagesDidDownload() {
        NSLog("imagesDidDownload.")
        // set desktop image options
        var options = getDesktopImageOptions(Preference().scalingMode)
        //let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate

        var workspace = NSWorkspace.sharedWorkspace()
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

        delegate?.switchrDidEnd()
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

    func switchWallpapers() {
        getTargetScreens()
        imgLinks = [String]()

        parseRss()
    }

    func cancelOperations() {
        rssParser!.queue.cancelAllOperations()
        imageDownload!.queue.cancelAllOperations()
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
            rssParser!.queue.addOperation(operation)
        }
    }

    func rssDidParse() {
        NSLog("rssDidParse.")
        imgLinks.shuffle()
        downloadImages(imgLinks)
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