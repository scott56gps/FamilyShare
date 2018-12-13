//
//  AncestorTableViewCell.swift
//  FamilyShareWorkingPrototype
//
//  Created by Nellie Roberts on 6/6/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import UIKit

class AncestorTableViewCell: UITableViewCell {
    // MARK: Properties
    @IBOutlet weak var ancestorNameLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var nextOrdinanceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
