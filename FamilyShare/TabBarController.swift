//
//  TabBarController.swift
//  FamilyShareWorkingPrototype
//
//  Created by Nellie Roberts on 6/29/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if (selectedIndex == 1) {
            if let tabBarItems = self.tabBar.items {
                let reservedTab = tabBarItems[1]
                reservedTab.badgeValue = nil
            }
        }
    }

}
