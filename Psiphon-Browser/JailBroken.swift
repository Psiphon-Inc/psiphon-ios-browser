//
//  JailBroken.swift
//  Psiphon-Browser
//
//  Created by Miro Kuratczyk on 2016-08-31.
//  Copyright © 2016 Psiphon. All rights reserved.
//

import Foundation
import MobileCoreServices

func isJailBroken() -> Bool {
    // TODO
    return false
}

// https://github.com/sat2eesh/ios-jailBroken/blob/master/JBroken.m
// http://thwart-ipa-cracks.blogspot.ca/2008/11/detection.html
func isAppStoreBuild() -> Bool {
    var isAppStoreBuild: Bool = false
    
    // Check for provisioning profile
    if let provisionPath: String = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") {
        if (provisionPath.characters.count == 0) {
            isAppStoreBuild = true
        }
    }
    
    // verify Info.plist integrity
    // App store build should be binary
    // Others should be XML w/ ascii
    do {
        let plistPath = Bundle.main.bundlePath + "/Info.plist"
        if (!FileManager.default.fileExists(atPath: plistPath)) {
            return false
        }
        
        _ = try NSString(contentsOf: URL.init(fileURLWithPath: plistPath), encoding: String.Encoding.ascii.rawValue)
        //(text as String).characters.count // hardcode this character count
        
        isAppStoreBuild = false
    } catch {
        // Need a better way of checking if Info.plist is in XML format
        PsiphonData.sharedInstance.addStatusEntry(id: error.localizedDescription, formatArgs: nil, throwable: nil)
        isAppStoreBuild = true
    }
    
    return isAppStoreBuild
}
