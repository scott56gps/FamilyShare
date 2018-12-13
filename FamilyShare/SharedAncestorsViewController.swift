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
    var ancestors = [Ancestor]()
    var ancestorToShare: AncestorDTO?
    var templeCard: PDFDocument?
    var selectedAncestorsCount = 0
    
    // MARK: Outlets
    @IBOutlet weak var reserveButton: UIButton!
    @IBOutlet weak var ancestorTableView: UITableView!
    @IBOutlet weak var sliderConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ancestorTableView.dataSource = self
        ancestorTableView.delegate = self
        ancestorTableView.separatorColor = UIColor.black
        ancestorTableView.separatorInset = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        
        reserveButton.isEnabled = false
        reserveButton.alpha = 0.5
        
        //loadSampleSharedAncestors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        downloadAvailableAncestors()
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
        return ancestors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "AncestorTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AncestorTableViewCell else {
            fatalError("Unable to downcast tableViewCell to AncestorTableViewCell")
        }
        
        let ancestor = ancestors[indexPath.row]
        
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
        
        cell.ancestorNameLabel.text = ancestor.name
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
        
        // Add the IndexPath onto the selectedArray
        //selectedAncestorCells.append(indexPath)
        
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
            let pdfLines = parsePDF(pdfDocument: templeCardPdf)
            let digitRegex = try! NSRegularExpression(pattern: "\\d", options: NSRegularExpression.Options.caseInsensitive)
            
            print(pdfLines)
            print(pdfLines[pdfLines.count - 2])
            
            // Populate a new Ancestor Object
            ancestorToShare = AncestorDTO(pdfLines, digitRegex: digitRegex)
            
            print(ancestorToShare!.givenNames)
            print(ancestorToShare!.surname)
            print(ancestorToShare!.neededOrdinance)
            print(ancestorToShare!.gender)
            print(ancestorToShare!.familySearchId)
        } else {
            // Throw an error
            fatalError("PDF Document creation failed")
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
    }
    
    //MARK: Actions
    @IBAction func pickFile(_ sender: UIButton) {
        print("BUTTON PRESSED")
        // Present the Document Picker
        let importPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        
        importPicker.delegate = self
        
        importPicker.modalPresentationStyle = .currentContext
        
        self.present(importPicker, animated: true, completion: nil)
    }
    
    @IBAction func showTempleActionSheet(_ sender: UIButton) {
        // Initialize Alert Controller
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        // Make actions for Action Sheet
        let showCodeAction = UIAlertAction(title: "Show Code", style: UIAlertAction.Style.default, handler: {
            (UIAlertAction) -> Void in self.showCodeView()
        })
        
        let printFORAction = UIAlertAction(title: "Print", style: UIAlertAction.Style.default, handler: {
            (UIAlertAction) -> Void in self.printFOR()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: {(UIAlertAction) -> Void in})
        
        alertController.addAction(showCodeAction)
        alertController.addAction(printFORAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
    }
    
    func showCodeView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.sliderConstraint.constant = 0
            self.tabBarController?.tabBar.isHidden = true
        })
    }
    
    @IBAction func hideCodeView(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.5, animations: {
            self.sliderConstraint.constant = -400
            self.tabBarController?.tabBar.isHidden = false
            
            // Set the reserved tab badge to the number of items selected
            self.setBadge()
            
            // Deselect the table view cells
            self.deselectTableViewCells()
        })
    }
    
    func printFOR() {
        // Get the FOR request
        let forRequest = makeFORRequest()
        
        // Configure the controller
        let printController = UIPrintInteractionController.shared
        printController.printingItem = forRequest
        
        // Make Print Info Object
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "FOR Request"
        
        printController.printInfo = printInfo
        
        printController.present(animated: true, completionHandler: { theHandler, didComplete, errorOptional in
            self.setBadge()
            self.deselectTableViewCells()
        })
    }
    
    
    //MARK: Private methods
    private func downloadAvailableAncestors() {
        // Make an Alamofire request to get the available ancestor data
        Alamofire.request("https://postgres-query-ancestors.herokuapp.com/available").responseJSON { response in
            guard response.result.isSuccess else {
                print("GET request for available ancestors failed: \(String(describing: response.result.error))")
                return
            }
            
            //print("response.result.value: \(String(describing: response.result.value!))")
            
            guard let value = response.result.value else {
                print("Data received was not able to be formed correctly")
                return
            }
            
            //let rows = value["rows"] as? [[String: Any]]
            if let array = value as? [Any] {
                var receivedAncestors = [Ancestor]()
                for object in array {
                    let jsonArray = object as? [String: Any]
                    let givenName = jsonArray!["given_name"]! as! String
                    let surname =  jsonArray!["surname"] as! String
                    let gender = jsonArray!["gender"] as! String
                    let fullName = givenName + " " + surname
                    let neededOrdinance = Ordinance(rawValue: jsonArray!["ordinance_needed"]! as! String)!
                    
                    // Create an Ancestor Object from the parts that we got from the JSON
                    guard let ancestor = Ancestor(name: fullName, gender: gender, neededOrdinance: neededOrdinance) else {
                        fatalError("There was an error in instantiating ancestor with name \(fullName)")
                    }
                    
                    receivedAncestors.append(ancestor)
                }
                
                self.ancestors = receivedAncestors
                self.ancestorTableView.reloadData()
            }
        }
    }
    
    private func uploadFile(_ sender: UIButton) {
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

    
    private func loadSampleSharedAncestors() {
        let ancestor1 = Ancestor(name: "Juan De Luna", gender: "Male", neededOrdinance: .baptism)!
        let ancestor2 = Ancestor(name: "Zsuzanna Zsik", gender: "Female", neededOrdinance: .endowment)!
        
        ancestors = [ancestor1, ancestor2]
    }
    
    private func setBadge() {
        if let tabItems = self.tabBarController?.tabBar.items {
            let reservedTab = tabItems[1]
            reservedTab.badgeValue = String(self.selectedAncestorsCount)
            reservedTab.badgeColor = UIColor(red: 252.0/255.0, green: 179.0/255.0, blue: 75.0/255.0, alpha: 1.0)
        }
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
    
    private func makeFORRequest() -> PDFDocument {
        // For right now, we will simply load the URL for the example PDF I included.
        guard let url = Bundle.main.url(forResource: "exampleFOR", withExtension: "pdf") else {
            fatalError("Could not find PDF path")
        }
        
        guard let forRequest = PDFDocument(url: url) else {
            fatalError("Did not convert URL into PDFDocument")
        }
        
        return forRequest
    }

}
