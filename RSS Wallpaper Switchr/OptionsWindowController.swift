//
//  OptionsWindowController.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/1.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa

class OptionsWindowController: NSWindowController {

    var mainW: NSWindow = NSWindow()

    @IBOutlet weak var rssUrlText: NSTextField!
    @IBOutlet weak var chkboxFitScreenOrientation: NSButton!
    @IBOutlet weak var popupUpdateInterval: NSPopUpButtonCell!

    @IBOutlet weak var chkboxFilterSmallerImages: NSButton!
    @IBOutlet weak var txtImageLowerLimitLength: NSTextField!

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        // Load stored options
        println("Loading options in Option Window")

        // use Preference class to load Preference
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let myPref = appDelegate.myPreference
        if (myPref.rssUrl != nil) {
            rssUrlText.stringValue = myPref.rssUrl!
        }
        popupUpdateInterval.selectItemWithTag(myPref.switchInterval)
        if myPref.fitScreenOrientation {
            chkboxFitScreenOrientation.state = NSOnState
        }
        if myPref.filterSmallerImages {
            chkboxFilterSmallerImages.state = NSOnState
        }
        txtImageLowerLimitLength.stringValue = String(myPref.imageLowerLimitLength)

        // stop timer after showing option window
        appDelegate.stopSwitchTimer()
    }
    
    @IBAction func popupSetUpdateInterval(sender: AnyObject) {
        /*
        if let item = sender.selectedItem as NSMenuItem! {
            println("\(item.tag)")
        }
        */
    }

    //method called, when "Close" - Button clicked
    @IBAction func closeOptionWindow(sender: AnyObject) {
        // saving options
        println("Try saving options.")

        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let myPref = appDelegate.myPreference
        myPref.rssUrl = rssUrlText.stringValue
        myPref.fitScreenOrientation = (chkboxFitScreenOrientation.state == NSOnState ? true : false)
        myPref.switchInterval = popupUpdateInterval.selectedItem!.tag
        myPref.filterSmallerImages = (chkboxFilterSmallerImages.state == NSOnState ? true : false)
        if txtImageLowerLimitLength.stringValue.toInt() == nil {
            let myAlert = NSAlert()
            myAlert.addButtonWithTitle("OK")
            myAlert.messageText = "Please enter an integer for image size limit!"
            if myAlert.runModal() == NSAlertFirstButtonReturn {
                return
            }
        }
        myPref.imageLowerLimitLength = txtImageLowerLimitLength.stringValue.toInt()!

        myPref.save()
        
        self.close()
    }

    @IBAction func btnValidateRSS(sender: AnyObject) {
        let rssUrl:String = rssUrlText.stringValue
        var rssParser = RssParser()
        // update UI will be done in the observer
    }
    
    func validateAlert(msg: String!){
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = "RSS Validation";
        myPopup.informativeText = msg
        myPopup.beginSheetModalForWindow(self.window!, completionHandler: nil)
    }

    func windowWillClose(notification: NSNotification) {
        // update timer.
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        println("Updating timer while closing option window.")
        appDelegate.updateSwitchTimer()
    }
}

