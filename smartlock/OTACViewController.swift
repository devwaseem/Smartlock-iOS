//
//  OTACViewController.swift
//  smartlock
//
//  Created by Waseem Akram on 16/02/20.
//  Copyright © 2020 Waseem Akram. All rights reserved.
//

import UIKit

class OTACViewController: UIViewController {

    @IBOutlet weak var otacField: UITextField!
    @IBOutlet weak var masterKeyField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func verifyOTAC(_ sender: Any) {
        if otacField.text == "" {
            self.simpleAlert(title: "Please enter OTP", message: nil)
            return
        }
        if masterKeyField.text == "" {
            self.simpleAlert(title: "Please enter master key", message: nil)
            return
        }
        let alert = UIAlertController(title: "Loading...", message: nil, preferredStyle: .alert)
        present(alert, animated: true, completion: nil)
        let masterKey = masterKeyField.text!.sha256()
        let otp = "\(otacField.text!)\(masterKey)".sha256()
        Server.shared.unlockDoor(otp:otp) { (success, message) in
            alert.dismiss(animated: true) {
                if !success {
                    self.simpleAlert(title: message, message: nil)
                    return
                }
                self.simpleAlertWithHandler(title: message, message: nil) {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}
