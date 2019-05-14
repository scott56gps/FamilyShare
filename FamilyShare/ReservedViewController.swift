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

class ReservedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    //MARK: Properties
    let ancestorModel = AncestorModel()
    var ancestors = [Ancestor]()
    var defaults = UserDefaults.standard
    var userId: Int?
    var selectedAncestorsCount = 0
    
    //MARK: Outlets
    @IBOutlet weak var ancestorTableView: UITableView!
    @IBOutlet weak var printButton: UIButton!
    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ancestorTableView.dataSource = self
        ancestorTableView.delegate = self
        ancestorTableView.separatorColor = UIColor.black
        ancestorTableView.separatorInset = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        
        printButton.isEnabled = false
        printButton.alpha = 0.5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        // Only download the reserved ancestors if the user is signed in
        let defaultUserId = defaults.integer(forKey: "User Id")
        if defaultUserId == 0 {
            print("User Id nil.  User not signed in")
            infoLabel.isHidden = false
            
            ancestors.removeAll()
            ancestorTableView.reloadData()
        } else {
            self.userId = defaultUserId
            infoLabel.isHidden = true
            downloadReservedAncestors()
        }
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
        
        // Configure Cell Selection Color
        let selectionView = UIView(frame: cell.frame)
        selectionView.backgroundColor = UIColor(red: 252.0/255.0, green: 179.0/255.0, blue: 75.0/255.0, alpha: 1.0)
        
        // Configure Cell Selection Checkmark        
        let blueCheckmark = #imageLiteral(resourceName: "Blue Checkmark")
        
        let imageView = UIImageView(image: blueCheckmark)
        imageView.frame = CGRect(x: 4, y: 26, width: 24, height: 24)
        selectionView.addSubview(imageView)
        
        cell.selectedBackgroundView = selectionView
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Increment selected ancestor count
        selectedAncestorsCount += 1
        
        // Enable Print Button
        printButton.isEnabled = true
        printButton.alpha = 1.0
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // Decrement selected ancestor count
        selectedAncestorsCount -= 1
        
        // Check to see if we should disable the reserve button
        if (selectedAncestorsCount == 0) {
            printButton.isEnabled = false
            printButton.alpha = 0.5
        }
    }

    
    //MARK: Actions
    @IBAction func showTempleActionSheet(_ sender: UIButton) {
        guard defaults.string(forKey: "User Id") != nil else {
            debugPrint("User Id is nil")
            return
        }
        
        guard let selectedAncestor = getSelectedAncestor() else {
            debugPrint("Expected a selected Ancestor, but there was none found")
            return
        }
        
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
            self.ancestorModel.getTempleCardForAncestor(ancestor: selectedAncestor) { [unowned self] (error: String?, templeCard: PDFDocument?) in
                guard error == nil else {
                    debugPrint(error!)
                    return
                }
                
                if let templeCard = templeCard {
                    self.printTempleCard(templeCard: templeCard, selectedAncestor: selectedAncestor)
                } else {
                    debugPrint("Expected PDFDocument, but instead found nil")
                }
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler:{(UIAlertAction) -> Void in
            self.deselectTableViewCells()
            self.downloadReservedAncestors()
        })
        
        //alertController.addAction(showCodeAction)
        alertController.addAction(printFORAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
    }

    
    //MARK: Private Functions
    private func downloadReservedAncestors() {
        ancestorModel.getReservedAncestorSummaries(forUserId: userId!) { [unowned self] (error: Error?, reservedAncestors: [Ancestor]?) in
            guard error == nil else {
                debugPrint(error!)
                return
            }
            
            if let reservedAncestors = reservedAncestors {
                self.ancestors = reservedAncestors
                self.ancestorTableView.reloadData()
            } else {
                // There was an error in initializing an array of type Ancestor
                debugPrint("There was an error in initializing an array of type Ancestor")
                return
            }
        }
    }
    
    private func printTempleCard(templeCard: PDFDocument, selectedAncestor: Ancestor) {
        // Configure the controller
        let printController = UIPrintInteractionController.shared
        if let pdfUrl = templeCard.documentURL {
            printController.printingItem = pdfUrl
            
            // Make Print Info Object
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.jobName = selectedAncestor.givenNames + " " + selectedAncestor.surname
            printInfo.outputType = .grayscale
            
            printController.printInfo = printInfo
            
            printController.present(animated: true) { [unowned self] theHandler, didComplete, errorOptional in
                // Delete the pdf that was downloaded
                let fileManager = FileManager.default
                do {
                    try fileManager.removeItem(at: pdfUrl)
                    self.deselectTableViewCells()
                } catch {
                    print("Error in deleting pdf")
                    self.deselectTableViewCells()
                }
            }
        } else {
            print("PDF Url could not be loaded")
        }
    }
    
    private func deselectTableViewCells() {
        if let selectedIndexPaths = ancestorTableView.indexPathsForSelectedRows {
            for indexPath in selectedIndexPaths {
                ancestorTableView.deselectRow(at: indexPath, animated: true)
            }
            
            selectedAncestorsCount = 0
            printButton.isEnabled = false
            printButton.alpha = 0.5
        }
    }
    
    private func getSelectedAncestor() -> Ancestor? {
        if let selectedIndexPath = ancestorTableView.indexPathForSelectedRow {
            return ancestors[selectedIndexPath.row]
        } else {
            return nil
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
