//
//  Common.swift
//  Psiphon-Browser
//
//  Created by Miro Kuratczyk on 2016-08-30.
//  Copyright © 2016 Psiphon. All rights reserved.
//

import Foundation

extension Array {
    func takeLastN<T>(n: Int) -> [T] {
        // TODO: handle as! errors?
        if (self.count < n) {
            return self.map { $0 as! T }
        } else {
            return self[self.count-n..<self.count].map { $0 as! T }
        }
    }
}

class PsiphonCommon {
    static func getRandomBytes(numBytes: Int) -> [UInt8] {
        let bytesCount = numBytes
        var randomBytes = [UInt8](repeating: 0, count: bytesCount)
        
        // Generate random bytes
        let result = SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
        if (result != 0) {
            // TODO: pretty fatal error
        }
        
        return randomBytes
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
