//
//  Server.swift
//  smartlock
//
//  Created by Waseem Akram on 16/02/20.
//  Copyright © 2020 Waseem Akram. All rights reserved.
//

import Alamofire
import SwiftyRSA

enum DoorStatus {
    case locked,unlocked
}


class Server {
    
    
    static let shared = Server()
    
    var systemIp : String {
        get {
            UserDefaults.standard.string(forKey: SYSTEM_IP) ?? ""
        }
        
        set (newVal){
            UserDefaults.standard.set(newVal, forKey: SYSTEM_IP)
        }
    }
    
    var publicKey : String {
        get {
            UserDefaults.standard.string(forKey: PUBLIC_KEY) ?? ""
        }
        
        set (newVal){
            UserDefaults.standard.set(newVal, forKey: PUBLIC_KEY)
        }
    }
    
    
    var token : String {
        get {
            UserDefaults.standard.string(forKey: TOKEN) ?? ""
        }
        
        set (newVal){
            UserDefaults.standard.set(newVal, forKey: TOKEN)
        }
    }
    
    let port = "5000"
    
    private init(){
        
    }
    
    var currentDoorStatus = DoorStatus.locked
    
    func getDoorStatus(completion:@escaping (DoorStatus?)->Void){
        if systemIp == "" {
            completion(nil)
        }
        var request = URLRequest(url: URL(string: "http://\(systemIp):\(port)/doorstatus")!)
        request.timeoutInterval = 5
        Alamofire.request(request as URLRequestConvertible).responseJSON { (response) in
            if let status = response.response?.statusCode {
                if !(status >= 200 && status < 300) {
                    completion(nil)
                }
            }else {
                completion(nil)
            }
            
            if let result = response.result.value {
                let responseJson = result as! NSDictionary
                let success = responseJson["success"] as! Bool
                if !success {
                    completion(nil)
                    return
                }
                let doorStatus = responseJson["status"] as! String
                if doorStatus == "unlocked" {
                    completion(.unlocked)
                    return
                }
                completion(.locked)
            }else {
                completion(nil)
            }
        }
        
    }
    
    func getPublicKey(completion:@escaping (String?)->Void){
        if systemIp == "" {
            completion(nil)
        }
        var request = URLRequest(url: URL(string: "http://\(systemIp):\(port)/publickey")!)
        request.timeoutInterval = 5
        Alamofire.request(request as URLRequestConvertible).responseJSON { (response) in
            if let status = response.response?.statusCode {
                if !(status >= 200 && status < 300) {
                    completion(nil)
                }
            }else {
                completion(nil)
            }
            
            if let result = response.result.value {
                let responseJson = result as! NSDictionary
                let success = responseJson["success"] as! Bool
                if !success {
                    completion(nil)
                    return
                }
                completion(responseJson["key"] as? String)
            }else {
                completion(nil)
            }
        }
        
    }
    
    
    
