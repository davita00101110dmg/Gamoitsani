//
//  Translation+CoreDataProperties.swift
//  
//
//  Created by Daviti Khvedelidze on 24/09/2024.
//
//

import Foundation
import CoreData


extension Translation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Translation> {
        return NSFetchRequest<Translation>(entityName: "Translation")
    }

    @NSManaged public var difficulty: Int16
    @NSManaged public var languageCode: String?
    @NSManaged public var word: String?
    @NSManaged public var originalWord: Word?

}
