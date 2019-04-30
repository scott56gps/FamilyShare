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
    
    func getAvailableAncestorSummaries(_ callback: @escaping ([AncestorSummary]) -> Void) {
        // Make a request to get the available ancestor summaries
        let availableUrl = url.appendingPathComponent("ancestors")
        getAncestorSummaries(summaryUrl: availableUrl) { (ancestorSummaries: [AncestorSummary]?) -> Void in
            if ancestorSummaries != nil {
                callback(ancestorSummaries!)
            }
        }
        
    }
    
    func getReservedAncestorSummaries(forUserId: Int, _ callback: @escaping ([AncestorSummary]) -> Void) {
        // Make a request to get the reserved ancestor summaries for this userId
        let reservedUrl = url.appendingPathComponent("ancestors/\(String(forUserId))")
        getAncestorSummaries(summaryUrl: reservedUrl) { (ancestorSummaries: [AncestorSummary]?) -> Void in
            if ancestorSummaries != nil {
                callback(ancestorSummaries!)
            }
        }
    }
    
    func getTempleCardForAncestor(ancestor: Ancestor, _ callback: @escaping (PDFDocument?) -> Void) {
        // Set the parameters for the GET request
        guard let ancestorId = ancestor.id else {
            callback(nil)
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
            if response.error == nil, let fileURL = response.destinationURL {
                print ("PDF Downloaded!")
                
                if let pdf = PDFDocument(url: fileURL) {
                    callback(pdf)
                }
            } else {
                callback(nil)
            }
        }
    }
    
    func postAncestor(templeCard: PDFDocument, ancestor: Ancestor, _ callback: @escaping (AncestorSummary?) -> Void) {
        // Make the share url
        let shareUrl = url.appendingPathComponent("ancestor")
        
        // Make parameters
        var parameters = [String: String]()
        parameters["givenNames"] = ancestor.givenNames
        parameters["surname"] = ancestor.surname
        parameters["gender"] = ancestor.gender
        parameters["ordinanceNeeded"] = ancestor.neededOrdinance
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
                    
                }
            case .failure(let encodingError):
                print(encodingError)
            }
        })
    }
    
    // MARK: Private Functions
    private func getAncestorSummaries(summaryUrl: URL, _ callback: @escaping ([AncestorSummary]?) -> Void) {
        Alamofire.request(summaryUrl).responseJSON { response in
            if let json = response.result.value {
                let ancestorDictionaries = json as! [Dictionary<String, Any>]
                var ancestorSummaries = [AncestorSummary]()
                
                for ancestorDictionary in ancestorDictionaries {
                    // Create an AncestorSummary Object from the parts that we got from the JSON
                    if let ancestorSummary = AncestorSummary(ancestorDictionary: ancestorDictionary) {
                        ancestorSummaries.append(ancestorSummary)
                    }
                }
                
                callback(ancestorSummaries)
            }
        }
    }
}
