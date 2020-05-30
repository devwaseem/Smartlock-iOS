//
//  Extensions.swift
//  smartlock
//
//  Created by Waseem Akram on 16/02/20.
//  Copyright © 2020 Waseem Akram. All rights reserved.
//

import Foundation
import UIKit

func getWiFiAddress() -> String? {
    var address : String?

    // Get list of all interfaces on the local machine:
    var ifaddr : UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return nil }
    guard let firstAddr = ifaddr else { return nil }

    // For each interface ...
    for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let interface = ifptr.pointee

        // Check for IPv4 or IPv6 interface:
        let addrFamily = interface.ifa_addr.pointee.sa_family
        //if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {  // **ipv6 committed
        if addrFamily == UInt8(AF_INET){

            // Check interface name:
            let name = String(cString: interface.ifa_name)
            if  name == "en0" {

                // Convert interface address to a human readable string:
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)
            }
        }
    }
    freeifaddrs(ifaddr)

    return address
}

func isValidIP(s: String) -> Bool {
    let parts = s.split(separator: ".")
    let nums = parts.compactMap { Int($0) }
    return parts.count == 4 && nums.count == 4 && nums.filter { $0 >= 0 && $0 < 256}.count == 4
}




func getPlaceholderIpAddress() -> String {
    if let ipAddress = getWiFiAddress() {
        let ipArr = ipAddress.split(separator: ".")
        var placeholderIp = ""
        for i in 0..<3 {
            placeholderIp += ipArr[i] + "."
        }
        return placeholderIp
    }else {
        return ""
    }
}


extension UIViewController {
    func simpleAlert(title:String?,message:String?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func simpleAlertWithHandler(title:String?,message:String?,completion: @escaping ()->Void){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            completion()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func simpleAlertWithTextField(
        title:String?,
        message:String?,
        textfieldConfiguration:@escaping (UITextField) -> Void,
        okHandler:@escaping (UIAlertController?) -> Void
    ){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField(configurationHandler: textfieldConfiguration)

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
           okHandler(alert)
        }))

        self.present(alert, animated: true, completion: nil)
    }
}


extension String {

    func sha256() -> String{
        if let stringData = self.data(using: String.Encoding.utf8) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }
        return ""
    }

    private func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }

    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)

        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }

        return hexString
    }
    
    var isPhoneNumber: Bool {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
            let matches = detector.matches(in: self, options: [], range: NSMakeRange(0, self.count))
            if let res = matches.first {
                return res.resultType == .phoneNumber && res.range.location == 0 && res.range.length == self.count
            } else {
                return false
            }
        } catch {
            return false
        }
    }

}

