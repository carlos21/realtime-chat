//
//  FirstViewController.swift
//  RealtimeChat
//
//  Created by Carlos Duclos on 11/5/17.
//  Copyright © 2017 Carlos Duclos. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func sendPressed(_ sender: Any) {
        PubNubManager.instance.pusblish(message: textView.text)
    }
    

}

