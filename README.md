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
  <title>Flickr Interestingness Wallpaper Feed</title>
  <link>http://feed.tsai.it/flickr/interestingness.rss</link>
  <description>Flickr Interestingness Wallpaper Feed</description>
  <item>
    <title>Hornby Lighthouse</title>
    <link>https://farm1.staticflickr.com/334/18726872639_d551e8ce0e_k.jpg</link>
    <description>Hornby Lighthouse</description>
  </item>
  <item>
    <title>Lady Bird</title>
    <link>https://farm4.staticflickr.com/3809/18921256432_b7ad6ad1c2_k.jpg</link>
    <description>Lady Bird</description>
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
