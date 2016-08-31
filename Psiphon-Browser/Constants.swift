//
//  Constants.swift
//  Psiphon-Browser
//
//  Created by Miro Kuratczyk on 2016-08-26.
//  Copyright © 2016 Psiphon. All rights reserved.
//

import Foundation

struct Constants {
    struct Notifications {
        static let ConnectionEstablished = "ConnectionEstablished"
        static let DisplayLogEntry = "DisplayLogEntry"
        static let NewLogEntry = "NewLogEntryPosted"
    }
    
    struct Keys {
        static let LastId = "LastId"
        static let LogEntry = "LogEntryKey"
    }
}

enum PsiphonError : Error {
    case Runtime(String)
}
