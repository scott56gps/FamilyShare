//
//  Group.swift
//  FamilyShareWorkingPrototype
//
//  Created by Scott Nicholes on 7/6/18.
//  Copyright © 2018 Scott Nicholes. All rights reserved.
//

import Foundation

class Group {
    var name = "Sintay Family Group"
    var members: [Member]
    var ancestors: [Ancestor]
    
    init?() {
        // Make Group Members
        let groupMembers = [Member(name: "Shaun Brown", gender: Gender.female), Member(name: "Susan Sintay", gender: Gender.female), Member(name: "Scott Nicholes", gender: Gender.male)]
        self.members = groupMembers
        
        // Make Group Ancestors
        // Make Date Logic
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let mayDate = dateFormatter.date(from: "2018/05/31")
        let juneDate = dateFormatter.date(from: "2018/06/2")
        let augustDate = dateFormatter.date(from: "2017/08/09")
        
        // Make Ancestors
        let ancestor1 = Ancestor(name: "Josiah Nicholes", gender: Gender.male, ordinancesAvailable: [.baptism], reservedDate: mayDate!, sharedBy: groupMembers[0])
        
        let ancestor2 = Ancestor(name: "Bandy Sintay", gender: .male, ordinancesAvailable: [.initiatory], reservedDate: juneDate!, sharedBy: groupMembers[0])
        
        let ancestor3 = Ancestor(name: "Evangelina De Luna", gender: .female, ordinancesAvailable: [.endowment], reservedDate: juneDate!, sharedBy: groupMembers[1])
        
        let ancestor4 = Ancestor(name: "Victor Robles", gender: .male, ordinancesAvailable: [.initiatory], reservedDate: juneDate!, sharedBy: groupMembers[2])
        
        let ancestor5 = Ancestor(name: "Nellie Swauger", gender: .female, ordinancesAvailable: [.baptism], reservedDate: augustDate!, sharedBy: groupMembers[1])
        
        self.ancestors = [ancestor1, ancestor2, ancestor3, ancestor4, ancestor5]
    }
}
