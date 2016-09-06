//
//  PsiphonData.swift
//  Psiphon-Browser
//
//  Created by Miro Kuratczyk on 2016-08-22.
//  Copyright © 2016 Psiphon. All rights reserved.
//

import Foundation

infix operator >>= { associativity left }


// Retrieve entry and convert to desired type with f
func getWithKey<T,U>(key: String, f: (T) -> (U)) -> (Notification) -> Result<U> {
    func getEntryAndInit(notif: Notification) -> Result<U> {
        if let userInfo = notif.userInfo as? Dictionary<String,T> {
            if let entry = userInfo[key] {
                return Result.Value(f(entry))
            } else {
                return Result.Error("No entry found for key: " + key )
            }
        } else {
            return Result.Error("Malformed or unexpected notification: userInfo absent")
        }
    }
    return getEntryAndInit
}

struct Throwable {
    var message: String // Error.localizedDescription
    var stackTrace: [String] // Thread.callStackSymbols()
}

class StatusEntry {
    private var Timestamp: Date
    private var Id: String
    private var Sensitivity: StatusEntry.SensitivityLevel
    private var FormatArgs: [AnyObject]?
    private var Throwable: Throwable?
    private var Priority: StatusEntry.PriorityLevel
    
    public enum SensitivityLevel {
        /**
         * The log does not contain sensitive information.
         */
        case NOT_SENSITIVE
        /**
         * The log message itself is sensitive information.
         */
        case SENSITIVE_LOG
        /**
         * The format arguments to the log messages are sensitive, but the
         * log message itself is not.
         */
        case SENSITIVE_FORMAT_ARGS
    }
    
    public enum PriorityLevel: Int {
        case VERBOSE = 2
        case DEBUG
        case INFO
        case WARN
        case ERROR
        case ASSERT
    }
    
    private init(id: String, formatArgs: [AnyObject]?, throwable: Throwable?, sensitivity: SensitivityLevel, priority: PriorityLevel) {
        Timestamp = Date()
        Id = id
        Sensitivity = sensitivity
        FormatArgs = formatArgs
        Throwable = throwable
        Priority = priority
    }
    
    public func getTimestamp() -> String {
        return self.Timestamp.iso8601
    }
    
    public func getId() -> String {
        return self.Id
    }
    
    func getSensitivity() -> StatusEntry.SensitivityLevel {
        return self.Sensitivity
    }
    
    public func getPriority() -> Int {
        return self.Priority.rawValue
    }
    
    public func getFormatArgs() -> [AnyObject]? {
        if (self.getSensitivity() == StatusEntry.SensitivityLevel.SENSITIVE_FORMAT_ARGS) {
            return []
        } else {
            return self.FormatArgs
        }
    }
    
    func getThrowable() -> Throwable? {
        return self.Throwable
    }
}

class DiagnosticEntry {
    
    private var Timestamp: Date
    private var Msg: String
    private var Data: [String:AnyObject]
    
    private init(msg: String, nameValuePairs: AnyObject...) {
        assert(nameValuePairs.count % 2 == 0)
        
        Timestamp = Date()
        Msg = msg
        
        var jsonObject: [String:AnyObject] = [:]
        
        for i in 0...nameValuePairs.count/2-1 {
            jsonObject[nameValuePairs[i*2] as! String] = nameValuePairs[i*2+1]
        }
        
        Data = jsonObject
    }
    
    private init(msg: String) {
        let result = DiagnosticEntry.init(msg: msg, nameValuePairs: "msg", msg)
        Timestamp = result.Timestamp
        Msg = result.Msg
        Data = result.Data
    }

    public func getTimestamp() -> String {
        return self.Timestamp.iso8601
    }
    
    public func getTimestampForDisplay() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: self.Timestamp)
    }
    
    public func getMsg() -> String {
        return self.Msg
    }
    
    public func getData() -> [String:AnyObject] {
        return self.Data
    }
}

@objc class PsiphonData: NSObject {
    
    
    
    private var statusHistory: [StatusEntry] = []
    private var diagnosticHistory: [DiagnosticEntry] = []
    static let sharedInstance = PsiphonData()

    override private init() {
        super.init()
        
        // Add observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receivedNewLogEntryNotification(aNotification:)),
            name: Notification.Name.init("NewLogEntryPosted"),
            object: nil)
    }
    
    func receivedNewLogEntryNotification(aNotification: Notification) {
        let result = aNotification.withName(name: Constants.Notifications.NewLogEntry) >>= getWithKey(key: Constants.Keys.LogEntry, f: DiagnosticEntry.init) >>= self.addDiagnosticEntry
        
        switch result {
        case let .Value(diagnosticEntry):
            if (diagnosticEntry.Msg == "Connected") {
                noticeConnectionEstablished()
            }
            noticeLogAdded()
        case let .Error(error):
            print(error)
        }
    }
    
    func noticeLogAdded() {
        let notif = Notification.init(name: Notification.Name.init(rawValue:Constants.Notifications.DisplayLogEntry), object: nil, userInfo: nil)
        NotificationQueue.default.enqueue(notif, postingStyle: NotificationQueue.PostingStyle.now)
    }
    
    func noticeConnectionEstablished() {
        let notif = Notification.init(name: Notification.Name.init(rawValue:Constants.Notifications.ConnectionEstablished), object: nil, userInfo: nil)
        NotificationQueue.default.enqueue(notif, postingStyle: NotificationQueue.PostingStyle.now)
    }
    
    func addDiagnosticEntry(diagnosticEntry: DiagnosticEntry) -> Result<DiagnosticEntry> {
        self.diagnosticHistory.append(diagnosticEntry)
        return Result<DiagnosticEntry>.Value(diagnosticEntry)
    }
    
    func addStatusEntry(id: String, formatArgs: [AnyObject]?, throwable: Throwable?, sensitivity: StatusEntry.SensitivityLevel, priority: StatusEntry.PriorityLevel) {
        let statusEntry = StatusEntry(id: id, formatArgs: formatArgs, throwable: throwable, sensitivity: sensitivity, priority: priority)
        self.statusHistory.append(statusEntry)
    }
    
    func getDiagnosticHistory() -> [DiagnosticEntry] {
        return self.diagnosticHistory
    }
    
    func getDiagnosticLogs(n: Int? = nil) -> [String] {
        var entries: [DiagnosticEntry] = []
        
        if let numEntries = n {
            entries = Array<DiagnosticEntry>(self.diagnosticHistory.suffix(numEntries))
        } else {
            entries = self.diagnosticHistory
        }
        return entries.map { ( $0 ).getTimestampForDisplay() + " " + ( $0 ).getMsg() } // map to string array of formatted entries for display
    }
    
    func getStatusHistory() -> [StatusEntry] {
        return self.statusHistory.filter { ($0).getSensitivity() != StatusEntry.SensitivityLevel.SENSITIVE_LOG }
    }
}
