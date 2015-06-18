//
//  SwitchrAPI.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/6/18.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

protocol SwitchrAPIDelegate {
    func wallpaperDidUpdate(targetScreens: [TargetScreen])
}

class SwitchrAPI: NSObject, RssParserObserverDelegate, ImageDownloadDelegate {
    var targetScreens = [TargetScreen]()

    var rssParser: RssParserObserver!
    var imageDownload: ImageDownloadObserver!

    override init() {
        super.init()
        rssParser = RssParserObserver(delegate: self)
        imageDownload = ImageDownloadObserver(delegate: self)
    }

    func rssDidParse() {
        getImageFromUrl()
    }

    func getImageFromUrl() {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate

        imageDownload.queue.maxConcurrentOperationCount = 2

        println("image queue: \(imageDownload.queue.operations.count)")

        for imgLink in appDelegate.imgLinks {
            let urlStr:String = imgLink as String
            let myPreference = Preference()

            let operation = DownloadImageOperation(URLString: urlStr) {
                (responseObject, error) in

                if responseObject == nil {
                    // handle error here

                    println("failed: \(error)")
                } else {
                    println("responseObject=\(responseObject!)")
                    if let targetScreen = self.getNoWallpaperScreen() {
                        var this_photo: PhotoRecord? = responseObject as? PhotoRecord
                        if this_photo!.isSuitable(targetScreen, preference: myPreference) {
                            targetScreen.wallpaperPhoto = this_photo
                        }
                    } else {
                        println("All targetScreens are done.")
                        self.imageDownload.queue.cancelAllOperations()
                    }
                }
            }
            imageDownload.queue.addOperation(operation)
        }
    }

    func imagesDidDownload() {
        setDesktopBackgrounds()
    }

    func getNoWallpaperScreen() -> TargetScreen? {
        for targetScreen in targetScreens {
            if targetScreen.wallpaperPhoto == nil {
                //println("Some targetScreens have no wallpaperPhoto.")
                return targetScreen
            }
        }
        return nil
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

    func switchWallpapers() {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate

        if appDelegate.state != .Ready {
            println("A process is running. Please wait.")
            return
        }

        println("start sequence set backgrounds.")

        #if DEBUG
            appDelegate.timeStart = CFAbsoluteTimeGetCurrent()
        #endif

        appDelegate.stateToRunning()

        // clean all var
        getTargetScreens()
        appDelegate.imgLinks = [String]()

        // load rss url
        let rssUrls = Preference().rssUrls
        if rssUrls.count == 0 {
            notify("No predefined RSS url.")
            appDelegate.stateToReady()
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
                    appDelegate.imgLinks += responseObject as! [String]
                }
            }
            rssParser.queue.addOperation(operation)
        }
    }

    func setDesktopBackgrounds() {
        // set desktop image options
        let scalingMode = Preference().scalingMode
        var options = getDesktopImageOptions(scalingMode)
        //println("scaling options: \(options)")
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate

        var workspace = NSWorkspace.sharedWorkspace()
        var error: NSError?
        let myPreference = Preference()

        if getNoWallpaperScreen() == nil {
            for targetScreen in targetScreens {
                let screenList = NSScreen.screens() as? [NSScreen]
                if (find(screenList!, targetScreen.screen!) != nil) {
                    if let photo = targetScreen.wallpaperPhoto {
                        var result:Bool = workspace.setDesktopImageURL(photo.localPathUrl, forScreen: targetScreen.screen!, options: options, error: &error)
                        if result {
                            println("\(targetScreen.screen!) set to \(photo.localPath) from \(photo.url) fitScreenOrientation: \(myPreference.fitScreenOrientation)")
                        } else {
                            println("error setDesktopImageURL for screen: \(targetScreen.screen!)")
                            return
                        }
                    } else {
                        println("No wallpaper set for \(targetScreen.screen!)")
                    }
                }
            }
            println("Wallpaper changes!", title: "Successful")
        } else {
            println("getNoWallpaperScreen incomplete.")
        }

        #if DEBUG
            let timeElapsed = CFAbsoluteTimeGetCurrent() - appDelegate.timeStart!
            println("time used: \(timeElapsed)")
        #endif

        appDelegate.stateToReady()

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