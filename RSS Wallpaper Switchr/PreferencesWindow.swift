//
//  PreferencesWindowController.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/1.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa
import Alamofire
import SWXMLHash

protocol PreferencesWindowDelegate {
    func preferencesDidUpdate()
}

class PreferencesWindow: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {

    var delegate: PreferencesWindowDelegate?

    @IBOutlet weak var chkboxFitScreenOrientation: NSButton!
    @IBOutlet weak var popupUpdateInterval: NSPopUpButtonCell!

    @IBOutlet weak var chkboxFilterSmallerImages: NSButton!
    @IBOutlet weak var txtImageLowerLimitLength: NSTextField!

    @IBOutlet weak var rssListTable: NSTableView!
    var rssUrls = NSMutableArray()
    
    @IBOutlet var sheetAddRss: NSPanel!
    @IBOutlet weak var popupWallpaperMode: NSPopUpButton!
    @IBOutlet weak var popupScalingMode: NSPopUpButton!

    override var windowNibName : String! {
        return "PreferencesWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        // Load stored options
        println("Loading options in Option Window")

        // use Preference class to load Preference
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let myPref = Preference()
        rssUrls = myPref.rssUrls
        popupUpdateInterval.selectItemWithTag(myPref.switchInterval)
        if myPref.fitScreenOrientation {
            chkboxFitScreenOrientation.state = NSOnState
        }
        if myPref.filterSmallerImages {
            chkboxFilterSmallerImages.state = NSOnState
        }
        txtImageLowerLimitLength.stringValue = String(myPref.imageLowerLimitLength)
        popupWallpaperMode.selectItemWithTag(myPref.wallpaperMode)
        popupScalingMode.selectItemWithTag(myPref.scalingMode)

        // stop timer after showing option window
        appDelegate.stopSwitchTimer()
        
        // in order to moniter NSTextField change
        textNewRssUrl.delegate = self

        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)
    }

    //method called, when "Close" - Button clicked
    @IBAction func closeOptionWindow(sender: AnyObject) {
        // saving options
        println("Try saving options.")

        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let myPref = Preference()
        myPref.rssUrls = rssUrls
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
        myPref.wallpaperMode = popupWallpaperMode.selectedItem!.tag
        myPref.scalingMode = popupScalingMode.selectedItem!.tag

        myPref.save()
        delegate?.preferencesDidUpdate()
        
        self.close()
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
        var list = rssUrls as AnyObject as! [String]
        var cell = tableView.makeViewWithIdentifier("rssList", owner: self) as! NSTableCellView
        cell.textField!.stringValue = list[row]
        return cell;
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return rssUrls.count
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

        // check if feed exists
        if rssUrls.containsObject(rssUrl) {
            validateAlertPopup("The feed already exists.")
            return
        }

        validateBtnStateToRunning()
        Alamofire.request(.GET, rssUrl)
            .responseString { (request, response, data, error) in
                //println(request)
                //println(response)
                if error != nil {
                    println("Error: \(error)")
                    if let localizedDescription = error!.localizedDescription as String? {
                        self.validateAlertPopup(localizedDescription)
                    }
                    self.validateBtnStateToReady()
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
                        self.validateBtnStateToReady()
                        return
                    }
                }

                // parse xml and get image count
                var imgCount = 0
                let xml = SWXMLHash.parse(data!)
                switch xml["rss"] {
                case .Element:
                    var imgCountMsg:String
                    for item in xml["rss"]["channel"]["item"] {
                        if let imgUrl = item["link"].element?.text {
                            imgCount++
                        }
                    }
                    imgCountMsg = imgCount > 0 ? "\(imgCount) image(s) found." : "However, no image found."
                    self.validateAlertPopup("Valid feed. \(imgCountMsg)")
                    self.btnAddNewRssAdd.enabled = true
                case .Error(let error):
                    println(error)
                    self.validateAlertPopup("Not a valid feed.")
                default:
                    println("nothing")  // switch must have a default !?!
                }

                self.validateBtnStateToReady()
        }
    }
    
    // control validate button state
    private func validateBtnStateToRunning() {
        btnValidateRss.enabled = false
        btnValidateRss.title = "Validating"
    }
    private func validateBtnStateToReady() {
        btnValidateRss.enabled = true
        btnValidateRss.title = "Validate"
    }

    // detect
    override func controlTextDidChange(obj: NSNotification) {
        if btnAddNewRssAdd.enabled {
            btnAddNewRssAdd.enabled = false
        }
    }
    
    @IBAction func btnAddNewRssUrl(sender: AnyObject) {
        let rssUrl:String = textNewRssUrl.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        if rssUrls.containsObject(rssUrl) {
            println("\(rssUrl) exists.")
        } else {
            rssUrls.addObject(rssUrl)
            println("\(rssUrl) added.")
            println("current rss urls: \(rssUrls).")
            rssListTable.reloadData()
            self.window!.endSheet(sheetAddRss)
            sheetAddRss.orderOut(sender)
        }
    }
    
    @IBAction func btnDeleteSeletedRow(sender: NSButton) {
        let selectedRow = rssListTable.selectedRow
        println("selected row: \(selectedRow)")
        if selectedRow > -1 {
            rssUrls.removeObjectAtIndex(selectedRow)
            rssListTable.reloadData()
        }
    }
    
}

