//
//  FeedbackViewController.swift
//  Psiphon-Browser
//
//  Created by Miro Kuratczyk on 2016-08-09.
//  Copyright © 2016 Psiphon. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import Security

func valOrNull(opt: AnyObject?) -> AnyObject {
    if let val = opt {
        return val
    } else {
        return NSNull()
    }
}

class FeedbackFormViewController: UIViewController, WKScriptMessageHandler {
    @IBOutlet var containerView : UIWebView? = nil
    var webView: WKWebView?
    
    override func loadView() {
        super.loadView()
        self.webView = WKWebView()
        self.view = self.webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let wkConfig = WKWebViewConfiguration()
        
        wkConfig.userContentController.add(self, name: "native")
        
        let indexHTMLPath = Bundle.main.path(forResource: "feedback", ofType: "html")
        let url = URL(fileURLWithPath: indexHTMLPath!)
        let request = URLRequest(url: url)
        
        self.webView = WKWebView(frame: self.view.frame, configuration: wkConfig)
        
        self.webView!.load(request)

        self.view = self.webView!
    }

    // Received javascript callback with feedback form info
    // TODO: add comment referencing android code
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        do {
            let dataString: String = message.body as! String
            let data: Data = dataString.data(using: String.Encoding.utf8) as Data!
            var decodedJson = try JSONSerialization.jsonObject(with: data) as! Dictionary<String, AnyObject>
            
            let sendDiagnosticInfo = decodedJson["sendDiagnosticInfo"] as! Bool
            
            var feedbackBlob: [String:AnyObject] = [:]
            
            feedbackBlob["Feedback"] = [
                "email": decodedJson["email"] as! String,
                "Message": [
                    "text": decodedJson["feedback"] as! String
                ],
                "Survey": [
                    "json": (decodedJson["responses"] as! [[String:AnyObject]])[0].description
                ]
            ]
            
            PsiphonData.sharedInstance.addStatusEntry(id: self.description, formatArgs: nil, throwable: nil, sensitivity: StatusEntry.SensitivityLevel.NOT_SENSITIVE, priority: StatusEntry.PriorityLevel.DEBUG)
            
            // If user decides to disclose diagnostics data
            if (sendDiagnosticInfo == true) {
                
                var diagnosticHistoryArray: [[String:AnyObject]] = []
                
                for diagnosticEntry in PsiphonData.sharedInstance.getDiagnosticHistory() {
                    let entry: [String:AnyObject] = [
                        "data": diagnosticEntry.getData(),
                        "msg": diagnosticEntry.getMsg(),
                        "timestamp!!timestamp": diagnosticEntry.getTimestamp()
                    ]
                    diagnosticHistoryArray.append(entry)
                }
                
                var statusHistoryArray: [[String:AnyObject]] = []
                
                for statusEntry in PsiphonData.sharedInstance.getStatusHistory() {
                    // Sensitive logs pre-removed

                    let entry: [String:AnyObject] = [
                        "id": statusEntry.getId(),
                        "timestamp!!timestamp": statusEntry.getTimestamp(),
                        "priority": statusEntry.getPriority(),
                        "formatArgs": valOrNull(opt: statusEntry.getFormatArgs()), // Sensitive format args pre-removed
                        "throwable": valOrNull(opt: statusEntry.getThrowable() as! AnyObject?)
                    ]
                    statusHistoryArray.append(entry)
                }
                
                let diagnosticInfo = [
                    "DiagnosticHistory": diagnosticHistoryArray,
                    "StatusHistory": statusHistoryArray,
                    "SystemInformation": [
                        "Build": gatherDeviceInfo(),
                        "PsiphonInfo": [
                            "CLIENT_VERSION": Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String,
                            "PROPAGATION_CHANNEL_ID": PsiphonConfig.sharedInstance.getField(field: "PropagationChannelId"),
                            "SPONSOR_ID": PsiphonConfig.sharedInstance.getField(field: "SponsorId")
                        ],
                        "isAppStoreBuild": isAppStoreBuild(),
                        "isJailbroken": isJailBroken(),
                        "language": decodedJson["language"] as! String, // NSLocale.preferredLanguages[0].lowercased(), // TODO: Is this right "en-CA" desired "en"?
                        "networkTypeName": PsiphonCommon.getNetworkType()
                    ]
                ]
                
                feedbackBlob["DiagnosticInfo"] = diagnosticInfo
            }
            
            // Generate random feedback ID
            var rndmHexId: String = ""
            guard let randomBytes: [UInt8] = PsiphonCommon.getRandomBytes(numBytes: 8) else {
                throw PsiphonError.Runtime("failed to generate enough random bytes")
            }
            
            // Turn randomBytes into array of hexadecimal strings
            // Join array of strings into single string
            // http://jamescarroll.xyz/2015/09/09/safely-generating-cryptographically-secure-random-numbers-with-swift/
            rndmHexId = randomBytes.map({String(format: "%02hhX", $0)}).joined(separator: "")
            
            feedbackBlob["Metadata"] = [
                "id": rndmHexId,
                "platform": "ios",
                "version": 1
            ]
            
            // Serialize feedback json
            let jsonData = try JSONSerialization.data(withJSONObject: feedbackBlob, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
            print(jsonString)
            
            sendFeedback(feedbackData: jsonString)
        } catch PsiphonError.Runtime(let error) {
            PsiphonData.sharedInstance.addStatusEntry(id: self.description, formatArgs: [], throwable: Throwable(message: error, stackTrace: Thread.callStackSymbols),
                                                      sensitivity: StatusEntry.SensitivityLevel.NOT_SENSITIVE, priority: StatusEntry.PriorityLevel.ERROR)
        } catch(let unknownError) {
            PsiphonData.sharedInstance.addStatusEntry(id: self.description, formatArgs: [], throwable: Throwable(message: unknownError.localizedDescription, stackTrace: Thread.callStackSymbols),
                                                      sensitivity: StatusEntry.SensitivityLevel.NOT_SENSITIVE, priority: StatusEntry.PriorityLevel.ERROR)
        }
        
        self.dismiss(animated: true, completion: nil) // Dismiss feedback view
    }
    
    func sendFeedback(feedbackData: String) {
        // Stubbed for now
    }
    
    func gatherDeviceInfo() -> Dictionary<String, String> {
        var deviceInfo: Dictionary<String, String> = [:]
        
        // Get device for profiling
        let device = UIDevice.current
        
        let userInterfaceIdiom = device.userInterfaceIdiom
        var userInterfaceIdiomString = ""
        
        switch userInterfaceIdiom {
        case UIUserInterfaceIdiom.unspecified:
            userInterfaceIdiomString = "unspecified"
        case UIUserInterfaceIdiom.phone:
            userInterfaceIdiomString = "phone"
        case UIUserInterfaceIdiom.pad:
            userInterfaceIdiomString = "pad"
        case UIUserInterfaceIdiom.tv:
            userInterfaceIdiomString = "tv"
        case UIUserInterfaceIdiom.carPlay:
            userInterfaceIdiomString = "carPlay"
        }

        //deviceInfo["name"] = device.name
        deviceInfo["systemName"] = device.systemName
        deviceInfo["systemVersion"] = device.systemVersion
        deviceInfo["model"] = device.model
        deviceInfo["localizedModel"] = device.localizedModel
        deviceInfo["userInterfaceIdiom"] = userInterfaceIdiomString
        deviceInfo["identifierForVendor"] = device.identifierForVendor!.uuidString
        
        return deviceInfo
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
