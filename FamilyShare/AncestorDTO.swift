//
//  AncestorDTO.swift
//  FamilyShare
//
//  Created by Scott Nicholes on 12/13/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import Foundation

class AncestorDTO {
    var givenNames: String
    var surname: String
    var neededOrdinance: String
    var gender: String
    var familySearchId: String
    
    init(givenNames: String, surname: String, neededOrdinance: String, gender: String, familySearchId: String) {
        self.givenNames = givenNames
        self.surname = surname
        self.neededOrdinance = neededOrdinance
        self.gender = gender
        self.familySearchId = familySearchId
    }
    
    init(_ pdfLines: [String], digitRegex: NSRegularExpression) {
        func parseOrdinanceNeeded(_ pdfLines: [String], _ digitRegex: NSRegularExpression) -> String? {
            guard var ordinanceIndex = pdfLines.firstIndex(of: "Baptism") else {
                return nil
            }
            
            // For each of the 5 possible ordinances
            for i in 0..<4 {
                // Run Regex on the index ahead
                if digitRegex.numberOfMatches(in: pdfLines[ordinanceIndex + 1], options: [], range: NSMakeRange(0, pdfLines[ordinanceIndex + 1].count)) == 0 {
                    break
                } else if i == 3 {
                    ordinanceIndex = ordinanceIndex + 1
                    break
                } else {
                    ordinanceIndex = ordinanceIndex + 2
                }
            }
            return pdfLines[ordinanceIndex]
        }
        
        func parseName(_ pdfLines: [String], _ forOrdinance: String) -> (givenNames: String, surname: String)? {
            //        for i in 0..<pdfLines.count {
            //            if pdfLines[i].contains("Given Names") {
            //                let givenNames = pdfLines[i + 3]
            //                let surname = pdfLines[i + 4]
            //
            //                return givenNames + " " + surname
            //            }
            //        }
            
            guard let givenNameIndex = pdfLines.firstIndex(of: "Given Names") else {
                return nil
            }
            
            return forOrdinance == "Sealing To Parents" ? (pdfLines[givenNameIndex + 3], pdfLines[givenNameIndex + 4]) : (pdfLines[givenNameIndex + 2], pdfLines[givenNameIndex + 3])
        }
        
        func parseFamilySearchId(_ pdfLines: [String]) -> String? {
            for i in 0..<pdfLines.count {
                if pdfLines[i].contains("Birth") {
                    return pdfLines[i - 1]
                }
            }
            
            return nil
        }
        
        // Get the ordinanceNeeded for this ancestor
        guard let neededOrdinance = parseOrdinanceNeeded(pdfLines, digitRegex) else {
            fatalError("Ancestor ordinanceNeeded was not parsed from PDF String")
        }
        
        self.neededOrdinance = neededOrdinance
        
        // Get the name of this ancestor
        guard let nameTuple = parseName(pdfLines, neededOrdinance) else {
            fatalError("Ancestor name was not parsed from PDF String")
        }
        
        print("pdfLines count: \(pdfLines.count)")
        
        self.givenNames = nameTuple.givenNames
        self.surname = nameTuple.surname
        
        // Get the FamilySearch ID of this ancestor
        guard let familySearchId = parseFamilySearchId(pdfLines) else {
            fatalError("Ancestor familySearchId was not parsed from PDF String")
        }
        
        self.familySearchId = familySearchId
        
        // Get the gender of this ancestor
        self.gender = pdfLines[pdfLines.count - 3]
    }
}
