//
//  Member.swift
//  FamilyShareWorkingPrototype
//
//  Created by Scott Nicholes on 7/6/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import Foundation

class Member {
    var name: String
    var gender: Gender
    
    init(name: String, gender: Gender) {
        self.name = name
        self.gender = gender
    }
}
