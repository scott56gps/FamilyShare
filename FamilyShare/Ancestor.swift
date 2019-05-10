//
//  AncestorDTO.swift
//  FamilyShare
//
//  Created by Scott Nicholes on 12/13/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import Foundation
import PDFKit

class Ancestor {
    var id: Int?
    var givenNames: String
    var surname: String
    var neededOrdinance: String
    var gender: String
    var familySearchId: String
    
    init(id: Int?, givenNames: String, surname: String, neededOrdinance: String, gender: String, familySearchId: String) {
        self.id = id
        self.givenNames = givenNames
        self.surname = surname
        self.neededOrdinance = neededOrdinance
        self.gender = gender
        self.familySearchId = familySearchId
    }
    
    init(_ templeCardPdf: PDFDocument) {
        func parsePDF(pdfDocument: PDFDocument) -> [String] {
            // Get an array of lines of the PDF String
            if let pdfString = pdfDocument.string {
                var pdfLines = pdfString.components(separatedBy: CharacterSet.newlines)
                
                // Trim the whitespace in the array of pdfLines
                pdfLines = pdfLines.map {
                    $0.trimmingCharacters(in: CharacterSet.whitespaces)
                }
                
                return pdfLines
            } else {
                fatalError("PDF String could not be extracted using the iOS API")
            }
        }
        
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
            
            let parentsRegex = try! NSRegularExpression(pattern: "\\s", options: NSRegularExpression.Options.caseInsensitive)
            
            let numberOfMatches = parentsRegex.numberOfMatches(in: pdfLines[givenNameIndex + 2], options: [], range: NSMakeRange(0, pdfLines[givenNameIndex + 2].count))
            
//            return forOrdinance == "Sealing To Parents" ? (pdfLines[givenNameIndex + 3], pdfLines[givenNameIndex + 4]) : (pdfLines[givenNameIndex + 2], pdfLines[givenNameIndex + 3])
            return numberOfMatches <= 1 ? (pdfLines[givenNameIndex + 2], pdfLines[givenNameIndex + 3]) : (pdfLines[givenNameIndex + 3], pdfLines[givenNameIndex + 4])
        }
        
        func parseFamilySearchId(_ pdfString: String, familySearchIdRegex: NSRegularExpression) -> String {
//            for i in 0..<pdfLines.count {
//                if pdfLines[i].contains("Birth") {
//                    return pdfLines[i - 1]
//                }
//            }

            let matchedFamilySearchId = familySearchIdRegex.firstMatch(in: pdfString, options: [], range: NSMakeRange(0, pdfString.count))
            
            let matchedString = String(pdfString[Range(matchedFamilySearchId!.range, in: pdfString)!])
            
            return matchedString
        }
        
        // Get the parsed lines for the document
        var pdfLines = parsePDF(pdfDocument: templeCardPdf)
        
        let digitRegex = try! NSRegularExpression(pattern: "\\d", options: NSRegularExpression.Options.caseInsensitive)
        let familySearchIdRegex = try! NSRegularExpression(pattern: "[A-Z0-9]+-[A-Z0-9]+", options: NSRegularExpression.Options.caseInsensitive)
        
        // Get the ordinanceNeeded for this ancestor
        guard let neededOrdinance = parseOrdinanceNeeded(pdfLines, digitRegex) else {
            fatalError("Ancestor ordinanceNeeded was not parsed from PDF String")
        }
        
        self.neededOrdinance = neededOrdinance
        
        // Get the name of this ancestor
        guard let nameTuple = parseName(pdfLines, neededOrdinance) else {
            fatalError("Ancestor name was not parsed from PDF String")
        }
        
        self.givenNames = nameTuple.givenNames
        self.surname = nameTuple.surname
        
        // Get the FamilySearch ID of this ancestor
        let familySearchId = parseFamilySearchId(templeCardPdf.string!, familySearchIdRegex: familySearchIdRegex)
        
        self.familySearchId = familySearchId
        
        // Get the gender of this ancestor
        self.gender = pdfLines[pdfLines.count - 3]
    }
}
