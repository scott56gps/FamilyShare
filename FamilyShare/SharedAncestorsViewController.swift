//
//  SharedViewController.swift
//  FamilyShareWorkingPrototype
//
//  Created by Nellie Roberts on 6/23/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import UIKit
import CoreGraphics
import PDFKit
import Alamofire

class SharedAncestorsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate {
    
    //MARK: Properties
    let ancestorModel = AncestorModel()
    var sharedAncestors = [Ancestor]()
    let defaults = UserDefaults.standard
    
    // MARK: Outlets
    @IBOutlet weak var reserveButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var ancestorTableView: UITableView!
    @IBOutlet weak var sliderConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
        activityIndicator.hidesWhenStopped = true;
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
            sharedAncestors.removeAll()
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
        return sharedAncestors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "AncestorTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AncestorTableViewCell else {
            fatalError("Unable to downcast tableViewCell to AncestorTableViewCell")
        }
        
        let ancestor = sharedAncestors[indexPath.row]
        
        // Configure Cell Selection Color
        let selectionView = UIView(frame: cell.frame)
        selectionView.backgroundColor = UIColor(red: 252.0/255.0, green: 179.0/255.0, blue: 75.0/255.0, alpha: 1.0)
        
        // Configure Cell Selection Checkmark
        let blueCheckmark = #imageLiteral(resourceName: "Blue Checkmark")
        
        let imageView = UIImageView(image: blueCheckmark)
        imageView.frame = CGRect(x: 4, y: 26, width: 24, height: 24)
        selectionView.addSubview(imageView)
        
        cell.selectedBackgroundView = selectionView
        
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
        // Enable Reserve Button
        enableReserveButton()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // Check to see if we should disable the reserve button
        ancestorTableView.indexPathsForSelectedRows?.count == 0 ? disableReserveButton() : enableReserveButton()
    }
    
    // MARK: UIDocumentPickerDelegate Methods
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        activityIndicator.startAnimating()
        
        // Load the PDF
        if let templeCardPdf = PDFDocument(url: urls[0]) {
            // Populate a new Ancestor Object
            let ancestorToShare = Ancestor(templeCardPdf)
            ancestorModel.postAncestor(templeCard: templeCardPdf, ancestor: ancestorToShare) { [unowned self] (error: String?, postedAncestor: Ancestor?) in
                self.activityIndicator.stopAnimating()
                
                if (error != nil) {
                    debugPrint(error!)
                    return
                }
                
                if let ancestor = postedAncestor {
                    self.sharedAncestors.append(ancestor)
                    self.ancestorTableView.reloadData()
                }
            }
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
        
        guard let selectedAncestorIndexPath = ancestorTableView.indexPathForSelectedRow else {
            print("There is no selected row")
            return
        }
        
        let selectedAncestor = sharedAncestors[selectedAncestorIndexPath.row]
        
        activityIndicator.startAnimating()
        
        ancestorModel.reserveAncestor(ancestor: selectedAncestor, userId: userId) { [unowned self] (reservedAncestor: Ancestor?) in
            self.activityIndicator.stopAnimating()
            guard reservedAncestor != nil else {
                print("There was an error in reserving ancestorSummary: \(selectedAncestor)")
                return
            }
            
            self.deselectTableViewCells()
            
            // Remove the reservedAncestor from the ancestorSummaries
            self.sharedAncestors.remove(at: selectedAncestorIndexPath.row)
            self.ancestorTableView.reloadData()
            
            // Set the reserved tab badge to the number of reserved ancestors
            if let tabItems = self.tabBarController?.tabBar.items {
                let reservedTab = tabItems[1]

                self.setBadgeNumber(tabBarItem: reservedTab, number: 1)
            }
        }
    }
    
    //MARK: Private methods
    private func downloadAvailableAncestors() {
        activityIndicator.startAnimating()
        ancestorModel.getAvailableAncestorSummaries() { [unowned self] (error: Error?, availableAncestors: [Ancestor]?) in
            self.activityIndicator.stopAnimating()
            
            guard error == nil else {
                print(error as Any)
                return
            }
            
            if let availableAncestors = availableAncestors {
                self.sharedAncestors = availableAncestors
                self.ancestorTableView.reloadData()
            } else {
                // There was an error in initializing an array of type Ancestor
                print("There was an error in initializing an array of type Ancestor")
                return
            }
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
            
            disableReserveButton()
        }
    }
    
    private func getIdsForSelectedAncestors() -> [Int] {
        if let selectedIndexPaths = self.ancestorTableView.indexPathsForSelectedRows {
            var ids = [Int]()
            for indexPath in selectedIndexPaths {
                // Get the id for this ancestor
                let retrievedAncestor = sharedAncestors[indexPath.row]
                if let id = retrievedAncestor.id {
                    ids.append(id)
                }
            }
            return ids
        } else {
            fatalError("Could not retrieve indexPathsForSelectedRows")
        }
    }
    
    private func enableReserveButton() {
        reserveButton.isEnabled = true
        reserveButton.alpha = 1.0
    }
    
    private func disableReserveButton() {
        reserveButton.isEnabled = false
        reserveButton.alpha = 0.5
    }
}
