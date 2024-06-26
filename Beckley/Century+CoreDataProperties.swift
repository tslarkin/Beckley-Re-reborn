//
//  Century+CoreDataProperties.swift
//  Beckley Swift
//
//  Created by Timothy Larkin on 3/25/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//
//

import Foundation
import CoreData


extension Century {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Century> {
        return NSFetchRequest<Century>(entityName: "Century")
    }

    @NSManaged public var marcs: NSSet?
    @NSManaged public var subjects: NSSet?

}

// MARK: Generated accessors for marcs
extension Century {

    @objc(addMarcsObject:)
    @NSManaged public func addToMarcs(_ value: Marc)

    @objc(removeMarcsObject:)
    @NSManaged public func removeFromMarcs(_ value: Marc)

    @objc(addMarcs:)
    @NSManaged public func addToMarcs(_ values: NSSet)

    @objc(removeMarcs:)
    @NSManaged public func removeFromMarcs(_ values: NSSet)

}

// MARK: Generated accessors for subjects
extension Century {

    @objc(addSubjectsObject:)
    @NSManaged public func addToSubjects(_ value: Subject)

    @objc(removeSubjectsObject:)
    @NSManaged public func removeFromSubjects(_ value: Subject)

    @objc(addSubjects:)
    @NSManaged public func addToSubjects(_ values: NSSet)

    @objc(removeSubjects:)
    @NSManaged public func removeFromSubjects(_ values: NSSet)

}
