//
//  AncestorModel.swift
//  FamilyShare
//
//  Created by Scott Nicholes on 4/16/19.
//  Copyright © 2019 Scott Nicholes. All rights reserved.
//

import Foundation
import PDFKit
import Alamofire

class AncestorModel {
    var url = URL(string: "https://familyshare-server.herokuapp.com")!
    
    func getAvailableAncestorSummaries(_ callback: @escaping (Error?, [Ancestor]?) -> Void) {
        // Make a request to get the available ancestor summaries
        let availableUrl = url.appendingPathComponent("ancestors")
        getAncestors(summaryUrl: availableUrl) { (error: Error?, ancestors: [Ancestor]?) -> Void in
            guard error == nil else {
                callback(error, nil)
                return
            }
            
            guard ancestors != nil else {
                callback(nil, nil)
                return
            }
            
            callback(nil, ancestors)
        }
    }
    
    func getReservedAncestorSummaries(forUserId: Int, _ callback: @escaping (Error?, [Ancestor]?) -> Void) {
        // Make a request to get the reserved ancestor summaries for this userId
        let reservedUrl = url.appendingPathComponent("ancestors/\(String(forUserId))")
        getAncestors(summaryUrl: reservedUrl) { (error: Error?, ancestors: [Ancestor]?) -> Void in
            guard error == nil else {
                callback(error, nil)
                return
            }
            
            guard ancestors != nil else {
                callback(nil, nil)
                return
            }
            
            callback(nil, ancestors)
        }
    }
    
    func getTempleCardForAncestor(ancestor: Ancestor, _ callback: @escaping (String?, PDFDocument?) -> Void) {
        // Set the parameters for the GET request
        guard let ancestorId = ancestor.id else {
            callback("Could not retrieve ancestorId", nil)
            return
        }
        
        let templeCardUrl = url.appendingPathComponent("templeCard/\(String(ancestorId))")
        
        // Create a place to put the PDF once downloaded
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(ancestor.familySearchId).pdf")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        // Make an Alamofire GET request to get the temple card for this ancestorId
        Alamofire.download(templeCardUrl, to: destination).response { response in
            if response.error == nil {
                guard let fileURL = response.destinationURL else {
                    callback("fileURL is nil", nil)
                    return
                }
                
                if let pdf = PDFDocument(url: fileURL) {
                    callback(nil, pdf)
                } else {
                    callback("Could not retrieve PDFDocument from url: \(fileURL)", nil)
                }
            } else {
                callback("There was an error in downloading the PDF", nil)
            }
        }
    }
    
    func reserveAncestor(ancestor: Ancestor, userId: String, _ callback: @escaping (Ancestor?) -> Void) {
        let parameters: [String: AnyObject] = [
            "ancestorId": ancestor.id as AnyObject,
            "userId": userId as AnyObject
        ]
        
        let reserveUrl = url.appendingPathComponent("reserve")
        
        Alamofire.request(reserveUrl, method: .put, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON() { response in
                switch response.result {
                case .success:
                    let ancestorDictionary = response.result.value as! Dictionary<String, Any>
                    
                    if let ancestor = Ancestor(ancestorDictionary: ancestorDictionary) {
                        callback(ancestor)
                    } else {
                        print("Did not instantiate Ancestor for dictionary: \(ancestorDictionary)")
                    }
                case .failure(let error):
                    print(error)
                    callback(nil)
                }
        }
    }
    
    func postAncestor(templeCard: PDFDocument, ancestor: Ancestor, _ callback: @escaping (String?, Ancestor?) -> Void) {
        // Make the share url
        let shareUrl = url.appendingPathComponent("ancestor")
        
        // Make parameters
        var parameters = [String: String]()
        parameters["givenNames"] = ancestor.givenNames
        parameters["surname"] = ancestor.surname
        parameters["gender"] = ancestor.gender
        parameters["ordinanceNeeded"] = ancestor.neededOrdinance.rawValue
        parameters["familySearchId"] = ancestor.familySearchId
        
        // Using Alamofire
        Alamofire.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(templeCard.documentURL!, withName: "templePdf", fileName: "\(ancestor.familySearchId).pdf", mimeType: "application/pdf")
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: .utf8)!, withName: key)
            }
        }, to: shareUrl, encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    debugPrint(response)
                    if let responseDictionary = response.result.value as? [String: String] {
                        callback(responseDictionary["success"], nil)
                    } else {
                        callback("Error", nil)
                    }
//                    if let ancestorDictionary = response.result.value as? Dictionary<String, Any> {
//                        // Create an Ancestor Object
//                        if let ancestor = Ancestor(ancestorDictionary: ancestorDictionary) {
//                            callback(nil, ancestor)
//                        } else {
//                            callback("Did not create Ancestor for Dictionary: \(ancestorDictionary)", nil)
//                        }
//                    } else {
//                        debugPrint("Did not create AncestorDictionary for value: \(response.result.value)")
//                        callback("Did not create AncestorDictionary for value: \(response.result.value)", nil)
//                    }
                }
            case .failure(let error):
                print(error)
                callback(error.localizedDescription, nil)
            }
        })
    }
    
    // MARK: Private Functions    
    private func getAncestors(summaryUrl: URL, _ callback: @escaping (Error?, [Ancestor]?) -> Void) {
        Alamofire.request(summaryUrl).responseJSON { response in
            switch response.result {
            case .success:
                var ancestors = [Ancestor]()
                let ancestorDictionaries = response.result.value as! [Dictionary<String, Any>]
                
                for ancestorDictionary in ancestorDictionaries {
                    // Create an Ancestor Object from the parts that we got from the JSON
                    if let ancestor = Ancestor(ancestorDictionary: ancestorDictionary) {
                        ancestors.append(ancestor)
                    }
                }
                
                callback(nil, ancestors)
                
            case .failure(let error):
                callback(error, nil)
            }
        }
    }
}
