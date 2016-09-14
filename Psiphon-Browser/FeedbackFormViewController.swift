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

struct Feedback {
    var title: String
    var question: String
    var answer: Int

    var description : String {
        return "[{\"answer\":\(answer),\"question\":\"\(question)\", \"title\":\"\(title)\"}]"
    }
}

class FeedbackFormViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    @IBOutlet var containerView : UIWebView? = nil
    var webView: WKWebView?
    
    override func loadView() {
        super.loadView()
        self.webView = WKWebView()
        self.view = self.webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFeedbackForm()
    }

    // Load feedback html into webview
    func loadFeedbackForm() {
        let wkConfig = WKWebViewConfiguration()
        wkConfig.userContentController.add(self, name: "native")
        
        let feedbackHTMLPath = Bundle.main.path(forResource: "feedback", ofType: "html")
        let htmlUrl = URL(fileURLWithPath: feedbackHTMLPath!)
        
        let faqURL = (PsiphonConfig.sharedInstance.getField(field: "FAQ_URL") as! String).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let dataCollectionInfoURL = (PsiphonConfig.sharedInstance.getField(field: "DATA_COLLECTION_INFO_URL") as! String).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        
        let args = "?{\"faqURL\":\"\(faqURL)\",\"dataCollectionInfoURL\":\"\(dataCollectionInfoURL)\"}#" + NSLocale.preferredLanguages[0].lowercased().components(separatedBy: "-")[0]
        
        let url = URL(dataRepresentation: args.data(using: .utf8)!, relativeTo: htmlUrl)!
        let request = URLRequest(url: url)

        self.webView = WKWebView(frame: self.view.frame, configuration: wkConfig)
        self.webView?.navigationDelegate = self
        self.webView!.load(request)
        self.view = self.webView!
    }

    // Open links in Browser instead of webview
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated  {
            let url = navigationAction.request.url
            let pageToLoad = url?.absoluteString

            let browserVC = PsiphonBrowserViewController()
            let navCntrl = UINavigationController.init(rootViewController: browserVC)
            navCntrl.navigationBar.isHidden = true

            self.present(navCntrl, animated: true, completion: { browserVC.addTab(withAddress: pageToLoad) })
            decisionHandler(.cancel)
        }
        // Not a user interaction
        decisionHandler(.allow)
    }
    
    // Received javascript callback with feedback form info
    // Form and send feedback blob which conforms to structure
    // expected by the feedback template for ios,
    // https://bitbucket.org/psiphon/psiphon-circumvention-system/src/default/EmailResponder/FeedbackDecryptor/templates/?at=default
    // Matching format used by android client,
    // https://bitbucket.org/psiphon/psiphon-circumvention-system/src/default/Android/app/src/main/java/com/psiphon3/psiphonlibrary/Diagnostics.java
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        do {
            let dataString: String = message.body as! String
            let data: Data = dataString.data(using: String.Encoding.utf8) as Data!
            var decodedJson = try JSONSerialization.jsonObject(with: data) as! Dictionary<String, AnyObject>
            
            let sendDiagnosticInfo = decodedJson["sendDiagnosticInfo"] as! Bool
            
            var feedbackBlob: [String:AnyObject] = [:]
            
            var surveyResponse = ""
            let responsesArray = (decodedJson["responses"] as! [[String:AnyObject]])
            
            // Ensure either feedback or survey response was completed
            if (responsesArray.count == 0 && (decodedJson["feedback"] as! String).characters.count == 0) {
                throw PsiphonError.Runtime("Submitted empty feedback")
            }
            
            // Check survey response
            if (responsesArray.count > 0) {
                let responses = responsesArray[0]
                surveyResponse = Feedback(title: responses["title"] as! String, question: responses["question"] as! String, answer: responses["answer"] as! Int).description
            }
            
            feedbackBlob["Feedback"] = [
                "email": decodedJson["email"] as! String,
                "Message": [
                    "text": decodedJson["feedback"] as! String
                ],
                "Survey": [
                    "json": surveyResponse
                ]
            ] as AnyObject

            // If user decides to disclose diagnostics data
            if (sendDiagnosticInfo == true) {
                
                var diagnosticHistoryArray: [[String:AnyObject]] = []
                
                for diagnosticEntry in PsiphonData.sharedInstance.getDiagnosticHistory() {
                    let entry: [String:AnyObject] = [
                        "data": diagnosticEntry.getData() as AnyObject,
                        "msg": diagnosticEntry.getMsg() as AnyObject,
                        "timestamp!!timestamp": diagnosticEntry.getTimestamp() as AnyObject
                    ]
                    diagnosticHistoryArray.append(entry)
                }
                
                var statusHistoryArray: [[String:AnyObject]] = []
                
                for statusEntry in PsiphonData.sharedInstance.getStatusHistory() { // Sensitive logs pre-removed
                    let entry: [String:AnyObject] = [
                        "id": statusEntry.getId() as AnyObject,
                        "timestamp!!timestamp": statusEntry.getTimestamp() as AnyObject,
                        "priority": statusEntry.getPriority() as AnyObject,
                        "formatArgs": valOrNull(opt: statusEntry.getFormatArgs() as AnyObject?), // Sensitive format args pre-removed
                        "throwable": valOrNull(opt: statusEntry.getThrowable() as AnyObject?)
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
                        "language": NSLocale.preferredLanguages[0].lowercased(),
                        "networkTypeName": PsiphonCommon.getNetworkType()
                    ]
                ] as [String:Any]
                feedbackBlob["DiagnosticInfo"] = diagnosticInfo as AnyObject?
            }
            
            // Generate random feedback ID
            var rndmHexId: String = ""
            
            let result: Result<[UInt8]> = PsiphonCommon.getRandomBytes(numBytes: 8)
            
            switch result {
            case let .Value(randomBytes):
                // Turn randomBytes into array of hexadecimal strings
                // Join array of strings into single string
                // http://jamescarroll.xyz/2015/09/09/safely-generating-cryptographically-secure-random-numbers-with-swift/
                rndmHexId = randomBytes.map({String(format: "%02hhX", $0)}).joined(separator: "")
            case let .Error(error):
                throw PsiphonError.Runtime(error)
            }
            
            feedbackBlob["Metadata"] = [
                "id": rndmHexId,
                "platform": "ios",
                "version": 1
            ] as AnyObject
            
            let jsonData = try JSONSerialization.data(withJSONObject: feedbackBlob)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
            
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
        let pubKey = PsiphonConfig.sharedInstance.getField(field: "FEEDBACK_ENCRYPTION_PUBLIC_KEY") as! String
        let uploadServer = PsiphonConfig.sharedInstance.getField(field: "FEEDBACK_DIAGNOSTIC_INFO_UPLOAD_SERVER") as! String
        let uploadPath = PsiphonConfig.sharedInstance.getField(field: "FEEDBACK_DIAGNOSTIC_INFO_UPLOAD_PATH") as! String
        let uploadServerHeaders = PsiphonConfig.sharedInstance.getField(field: "FEEDBACK_DIAGNOSTIC_INFO_UPLOAD_SERVER_HEADERS") as! String
            
        // Async upload
        DispatchQueue.global().async(execute: {
            Psi.sendFeedback(PsiphonConfig.sharedInstance.getConfig(), diagnostics: feedbackData, b64EncodedPublicKey: pubKey, uploadServer: uploadServer, uploadPath: uploadPath, uploadServerHeaders: uploadServerHeaders)
        })
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
