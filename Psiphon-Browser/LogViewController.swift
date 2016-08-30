//
//  File.swift
//  Psiphon-Browser
//
//  Created by Miro Kuratczyk on 2016-08-25.
//  Copyright © 2016 Psiphon. All rights reserved.
//

import Foundation
import UIKit

class LogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var displayedLogs: [String] = []
    
    enum Buttons: Int {
        case OPEN_BROWSER = 0
        case FEEDBACK
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        segmentedControl.setEnabled(false, forSegmentAt: 0)
        
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(receivedConnectionEstablished), name: NSNotification.Name.init(rawValue: Constants.Notifications.ConnectionEstablished), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedUpdateLogsNotification), name: NSNotification.Name.init(rawValue: Constants.Notifications.DisplayLogEntry), object: nil)
    }
    
    func receivedConnectionEstablished(aNotification: Notification) {
        let result = aNotification.withName(name: Constants.Notifications.ConnectionEstablished)
        
        switch result {
        case .Value(_):
            self.segmentedControl.setEnabled(true, forSegmentAt: 0)
        case let .Error(error):
            print("Error receiving notification: " + String(error))
        }
    }
    
    func receivedUpdateLogsNotification(aNotification: Notification) {
        let result = aNotification.withName(name: Constants.Notifications.DisplayLogEntry)
        
        switch result {
        case .Value(_):
            displayedLogs = PsiphonData.sharedInstance.getDiagnosticLogs()
            tableView.reloadData()
            scrollToBottom()
        case let .Error(error):
            print("Error receiving notification: " + String(error))
        }
    }
    
    func scrollToBottom() {
        let bottomOffset: CGPoint = CGPoint(x: 0, y: tableView.contentSize.height - tableView.frame.size.height)
        tableView.setContentOffset(bottomOffset, animated: true)
    }
    
    @IBAction func segmentedControlButtonPressed(_ sender: UISegmentedControl) {
        if (sender.selectedSegmentIndex == Buttons.OPEN_BROWSER.rawValue) {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let homepage = appDelegate.getHomepage()
            let pageToLoad = homepage != nil ? homepage! : ""
            
            let browserVC = PsiphonBrowserViewController()
            let navCntrl = UINavigationController.init(rootViewController: browserVC)
            navCntrl.navigationBar.isHidden = true
            self.present(navCntrl, animated: true, completion: { browserVC.addTab(withAddress: pageToLoad)} )
            
        } else if (sender.selectedSegmentIndex == Buttons.FEEDBACK.rawValue) {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "FeedbackViewController")
            self.present(vc!, animated: true, completion: nil)
        } else {
            // Unreachable: Do nothing
        }
        
        scrollToBottom()
        sender.selectedSegmentIndex = -1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.displayedLogs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        
        cell.textLabel?.text = self.displayedLogs[indexPath.row]
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       print("You selected cell #\(indexPath.row)!") // TODO: remove
    }
}
