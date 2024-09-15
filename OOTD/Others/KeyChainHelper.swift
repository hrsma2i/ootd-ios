//
//  KeyChainHelper.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/13.
//

import Foundation
import Security
import WebKit

private let logger = getLogger(#file)

extension Date {
    func iso8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }

    init?(iso8601String: String) {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: iso8601String) {
            self = date
        } else {
            return nil
        }
    }
}

class KeyChainHelper {
    static let shared = KeyChainHelper()
    private init() {}
    private let account = "anonymous"
    
    func saveCookies(key: String, cookies: [HTTPCookie]) throws {
        let cookieData = cookies.map { cookie -> [String: Any] in
            let cookieDict: [String: Any] = [
                "name": cookie.name,
                "value": cookie.value,
                "domain": cookie.domain,
                "path": cookie.path,
                "secure": cookie.isSecure,
                "expiresDate": cookie.expiresDate?.iso8601String() ?? "",
            ]
            return cookieDict
        }
        let data = try JSONSerialization.data(withJSONObject: cookieData, options: [])
        try save(data, service: key)
    }
    
    func loadCookies(key: String) throws -> [HTTPCookie] {
        let data = try load(service: key)
        guard let cookieData = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
            throw "failed to load cookie \(key)"
        }
        
        let cookies = cookieData.compactMap { cookieDict -> HTTPCookie? in
            guard let name = cookieDict["name"] as? String,
                  let value = cookieDict["value"] as? String,
                  let domain = cookieDict["domain"] as? String,
                  let path = cookieDict["path"] as? String,
                  let secure = cookieDict["secure"] as? Bool
            else {
                logger.error("convert cookieDict=\(cookieDict) has some nil value")
                return nil
            }
            
            let expiresDate: Date?
            if let expiresDateString = cookieDict["expiresDate"] as? String {
                expiresDate = Date(iso8601String: expiresDateString)
            } else {
                // session cookie
                expiresDate = nil
            }

            let cookieProperties: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: value,
                .domain: domain,
                .path: path,
                .secure: secure,
                .expires: expiresDate as Any,
            ]
                        
            guard let cookie = HTTPCookie(properties: cookieProperties) else { return nil }
                
            return cookie
        }
        return cookies
    }
    
    func save(_ data: Data, service: String) throws {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as CFDictionary
        
        let matchingStatus = SecItemCopyMatching(query, nil)
        switch matchingStatus {
        case errSecItemNotFound:
            // データが存在しない場合は保存
            let status = SecItemAdd(query, nil)
            if status != noErr {
                throw "\(status)"
            }
            logger.debug("[KeyChain] save \(service)")
        case errSecSuccess:
            SecItemUpdate(query, [kSecValueData as String: data] as CFDictionary)
            logger.debug("[KeyChain] update \(service)")
        default:
            throw "Failed to save data to keychain"
        }
    }
    
    func load(service: String) throws -> Data {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true,
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        guard let data = (result as? Data) else {
            throw "loaded keychain result is not Data"
        }
        
        logger.debug("[KeyChain] load \(service)")
        return data
    }
    
    func delete(service: String) throws {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
        ] as CFDictionary
        
        let status = SecItemDelete(query)
        if status != noErr {
            throw "\(status)"
        }
    }
}
