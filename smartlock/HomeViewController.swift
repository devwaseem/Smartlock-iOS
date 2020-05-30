//
//  HomeViewController.swift
//  smartlock
//
//  Created by Waseem Akram on 16/02/20.
//  Copyright © 2020 Waseem Akram. All rights reserved.
//

import UIKit


class HomeViewController: UIViewController {
    
    @IBOutlet weak var unlockButton: UIButton!
    @IBOutlet weak var lockStatusImageView: UIImageView!
    @IBOutlet weak var lockLabel: UILabel!
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.lockStatusImageView.image = nil
        self.lockLabel.text = ""
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        //check if ip address is added
        if Server.shared.systemIp == "" {
            self.timer.invalidate()
            getIpWithAlert()
        }else {
            //ip already added
            //check if ip working or show alert
            let loadingAlert = UIAlertController(title: "Connecting to smart lock...", message: "", preferredStyle: .alert)
            self.present(loadingAlert, animated: true, completion: nil)
            Server.shared.getDoorStatus { (status) in
                loadingAlert.dismiss(animated: true) {
                    if status == nil {
                        //problem with connecting...
                        self.getIpWithAlert()
                        return
                    }
                    self.setLayout(for: status!)
                    self.scheduledTimerWithTimeIntervalForDoorStatus()
                }
            }
        }
    }
    
    
    func getIpWithAlert(){
        simpleAlertWithTextField(title: "Smart lock", message: "Enter ip address of the smartlock", textfieldConfiguration: { (textField) in
            textField.text = getPlaceholderIpAddress()
        }) { (alert) in
            let textField = alert!.textFields![0]
            let systemIpAddress = textField.text!
            if !isValidIP(s: systemIpAddress) {
                let alert = UIAlertController(title: "Error", message: "Invalid IP Address. Please enter again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    alert.dismiss(animated: true) {
                        self.getIpWithAlert()
                    }
                }))
                self.present(alert, animated: true, completion: nil)
                return
            }
            Server.shared.systemIp = systemIpAddress
            let loadingAlert = UIAlertController(title: "Loading...", message: "", preferredStyle: .alert)
            self.present(loadingAlert, animated: true, completion: nil)
            Server.shared.getPublicKey { (key) in
                loadingAlert.dismiss(animated: true) {
                    if key == nil {
                        let alert = UIAlertController(title: "Error", message: "Cannot Connect to system", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                            alert.dismiss(animated: true) {
                                self.getIpWithAlert()
                            }
                        }))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    Server.shared.publicKey = key!
                    Server.shared.getDoorStatus { (status) in
                        loadingAlert.dismiss(animated: true) {
                            if status != nil {
                                self.setLayout(for: status!)
                                self.simpleAlert(title: "Smart Lock connected", message: nil)
                                self.scheduledTimerWithTimeIntervalForDoorStatus()
                            }else {
                                let alert = UIAlertController(title: "Error", message: "Cannot Connect to system", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                                    alert.dismiss(animated: true) {
                                        self.getIpWithAlert()
                                    }
                                }))
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setLayout(for status:DoorStatus){
        switch status {
        case .locked:
            self.lockStatusImageView.image = #imageLiteral(resourceName: "locked")
            self.lockLabel.text = "Locked"
            self.lockLabel.textColor = UIColor.init(red: 255/255, green: 0, blue: 87/255, alpha: 1)
            self.unlockButton.isHidden = false
        case .unlocked:
            self.lockStatusImageView.image = #imageLiteral(resourceName: "unlocked")
            self.lockLabel.text = "Unlocked"
            self.lockLabel.textColor = UIColor.init(red: 39/255, green: 174/255, blue: 96/255, alpha: 1)
            self.unlockButton.isHidden = true
        case .breached:
            self.lockStatusImageView.image = #imageLiteral(resourceName: "locked")
            self.lockLabel.text = "Breached"
            self.lockLabel.textColor = UIColor.init(red: 255/255, green: 0, blue: 87/255, alpha: 1)
            self.unlockButton.isHidden = true
        }
    }
    
    func scheduledTimerWithTimeIntervalForDoorStatus(){
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateDoorStatus), userInfo: nil, repeats: true)
    }
    
    @objc func updateDoorStatus(){
        Server.shared.getDoorStatus { (status) in
            if let status = status {
                self.setLayout(for: status)
            }else{
                self.timer.invalidate()
                self.getIpWithAlert()
            }
        }
    }
    
    @IBAction func unlockButtonPressed(_ sender: Any) {
        if Server.shared.token == "" {
            simpleAlertWithHandler(title: "Smart Lock", message: "This device is not registered to smart lock.") {
                self.performSegue(withIdentifier: "registerSegue", sender: self)
            }
            return
        }
        let loadingAlert = UIAlertController(title: "Sending OTP to registered mobile number...", message: "", preferredStyle: .alert)
        self.present(loadingAlert, animated: true, completion: nil)
        Server.shared.sendOTP { (success, message) in
            loadingAlert.dismiss(animated: true) {
                if !success {
                    self.simpleAlert(title: "Smart Lock", message: message)
                    return
                }
                self.simpleAlertWithHandler(title: message, message: nil) {
                    self.performSegue(withIdentifier: "otacSegue", sender: self)
                }
            }
        }
    }
    
    @IBAction func settingsButtonTapped(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Smart lock", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Change IP Address", style: .default, handler: { (_) in
            self.getIpWithAlert()
        }))
        
        if Server.shared.token != "" {
            actionSheet.addAction(UIAlertAction(title: "Logout", style: .default, handler: { (_) in
                Server.shared.token = ""
                self.simpleAlert(title: "Smart lock", message: "Logout successful")
            }))
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            actionSheet.dismiss(animated: true, completion: nil)
        }))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
}
