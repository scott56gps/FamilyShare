//
//  SharedViewController.swift
//  FamilyShareWorkingPrototype
//
//  Created by Nellie Roberts on 6/23/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import UIKit
import PDFKit
import CoreGraphics
import Alamofire

class SharedAncestorsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate {
    
    //MARK: Properties
    let ancestorModel = AncestorModel()
    var ancestorSummaries = [AncestorSummary]()
    var ancestorToShare: Ancestor?
    var templeCard: PDFDocument?
    var selectedAncestorsCount = 0
    let defaults = UserDefaults.standard
    
    // MARK: Outlets
    @IBOutlet weak var reserveButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var ancestorTableView: UITableView!
    @IBOutlet weak var sliderConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ancestorTableView.dataSource = self
        ancestorTableView.delegate = self
        ancestorTableView.separatorColor = UIColor.black
        ancestorTableView.separatorInset = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        
        reserveButton.isEnabled = false
        reserveButton.alpha = 0.5
        shareButton.isEnabled = false
        shareButton.alpha = 0.5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        reserveButton.isEnabled = false
        
        // Only download the available ancestors if the user is signed in
        let defaultUserId = defaults.integer(forKey: "User Id")
        if defaultUserId == 0 {
            print("User Id nil.  User not signed in")
            infoLabel.isHidden = false
            shareButton.isEnabled = false
            reserveButton.isEnabled = false
            shareButton.alpha = 0.5
            ancestorSummaries.removeAll()
            ancestorTableView.reloadData()
        } else {
            infoLabel.isHidden = true
            shareButton.isEnabled = true
            reserveButton.isEnabled = false
            shareButton.alpha = 1.0
            downloadAvailableAncestors()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITableViewDataSource Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ancestorSummaries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "AncestorTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AncestorTableViewCell else {
            fatalError("Unable to downcast tableViewCell to AncestorTableViewCell")
        }
        
        let ancestor = ancestorSummaries[indexPath.row]
        
        // Configure Cell Selection Color
        let selectionView = UIView(frame: cell.frame)
        selectionView.backgroundColor = UIColor(red: 252.0/255.0, green: 179.0/255.0, blue: 75.0/255.0, alpha: 1.0)
        
