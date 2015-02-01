//
//  AppDelegate.swift
//  RSS Wallpaper Switchr
//
//  Created by 蔡依達 on 2015/2/1.
//  Copyright (c) 2015年 I-Ta Tsai. All rights reserved.
//

import Cocoa
//import CoreData

@objc(Option)
class Option: NSManagedObject {
    @NSManaged var name:String
    @NSManaged var value:String
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var optionName: NSTextField!
    @IBOutlet weak var optionValue: NSTextField!

    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItem : NSMenuItem = NSMenuItem()
    
    var optWin = OptionsWindowController(windowNibName: "OptionsWindowController")


    @IBAction func btnLoad(sender: AnyObject) {
        println("Load")
        var context:NSManagedObjectContext = self.managedObjectContext!
        
        var request = NSFetchRequest(entityName: "Options")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "optionName = %@", "RssUrl")
        
        var results:[NSManagedObject]? = context.executeFetchRequest(request, error: nil) as? [NSManagedObject]
        if (results!.count > 0) {
            println("Loaded")
            var res = results![0] as NSManagedObject
            println(res.valueForKey("optionValue") as String)
            optionName.stringValue = res.valueForKey("optionValue") as String
        } else {
            println("No record.")
        }
    }
    @IBAction func btnSave(sender: AnyObject) {
        println("Save")
        var context:NSManagedObjectContext = self.managedObjectContext!
//        var en = NSEntityDescription.entityForName( "Options", inManagedObjectContext: context )
        var newOption = NSEntityDescription.insertNewObjectForEntityForName("Options", inManagedObjectContext: context) as NSManagedObject
        newOption.setValue("RssUrl", forKey: "optionName")
        newOption.setValue("http://", forKey: "optionValue")
        context.save(nil)
        println(newOption)
        println("Saved")
    }
    
    override func awakeFromNib() {
        //theLabel.stringValue = "You've pressed the button \n \(buttonPresses) times!"

        println(statusBar)

        //Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        statusBarItem.title = "Presses"
        
        //Add menuItem to menu
        menuItem.title = "Options"
        menuItem.action = Selector("showOptionsWindow:")
        menuItem.keyEquivalent = ""
        menu.addItem(menuItem)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application

        // by notification, trigger switcher when space changes
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self,
            selector: "changeDesktopAfterSpaceDidChange:",
            name: NSWorkspaceActiveSpaceDidChangeNotification,
            object: NSWorkspace.sharedWorkspace())

        //self.window!.orderOut(self)

    }

    func showOptionsWindow(sender: AnyObject){
        //self.window!.orderFront(self)
        optWin.beginSheet(self.window)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func setDesktopBackgrounds() {
        var imgurl = NSURL(fileURLWithPath: "/Users/tsaiid/git/rss-wallpaper-switchr/15526028562_197501ee89_o.jpg")
        var workspace = NSWorkspace.sharedWorkspace()
        var error: NSError?
        
        if let screenList = NSScreen.screens() as? [NSScreen] {
            println(screenList.count)
            for screen in screenList {
                //                var result : Bool = workspace.setDesktopImageURL(imgurl!, forScreen: screen, options: nil, error: &error)
                
                //                if !result {
                //testLabel.stringValue = "error"
                //                    println("error")
                //                    break
                //                }
                //let screenOptions:NSDictionary! = workspace.desktopImageOptionsForScreen(screen)
                //let a  = screenOptions.NSWorkspaceDesktopImageScalingKey
                //println(screenOptions[NSWorkspaceDesktopImageScalingKey])
                //println(screenOptions[NSWorkspaceDesktopImageFillColorKey])
            }
            
            //            testLabel.stringValue = "Changed"
        }
        
        
    }

    func changeDesktopAfterSpaceDidChange(aNotification: NSNotification) {
        println("space changed")
        //setDesktopBackgrounds()
    }

    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.tsaiid.RSS-Wallpaper-Switchr" in the user's Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let appSupportURL = urls[urls.count - 1] as NSURL
        return appSupportURL.URLByAppendingPathComponent("com.tsaiid.RSS-Wallpaper-Switchr")
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("OptionsData", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = NSFileManager.defaultManager()
        var shouldFail = false
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        // Make sure the application files directory is there
        let propertiesOpt = self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey], error: &error)
        if let properties = propertiesOpt {
            if !properties[NSURLIsDirectoryKey]!.boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } else if error!.code == NSFileReadNoSuchFileError {
            error = nil
            fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil, error: &error)
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator?
        if !shouldFail && (error == nil) {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("options.storedata")
            if coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
                coordinator = nil
            }
        }
        
        if shouldFail || (error != nil) {
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            if error != nil {
                dict[NSUnderlyingErrorKey] = error
            }
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSApplication.sharedApplication().presentError(error!)
            return nil
        } else {
            return coordinator
        }
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving and Undo support
    
    @IBAction func saveAction(sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if let moc = self.managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing before saving")
            }
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSApplication.sharedApplication().presentError(error!)
            }
        }
    }
    
    func windowWillReturnUndoManager(window: NSWindow) -> NSUndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        if let moc = self.managedObjectContext {
            return moc.undoManager
        } else {
            return nil
        }
    }
    
    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if let moc = managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing to terminate")
                return .TerminateCancel
            }
            
            if !moc.hasChanges {
                return .TerminateNow
            }
            
            var error: NSError? = nil
            if !moc.save(&error) {
                // Customize this code block to include application-specific recovery steps.
                let result = sender.presentError(error!)
                if (result) {
                    return .TerminateCancel
                }
                
                let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
                let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
                let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
                let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
                let alert = NSAlert()
                alert.messageText = question
                alert.informativeText = info
                alert.addButtonWithTitle(quitButton)
                alert.addButtonWithTitle(cancelButton)
                
                let answer = alert.runModal()
                if answer == NSAlertFirstButtonReturn {
                    return .TerminateCancel
                }
            }
        }
        // If we got here, it is time to quit.
        return .TerminateNow
    }
}

class RssParser: NSObject, NSXMLParserDelegate {
    var strXMLData:String = ""
    var currentElement:String = ""
    var passData:Bool=false
    var passName:Bool=false

    func parseRssFromUrl(){
        var rss_url = NSURL(string: "http://feeds.feedburner.com/500pxPopularWallpapers")
        let p : NSXMLParser! = NSXMLParser(contentsOfURL: rss_url)
        p.delegate = self
        var success:Bool = p.parse()
    }

    func parser(parser: NSXMLParser!,didStartElement elementName: String!, namespaceURI: String!, qualifiedName : String!, attributes attributeDict: NSDictionary!) {
        currentElement=elementName
        if(elementName=="id" || elementName=="name" || elementName=="cost" || elementName=="description")
        {
            if(elementName=="name"){
                passName=true;
            }
            passData=true;
        }
    }
    
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        currentElement="";
        if(elementName=="id" || elementName=="name" || elementName=="cost" || elementName=="description")
        {
            if(elementName=="name"){
                passName=false;
            }
            passData=false;
        }
    }
    
    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        if(passName){
            strXMLData=strXMLData+"\n\n"+string
        }
        
        if(passData)
        {
            println(string)
        }
    }
    
    func parser(parser: NSXMLParser!, parseErrorOccurred parseError: NSError!) {
        NSLog("failure error: %@", parseError)
    }

}

