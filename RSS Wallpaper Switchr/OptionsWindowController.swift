//
//  OptionsWindowController.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/1.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa
import Alamofire
import SWXMLHash

class OptionsWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {

    var mainW: NSWindow = NSWindow()

    @IBOutlet weak var rssUrlText: NSTextField!
    @IBOutlet weak var chkboxFitScreenOrientation: NSButton!
    @IBOutlet weak var popupUpdateInterval: NSPopUpButtonCell!

    @IBOutlet weak var chkboxFilterSmallerImages: NSButton!
    @IBOutlet weak var txtImageLowerLimitLength: NSTextField!

    @IBOutlet weak var rssListTable: NSTableView!
    
    @IBOutlet var sheetAddRss: NSPanel!
    
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
        
        // in order to moniter NSTextField change
        textNewRssUrl.delegate = self
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

        // update UI will be done in the observer
        Alamofire.request(.GET, rssUrl)
            .responseString { (request, response, data, error) in
                //println(request)
                //println(response)
                if error != nil {
                    println("Error: \(error)")
                    if let localizedDescription = error!.localizedDescription as String? {
                        self.validateAlert(localizedDescription)
                    }
                    return
                }

                if let httpResponse = response as NSHTTPURLResponse? {
                    let statusCode = httpResponse.statusCode
                    if statusCode != 200 {
                        println("NSHTTPURLResponse.statusCode = \(statusCode)")
                        //println("Text of response = \(data)")
                        if let localizedResponse = NSHTTPURLResponse.localizedStringForStatusCode(statusCode) as String? {
                            self.validateAlert(localizedResponse)
                        }
                        return
                    }
                }

                //println(data)
                let xml = SWXMLHash.lazy(data!)
                var imgCount = 0
                for item in xml["rss"]["channel"]["item"] {
                    if let imgUrl = item["link"].element?.text {
                        imgCount++
                    }
                }
                self.validateAlert("Valid feed. \(imgCount) image(s) found.")
        }
    }
    
    func validateAlert(msg: String!){
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = "RSS Validation";
        myPopup.informativeText = msg
        myPopup.beginSheetModalForWindow(self.window!, completionHandler: nil)
    }
    
    func validateAlertPopup(msg: String!){
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = "RSS Validation";
        myPopup.informativeText = msg
        myPopup.runModal()
    }

    func windowWillClose(notification: NSNotification) {
        // update timer.
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        println("Updating timer while closing option window.")
        appDelegate.updateSwitchTimer()
    }

    // for RSS URL List Data Source
    func tableView(tableView: NSTableView, viewForTableColumn: NSTableColumn?, row: Int) -> NSView? {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let myPref = appDelegate.myPreference
        
        var list = myPref.newRssUrls as AnyObject as! [String]
        var cell = tableView.makeViewWithIdentifier("rssList", owner: self) as! NSTableCellView
        cell.textField!.stringValue = list[row]
//        cell.textField!.stringValue = "test"
        return cell;
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let myPref = appDelegate.myPreference

        return myPref.newRssUrls.count
    }

    // Add Rss Feed Window Panel
    @IBAction func btnShowAddRssSheet(sender: AnyObject) {
        self.window!.beginSheet(sheetAddRss, completionHandler: nil)
    }
    
    // Panel window
    @IBOutlet weak var textNewRssUrl: NSTextField!
    @IBOutlet weak var btnValidateRss: NSButton!
    @IBOutlet weak var btnAddNewRssCancel: NSButton!
    @IBOutlet weak var btnAddNewRssAdd: NSButton!
    
    @IBAction func btnEndAddingRssWindow(sender: AnyObject) {
        self.window!.endSheet(sheetAddRss)
        sheetAddRss.orderOut(sender)
    }
    
    @IBAction func btnValidateNewRss(sender: NSButton) {
        // have to trim string to prevent Alamofire crash
        let rssUrl:String = textNewRssUrl.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        textNewRssUrl.stringValue = rssUrl
        
        btnValidateRss.enabled = false
        btnValidateRss.title = "Validating"
        Alamofire.request(.GET, rssUrl)
            .responseString { (request, response, data, error) in
                //println(request)
                //println(response)
                if error != nil {
                    println("Error: \(error)")
                    if let localizedDescription = error!.localizedDescription as String? {
                        self.validateAlertPopup(localizedDescription)
                    }
                    self.btnValidateRss.enabled = true
                    self.btnValidateRss.title = "Validate"
                    return
                }
                
                if let httpResponse = response as NSHTTPURLResponse? {
                    let statusCode = httpResponse.statusCode
                    if statusCode != 200 {
                        println("NSHTTPURLResponse.statusCode = \(statusCode)")
                        //println("Text of response = \(data)")
                        if let localizedResponse = NSHTTPURLResponse.localizedStringForStatusCode(statusCode) as String? {
                            self.validateAlertPopup(localizedResponse)
                        }
                        self.btnValidateRss.enabled = true
                        self.btnValidateRss.title = "Validate"
                        return
                    }
                }
                
                //println(data)
                let xml = SWXMLHash.lazy(data!)
                var imgCount = 0
                for item in xml["rss"]["channel"]["item"] {
                    if let imgUrl = item["link"].element?.text {
                        imgCount++
                    }
                }
                self.validateAlertPopup("Valid feed. \(imgCount) image(s) found.")
                self.btnValidateRss.enabled = true
                self.btnAddNewRssAdd.enabled = true
                self.btnValidateRss.title = "Validate"
        }
    }
    
    // detect
    override func controlTextDidChange(obj: NSNotification) {
        if btnAddNewRssAdd.enabled {
            btnAddNewRssAdd.enabled = false
        }
    }
    
    @IBAction func btnAddNewRssUrl(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let myPref = appDelegate.myPreference

        let rssUrl:String = textNewRssUrl.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        if myPref.newRssUrls.containsObject(rssUrl) {
            println("\(rssUrl) exists.")
        } else {
            myPref.newRssUrls.addObject(rssUrl)
            println("\(rssUrl) added.")
            println("current rss urls: \(myPref.newRssUrls).")
            rssListTable.reloadData()
            self.window!.endSheet(sheetAddRss)
            sheetAddRss.orderOut(sender)
        }
    }
}