    func registerDevice(name:String,mobile:String,masterKey:String,completion:@escaping (Bool,String,String?,Int)->Void){
        if systemIp == "" || publicKey == "" {
            completion(false,"Something went wrong, Please try again later.",nil,0)
        }
        
        let publicKeyObj = try? PublicKey(pemEncoded: publicKey)

        if publicKeyObj == nil {
            self.systemIp = ""
            self.publicKey = ""
            completion(false,"Cannot Verify Smartlock digital key, Please restart the app. ",nil,1)
            return
        }
        guard
            let encodedName = try? ClearMessage(string: name, using: .utf8),
            let encryptedName = try? encodedName.encrypted(with: publicKeyObj!, padding: .OAEP).base64String,
            let encodedMobile = try? ClearMessage(string: mobile, using: .utf8),
            let encryptedMobile = try? encodedMobile.encrypted(with: publicKeyObj!, padding: .OAEP).base64String,
            let encodedMasterKey = try? ClearMessage(string: masterKey.sha256(), using: .utf8),
            let encryptedMasterKey = try? encodedMasterKey.encrypted(with: publicKeyObj!, padding: .OAEP).base64String
        else {
            completion(false,"Something went Wrong",nil,2)
            return
        }

        let parameters:Parameters = ["name":encryptedName,
                                     "mobile":encryptedMobile,
                                     "masterkey":encryptedMasterKey
                                    ]
        
        Alamofire.request("http://\(systemIp):\(port)/registerclient", method: .post, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseJSON { (response) in
            if let status = response.response?.statusCode {
                if !(status >= 200 && status < 300) {
                    completion(false,"Something went wrong, Please try again",nil,3)
                }
            } else {
                completion(false,"Something went wrong, Please try again",nil,3)
            }
            
            if let result = response.result.value {
                let responseJson = result as! NSDictionary
                let success = responseJson["success"] as! Bool
                let token = responseJson["token"] as? String ?? ""
                let message = responseJson["message"] as! String
                completion(success,message,token,99)
            }else {
                completion(false,"Something went wrong, Please try again",nil,3)
            }
        }
        
    }
    
    func sendOTP(completion:@escaping (Bool,String)->Void){
        if self.token == "" {
            completion(false,"Device not registered..Please logout and re-register")
            return
        }
        let headers:HTTPHeaders = ["authorization":"Bearer \(self.token)"]
        
        Alamofire.request("http://\(systemIp):\(port)/sendotp", method: .post, encoding: URLEncoding.default, headers: headers).responseJSON { (response) in
            if let status = response.response?.statusCode {
                if !(status >= 200 && status < 300) {
                    completion(false,"Something went wrong, Please try again")
                }
            } else {
                completion(false,"Something went wrong, Please try again")
            }
            
            if let result = response.result.value {
                let responseJson = result as! NSDictionary
                let success = responseJson["success"] as! Bool
                let message = responseJson["message"] as! String
                let otp = responseJson["otp"] as? String ?? ""
                UIPasteboard.general.string = otp
                completion(success,message)
            }else {
                completion(false,"Something went wrong, Please try again")
            }
        }
    }
    
    func unlockDoor(otp:String,completion:@escaping (Bool,String)->Void){
        
        if systemIp == "" || publicKey == "" {
            completion(false,"Something went wrong, Please try again later.")
        }
        
        if self.token == "" {
            completion(false,"Device not registered..Please logout and re-register")
            return
        }
        
        if otp == "" {
            completion(false,"Invalid OTP")
            return
        }
        
        let publicKeyObj = try? PublicKey(pemEncoded: publicKey)

        if publicKeyObj == nil {
            self.systemIp = ""
            self.publicKey = ""
            completion(false,"Cannot Verify Smartlock digital key, Please restart the app. ")
            return
        }
        guard
            let encodedOTP = try? ClearMessage(string: otp, using: .utf8),
            let encryptedOTP = try? encodedOTP.encrypted(with: publicKeyObj!, padding: .OAEP).base64String
        else {
            completion(false,"Something went Wrong")
            return
        }
        
        let headers:HTTPHeaders = ["authorization":"Bearer \(self.token)"]
        let parameters:Parameters = ["otp":encryptedOTP]
        
        Alamofire.request("http://\(systemIp):\(port)/unlockdoor", method: .post, parameters:parameters, encoding: URLEncoding.default, headers: headers).responseJSON { (response) in
            if let status = response.response?.statusCode {
                if !(status >= 200 && status < 300) {
                    completion(false,"Something went wrong, Please try again")
                }
            } else {
                completion(false,"Something went wrong, Please try again")
            }
            
            if let result = response.result.value {
                let responseJson = result as! NSDictionary
                let success = responseJson["success"] as! Bool
                let message = responseJson["message"] as! String
                completion(success,message)
                return
            }else {
                completion(false,"Something went wrong, Please try again")
            }
        }
    }
    
    
}
