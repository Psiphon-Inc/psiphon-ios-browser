//
//  FeedbackViewController.swift
//  Psiphon-Browser
//
//  Created by Miro Kuratczyk on 2016-08-25.
//  Copyright © 2016 Psiphon. All rights reserved.
//

import Foundation
import UIKit

class FeedbackViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
