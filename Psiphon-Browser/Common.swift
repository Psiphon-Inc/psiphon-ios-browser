//
//  Common.swift
//  Psiphon-Browser
//
//  Created by Miro Kuratczyk on 2016-08-30.
//  Copyright © 2016 Psiphon. All rights reserved.
//

import Foundation
import SystemConfiguration

struct ConnectionStatus {
    var isConnected: Bool
    var onWifi: Bool
}

class PsiphonCommon {
    static func getRandomBytes(numBytes: Int) -> [UInt8]? {
        let bytesCount = numBytes
        var randomBytes = [UInt8](repeating: 0, count: bytesCount)
        
        // Generate random bytes
        let result = SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
        if (result != 0) {
            return nil
        }
        
        return randomBytes
    }
    static func getNetworkType() -> String {
        let connectionStatus = self.getConnectionStatus()
        
        switch (connectionStatus.isConnected, connectionStatus.onWifi) {
        case (false, _):
            return ""
        case (true, false):
            return "MOBILE"
        case (true, true):
            return "WIFI"
        }
    }
    
    // http://stackoverflow.com/questions/25623272/how-to-use-scnetworkreachability-in-swift
    static func getConnectionStatus() -> ConnectionStatus {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else {
            return ConnectionStatus(isConnected: false, onWifi: false)
        }
        
        var flags : SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return ConnectionStatus(isConnected: false, onWifi: false)
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let onWifi = !flags.contains(.isWWAN)
        
        return ConnectionStatus(isConnected: isReachable && !needsConnection, onWifi: onWifi)
    }
}

class PsiphonConfig {
    static let sharedInstance = PsiphonConfig()
    private var config: [String:AnyObject]
    
    private init () {
        config = [:]
        if let path = Bundle.main.path(forResource: "psiphon_config", ofType: "json")
        {
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSData.ReadingOptions.mappedIfSafe)
                if let jsonResult: [String:AnyObject] = try JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:AnyObject]
                {
                    config = jsonResult
                }
            } catch {
                print("Failed to parse config JSON. Aborting now.")
                abort()
            }
        }
    }
    
    public func getField(field: String) -> AnyObject {
        return config[field]! // TODO: should check exists / handle exception
    }
}

extension Notification {
    init() {
        self.init()
    }
    func withName(name: String) -> Result<Notification> {
        if (name == self.name.rawValue) {
            return Result<Notification>.Value(self)
        } else {
            return Result.Error("Got wrong notification type. Expected: " + name + ". Got: " + self.name.rawValue)
        }
    }
}

// http://stackoverflow.com/questions/28016578/swift-how-to-create-a-date-time-stamp-and-format-as-iso-8601-rfc-3339-utc-tim
// ISO8601DateFormatter only available in iOS 10.0+

// Follow format specified in `getISO8601String` https://bitbucket.org/psiphon/psiphon-circumvention-system/src/default/Android/app/src/main/java/com/psiphon3/psiphonlibrary/Utils.java?fileviewer=file-view-default
extension Date {
    struct Formatter {
        static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX") // https://developer.apple.com/library/mac/qa/qa1480/_index.html
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
            return formatter
        }()
    }
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}

extension String {
    var dateFromISO8601: Date? {
        return Date.Formatter.iso8601.date(from: self)
    }
}
