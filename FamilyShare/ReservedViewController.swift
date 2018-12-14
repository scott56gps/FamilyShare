//
//  ReservedViewController.swift
//  FamilyShareWorkingPrototype
//
//  Created by Nellie Roberts on 6/27/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import UIKit
import PDFKit
import Alamofire

class ReservedViewController: UIViewController, UITableViewDataSource {
    var ancestors = [Ancestor]()
    var templeCard: PDFDocument?
    
    var defaults = UserDefaults.standard
    var selectedAncestorsCount = 0
    
    //MARK: Outlets
    @IBOutlet weak var ancestorTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ancestorTableView.dataSource = self
        ancestorTableView.separatorColor = UIColor.black
        ancestorTableView.separatorInset = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        
        //loadSampleReservedAncestors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        downloadReservedAncestors()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK - UITableViewDataSource
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
        
        // Configure Date Formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM YYYY"
        
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
    
    //MARK: Actions
    func showTempleActionSheet(familySearchId: String) {
        print("I AM IN showTempleActionsSheet!")
        // Initialize Alert Controller
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        // Make actions for Action Sheet
//        let showCodeAction = UIAlertAction(title: "Show Code", style: UIAlertAction.Style.default, handler: {
//            (UIAlertAction) -> Void in
//            print("I am about to showCodeAction")
//            self.downloadTempleCard(familySearchId: familySearchId)
//        })
        
        let printFORAction = UIAlertAction(title: "Print", style: UIAlertAction.Style.default, handler: {
            (UIAlertAction) -> Void in
            self.printFOR()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler:{(UIAlertAction) -> Void in
            self.deselectTableViewCells()
            self.downloadReservedAncestors()
        })
        
        alertController.addAction(showCodeAction)
        alertController.addAction(printFORAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
    }

    
    //MARK: Private Functions
    private func downloadReservedAncestors() {
        if let userId = defaults.string(forKey: "User Id") {
            // Make an Alamofire request to get the available ancestor data
            Alamofire.request("https://postgres-query-ancestors.herokuapp.com/reserved/\(userId)").responseJSON { response in
                guard response.result.isSuccess else {
                    print("GET request for reserved ancestors failed: \(String(describing: response.result.error))")
                    return
                }
                
                guard let value = response.result.value else {
                    print("Data received was not able to be formed correctly")
                    return
                }
                
                if let array = value as? [Any] {
                    var receivedAncestors = [Ancestor]()
                    for object in array {
                        let jsonObject = object as? [String: Any]
                        let id = jsonObject!["id"]! as! Int
                        let givenName = jsonObject!["given_name"]! as! String
                        let surname =  jsonObject!["surname"] as! String
                        let gender = jsonObject!["gender"] as! String
                        let neededOrdinance = Ordinance(rawValue: jsonObject!["ordinance_needed"]! as! String)!
                        
                        // Create an Ancestor Object from the parts that we got from the JSON
                        guard let ancestor = Ancestor(id: id, givenNames: givenName, surname: surname, gender: gender, neededOrdinance: neededOrdinance) else {
                            fatalError("There was an error in instantiating ancestor with name \(givenName + " " + surname)")
                        }
                        
                        receivedAncestors.append(ancestor)
                    }
                    
                    self.ancestors = receivedAncestors
                    self.ancestorTableView.reloadData()
                }
            }
        } else {
            print("User Id nil.  User not signed in")
        }
    }
    
    private func downloadTempleCard(familySearchId: String) {
        if let userId = defaults.string(forKey: "User Id") {
            // Set the parameters for the GET request
            let url = "https://postgres-query-ancestors.herokuapp.com/templeCard/" + userId + "/" + familySearchId
            
            // Create a place to put the PDF once downloaded
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsURL.appendingPathComponent("\(familySearchId).pdf")
                
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }
            
            // Make an Alamofire GET request to get the temple card for this ancestorId
            Alamofire.download(url, to: destination).response { response in
                if response.error == nil, let fileURL = response.destinationURL {
                    print ("PDF Downloaded!")
                    
                    if let pdf = PDFDocument(url: fileURL) {
                        print(pdf.string!)
                        
                        self.templeCard = pdf
                    }
                } else {
                    fatalError("PDF was not downloaded correctly")
                }
            }
        } else {
            fatalError("User Id was not found")
        }
    }
    
    private func printFOR() {
        // Get the FOR request
        
        
        // Configure the controller
        let printController = UIPrintInteractionController.shared
        printController.printingItem = forRequest
        
        // Make Print Info Object
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "FOR Request"
        
        printController.printInfo = printInfo
        
        printController.present(animated: true, completionHandler: { theHandler, didComplete, errorOptional in
            self.deselectTableViewCells()
        })
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
    
//    func showCodeView() {
//        UIView.animate(withDuration: 0.5, animations: {
//            self.sliderConstraint.constant = 0
//            self.tabBarController?.tabBar.isHidden = true
//        })
//    }
//
//    func hideCodeView(_ sender: UITapGestureRecognizer) {
//        UIView.animate(withDuration: 0.5, animations: {
//            self.sliderConstraint.constant = -400
//            self.tabBarController?.tabBar.isHidden = false
//
//            // Deselect the table view cells
//            self.deselectTableViewCells()
//        })
//    }

}
