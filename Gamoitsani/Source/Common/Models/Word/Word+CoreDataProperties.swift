//
//  Word+CoreDataProperties.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 20/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//
//

import Foundation
import CoreData


extension Word {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Word> {
        return NSFetchRequest<Word>(entityName: "Word")
    }

    @NSManaged public var wordKa: String?
    @NSManaged public var wordEn: String?
    @NSManaged public var categories: [String]?
    @NSManaged public var definitions: [String]?

}

extension Word : Identifiable {

}
