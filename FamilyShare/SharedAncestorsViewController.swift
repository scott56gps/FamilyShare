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

class SharedAncestorsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    //MARK: Properties
    var group = Group()
    var ancestors = [Ancestor]()
    //var selectedAncestorCells = [IndexPath]()
    var selectedAncestorsCount = 0
    @IBOutlet weak var reserveButton: UIButton!
    @IBOutlet weak var ancestorTableView: UITableView!
    @IBOutlet weak var sliderConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ancestorTableView.dataSource = self
        ancestorTableView.delegate = self
        ancestorTableView.separatorColor = UIColor.black
        ancestorTableView.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        
        reserveButton.isEnabled = false
        reserveButton.alpha = 0.5
        
        ancestors = group!.ancestors
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
        cell.reservedDateLabel.text = dateFormatter.string(from: ancestor.reservedDate)
        cell.reservedByNameLabel.text = "Reserved By \(ancestor.sharedBy!.name)"
        cell.nextOrdinanceLabel.text = ancestor.ordinancesAvailable[0].rawValue
        
        // Determine which photo to place based on gender
        if (ancestor.gender == .male) {
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
        
        // Search for the indexPath to remove
//        for index in 0..<selectedAncestorCells.count {
//            if (indexPath.description == selectedAncestorCells[index].description) {
//                // Remove this index path from the array
//                selectedAncestorCells.remove(at: index)
//            }
//        }
        
        // Check to see if we should disable the reserve button
        if (selectedAncestorsCount == 0) {
            reserveButton.isEnabled = false
            reserveButton.alpha = 0.5
        }
    }
    
    //MARK: Actions
    @IBAction func showTempleActionSheet(_ sender: UIButton) {
        // Initialize Alert Controller
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // Make actions for Action Sheet
        let showCodeAction = UIAlertAction(title: "Show Code", style: UIAlertActionStyle.default, handler: {
            (UIAlertAction) -> Void in self.showCodeView()
        })
        
        let printFORAction = UIAlertAction(title: "Print", style: UIAlertActionStyle.default, handler: {
            (UIAlertAction) -> Void in self.printFOR()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(UIAlertAction) -> Void in})
        
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
