//
//  FeedbackViewController.swift
//  Psiphon-Browser
//
//  Created by Miro Kuratczyk on 2016-08-09.
//  Copyright © 2016 Psiphon. All rights reserved.
//

function sendFeedback(feedbackJson){
    window.webkit.messageHandlers.native.postMessage(feedbackJson)
}
