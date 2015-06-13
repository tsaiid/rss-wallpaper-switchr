# RSS Wallpaper Switchr

![RSS Wallpaper Switchr Logo][logo]

A Mac OS X menubar App to periodically change the desktop wallpaper from RSS feeds.

The project page: [http://tsai.it/project/osx/rss-wallpaper-switchr/]()

[logo]: https://raw.githubusercontent.com/tsaiid/rss-wallpaper-switchr/master/RSS%20Wallpaper%20Switchr/Images.xcassets/AppIcon.appiconset/RWS-icon_128x128.png

### Features

1. Different screen uses different wallpaper. 
2. Can detect screen orientation and try to choose a matched image such as portrait or landscape.
3. Can set a lower limit of image size. 

### RSS Feed Requirement

The current RSS parser only recognize document structure as below:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">

<channel>
  <title>W3Schools Home Page</title>
  <link>http://www.w3schools.com</link>
  <description>Free web building tutorials</description>
  <item>
    <title>RSS Tutorial</title>
    <link>http://www.w3schools.com/webservices</link>
    <description>New RSS tutorial on W3Schools</description>
  </item>
  <item>
    <title>XML Tutorial</title>
    <link>http://www.w3schools.com/xml</link>
    <description>New XML tutorial on W3Schools</description>
  </item>
</channel>

</rss>
```

The link of items will be extracted for fetching images. 

### Build

It uses [CocoaPods][] for managing Cocoa dependency.

Dependent Pods: 

1. [Alamofire][]
2. [SWXMLHash][]

[CocoaPods]:  https://github.com/cocoapods/cocoapods
[Alamofire]:  https://github.com/Alamofire/Alamofire
[SWXMLHash]:  https://github.com/drmohundro/SWXMLHash

### Package

It uses [node-appdmg][] for packaging. Exporting to `AppDmg/` and execute:

```bash
$ appdmg spec.json RssWallpaperSwitchr.dmg
```

[node-appdmg]:  https://github.com/LinusU/node-appdmg
