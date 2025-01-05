//
//  Word+CoreDataProperties.swift
//  
//
//  Created by Daviti Khvedelidze on 24/09/2024.
//
//

import Foundation
import CoreData


extension Word {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Word> {
        return NSFetchRequest<Word>(entityName: "Word")
    }

    @NSManaged public var baseWord: String?
    @NSManaged public var categoriesData: Data?
    @NSManaged public var last_updated: Date?
    @NSManaged public var wordTranslations: NSSet?

    var categories: [String] {
            get {
                guard let data = categoriesData else { return [] }
                do {
                    return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data) as? [String] ?? []
                } catch {
                    log(.error, "Error unarchiving categories: \(error)")
                    return []
                }
            }
            set {
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)
                    categoriesData = data
                } catch {
                    log(.error, "Error archiving categories: \(error)")
                    categoriesData = nil
                }
            }
        }
}

// MARK: Generated accessors for wordTranslations
extension Word {

    @objc(addWordTranslationsObject:)
    @NSManaged public func addToWordTranslations(_ value: Translation)

    @objc(removeWordTranslationsObject:)
    @NSManaged public func removeFromWordTranslations(_ value: Translation)

    @objc(addWordTranslations:)
    @NSManaged public func addToWordTranslations(_ values: NSSet)

    @objc(removeWordTranslations:)
    @NSManaged public func removeFromWordTranslations(_ values: NSSet)

}
