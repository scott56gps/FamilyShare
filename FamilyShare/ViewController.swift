//
//  ViewController.swift
//  FamilyShareWorkingPrototype
//
//  Created by Nellie Roberts on 6/6/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var moveAmount:CGFloat = 500.0
    @IBOutlet weak var sliderLeftConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        moveAmount = self.view.frame.width
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    

}

