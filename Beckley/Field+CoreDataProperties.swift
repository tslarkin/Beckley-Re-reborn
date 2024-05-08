//
//  Field+CoreDataProperties.swift
//  Beckley Swift
//
//  Created by Timothy Larkin on 3/25/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//
//

import Foundation
import CoreData


extension Field {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Field> {
        return NSFetchRequest<Field>(entityName: "Field")
    }

    @NSManaged public var tag: String?
    @NSManaged public var marc: Marc?
    @NSManaged public var subfields: NSSet?

}

// MARK: Generated accessors for subfields
extension Field {

    @objc(addSubfieldsObject:)
    @NSManaged public func addToSubfields(_ value: Subfield)

    @objc(removeSubfieldsObject:)
    @NSManaged public func removeFromSubfields(_ value: Subfield)

    @objc(addSubfields:)
    @NSManaged public func addToSubfields(_ values: NSSet)

    @objc(removeSubfields:)
    @NSManaged public func removeFromSubfields(_ values: NSSet)

}
