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
    var url = URL(string: "https://postgres-query-ancestors.herokuapp.com")!
    
    func postAncestor(templeCard: PDFDocument, ancestor: Ancestor, _ callback: @escaping (AncestorSummary?) -> Void) {
        // Make the share url
        let shareUrl = url.appendingPathComponent("share")
        
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
}
