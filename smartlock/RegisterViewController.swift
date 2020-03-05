//
//  RegisterViewController.swift
//  smartlock
//
//  Created by Waseem Akram on 16/02/20.
//  Copyright © 2020 Waseem Akram. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var mobileField: UITextField!
    @IBOutlet weak var masterKeyField: UITextField!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameField.text = UIDevice.current.name
    }
    
    @IBAction func register(_ sender: Any) {
        if nameField.text == "" {
            simpleAlert(title: "Error in Registeration", message: "Please enter the device name")
            return
        }
        
        if mobileField.text == "" {
            simpleAlert(title: "Error in Registeration", message: "Please enter your mobile number")
            return
        }
        
        if masterKeyField.text == "" {
            simpleAlert(title: "Error in Registeration", message: "Please enter the master key")
            return
        }
        let loadingAlert = UIAlertController(title: "Loading...", message: "", preferredStyle: .alert)
        self.present(loadingAlert, animated: true, completion: nil)
        Server.shared.registerDevice(name: nameField.text!, mobile: mobileField!.text!, masterKey: masterKeyField!.text!) { (success, message, token,code) in
            loadingAlert.dismiss(animated: true) {
                if !success {
                    self.simpleAlert(title: "Error", message: message)
                    if code == 0 || code == 1 {
                        self.dismiss(animated: true, completion: nil)
                    }
                    return
                }
                if let token = token {
                    Server.shared.token = token
                    self.simpleAlertWithHandler(title: "Smart lock", message: "Device Registration Successful") {
                        self.dismiss(animated: true, completion: nil)
                    }
                    return
                }
            }
        }
    }
    

}