        // Configure Cell Selection Checkmark
        guard let image = UIImage(named: "blueCheckmark.png") else {
            fatalError("PNG not loaded")
        }
        
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 4, y: 26, width: 24, height: 24)
        selectionView.addSubview(imageView)
        
        cell.selectedBackgroundView = selectionView
        
        // Configure Date Formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM YYYY"
        
        cell.ancestorNameLabel.text = ancestor.givenNames + " " + ancestor.surname
        cell.nextOrdinanceLabel.text = ancestor.neededOrdinance.rawValue
        
        // Determine which photo to place based on gender
        if (ancestor.gender == "Male") {
            cell.photoImageView.image = #imageLiteral(resourceName: "Default Male")
            cell.backgroundColor = UIColor(red: 125.0/255.0, green: 126.0/255.0, blue: 232.0/255.0, alpha: 0.25)
        } else {
            cell.photoImageView.image = #imageLiteral(resourceName: "Default Female")
            cell.backgroundColor = UIColor(red: 217.0/255.0, green: 38.0/255.0, blue: 196.0/255.0, alpha: 0.25)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Increment selected ancestor count
        selectedAncestorsCount += 1
        
        // Enable Reserve Button
        reserveButton.isEnabled = true
        reserveButton.alpha = 1.0
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // Decrement selected ancestor count
        selectedAncestorsCount -= 1
        
        // Check to see if we should disable the reserve button
        if (selectedAncestorsCount == 0) {
            reserveButton.isEnabled = false
            reserveButton.alpha = 0.5
        }
    }
    
    // MARK: UIDocumentPickerDelegate Methods
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // Load the PDF
        if let templeCardPdf = PDFDocument(url: urls[0]) {
            templeCard = templeCardPdf
            // Parse the PDF
            //let templeOrdinanceInformation = parsePDF(pdfDocument: templeCardPdf)
//            let pdfLines = parsePDF(pdfDocument: templeCardPdf)
//            let digitRegex = try! NSRegularExpression(pattern: "\\d", options: NSRegularExpression.Options.caseInsensitive)
            
//            print(pdfLines)
//            print(pdfLines[pdfLines.count - 2])
            
            // Populate a new Ancestor Object
            ancestorToShare = Ancestor(templeCardPdf)
            
            uploadFile()
        } else {
            // Throw an error
            fatalError("PDF Document creation failed")
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
    }
    
    //MARK: Actions
    @IBAction func pickFile(_ sender: UIButton) {
        // Deselect selected ancestorTableView cells
        self.deselectTableViewCells()
        reserveButton.isEnabled = false
        
        // Present the Document Picker
        let importPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        
        importPicker.delegate = self
        
        importPicker.modalPresentationStyle = .currentContext
        
        self.present(importPicker, animated: true, completion: nil)
    }
    
    @IBAction func reserveAncestors(_ sender: UIButton) {
        guard let userId = defaults.string(forKey: "User Id") else {
            print("User Id is nil")
            return
        }
        
        guard let selectedAncestorSummaryIndexPath = ancestorTableView.indexPathForSelectedRow else {
            print("There is no selected row")
            return
        }
        
        let selectedAncestorSummary = ancestorSummaries[selectedAncestorSummaryIndexPath.row]
        
        ancestorModel.reserveAncestor(ancestorSummary: selectedAncestorSummary, userId: userId) { (reservedAncestorSummary: AncestorSummary?) in
            guard reservedAncestorSummary != nil else {
                print("There was an error in reserving ancestorSummary: \(selectedAncestorSummary)")
                return
            }
            
            // Set the reserved tab badge to the number of reserved ancestors
            if let tabItems = self.tabBarController?.tabBar.items {
                let reservedTab = tabItems[1]
                
                self.setBadgeNumber(tabBarItem: reservedTab, number: 1)
            }
        }
    }
    
    //MARK: Private methods
    private func downloadAvailableAncestors() {
        print("In DownloadAvailableAncestors")
        // Make an Alamofire request to get the available ancestor data
        Alamofire.request("https://postgres-query-ancestors.herokuapp.com/available").responseJSON { response in
            guard response.result.isSuccess else {
                print("GET request for available ancestors failed: \(String(describing: response.result.error))")
                return
            }
            
            guard let value = response.result.value else {
                print("Data received was not able to be formed correctly")
                return
            }
            
            if let array = value as? [Any] {
                var receivedAncestors = [AncestorSummary]()
                for object in array {
                    let jsonObject = object as? [String: Any]
                    let id = jsonObject!["id"]! as! Int
                    let givenName = jsonObject!["given_name"]! as! String
                    let surname =  jsonObject!["surname"] as! String
                    let gender = jsonObject!["gender"] as! String
                    let neededOrdinance = Ordinance(rawValue: jsonObject!["ordinance_needed"]! as! String)!
                    
                    // Create an Ancestor Object from the parts that we got from the JSON
                    guard let ancestor = AncestorSummary(id: id, givenNames: givenName, surname: surname, gender: gender, neededOrdinance: neededOrdinance) else {
                        fatalError("There was an error in instantiating ancestor with name \(givenName + " " + surname)")
                    }
                    
                    receivedAncestors.append(ancestor)
                }
                
                self.ancestorSummaries = receivedAncestors
                self.ancestorTableView.reloadData()
            }
        }
    }
    
    private func uploadFile() {
        // Make an HTTP request
        let url = URL(string: "https://postgres-query-ancestors.herokuapp.com/share")!
        
        // Make parameters
        var parameters = [String: String]()
        parameters["givenNames"] = ancestorToShare!.givenNames
        parameters["surname"] = ancestorToShare!.surname
        parameters["gender"] = ancestorToShare!.gender
        parameters["ordinanceNeeded"] = ancestorToShare!.neededOrdinance
        parameters["familySearchId"] = ancestorToShare!.familySearchId
        
        // Using Alamofire
        Alamofire.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(self.templeCard!.documentURL!, withName: "templePdf", fileName: "\(self.ancestorToShare!.familySearchId).pdf", mimeType: "application/pdf")
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: .utf8)!, withName: key)
            }
        },
         to: url,
         encodingCompletion: { encodingResult in
            switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseString { response in
                        debugPrint(response)
                                    
                        // Update the available ancestors
                        self.downloadAvailableAncestors()
                    }
                case .failure(let encodingError):
                    print(encodingError)
            }
        })
    }
    
    private func parsePDF(pdfDocument: PDFDocument) -> [String] {
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
    
    /**********************************************
     SET BADGE NUMBER
     Set the badge for a tab bar item to a number
     **********************************************/
    private func setBadgeNumber(tabBarItem: UITabBarItem, number: Int) {
        tabBarItem.badgeValue = String(number)
        tabBarItem.badgeColor = UIColor(red: 252.0/255.0, green: 179.0/255.0, blue: 75.0/255.0, alpha: 1.0)
    }
    
    private func deselectTableViewCells() {
        if let selectedIndexPaths = self.ancestorTableView.indexPathsForSelectedRows {
            for indexPath in selectedIndexPaths {
                self.ancestorTableView.deselectRow(at: indexPath, animated: true)
            }
            
            self.selectedAncestorsCount = 0
            self.reserveButton.isEnabled = false
            self.reserveButton.alpha = 0.5
        }
    }
    
    private func getIdsForSelectedAncestors() -> [Int] {
        if let selectedIndexPaths = self.ancestorTableView.indexPathsForSelectedRows {
            var ids = [Int]()
            for indexPath in selectedIndexPaths {
                // Make an AncestorDTO for the Ancestor at this indexPath
                let retrievedAncestor = ancestorSummaries[indexPath.row]
                ids.append(retrievedAncestor.id)
            }
            return ids
        } else {
            fatalError("Could not retrieve indexPathsForSelectedRows")
        }
    }
}
