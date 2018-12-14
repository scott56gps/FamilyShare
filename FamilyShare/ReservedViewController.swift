//
//  ReservedViewController.swift
//  FamilyShareWorkingPrototype
//
//  Created by Nellie Roberts on 6/27/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import UIKit
import Alamofire

class ReservedViewController: UIViewController, UITableViewDataSource {
    var ancestors = [Ancestor]()
    var defaults = UserDefaults.standard
    
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
    
    private func loadSampleReservedAncestors() {
        guard let ancestor1 = Ancestor(id: 1, givenNames: "Hector", surname: "Lopez", gender: "Male", neededOrdinance: .initiatory) else {
            fatalError("Error in instatiating Hector Lopez")
        }
        guard let ancestor2 = Ancestor(id: 1, givenNames: "Evangelina", surname: "De Luna", gender: "Female", neededOrdinance: .baptism) else {
            fatalError("Error in instatiating Evangelina De Luna")
        }
        
        ancestors = [ancestor1, ancestor2]
    }
}
