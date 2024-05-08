//
//  Subject+CoreDataProperties.swift
//  Beckley Swift
//
//  Created by Timothy Larkin on 3/25/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//
//

import Foundation
import CoreData


extension Subject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Subject> {
        return NSFetchRequest<Subject>(entityName: "Subject")
    }

    @NSManaged public var centuries: NSSet?
    @NSManaged public var marcs: NSSet?
    @NSManaged public var creators: NSSet?

}

// MARK: Generated accessors for centuries
extension Subject {

    @objc(addCenturiesObject:)
    @NSManaged public func addToCenturies(_ value: Century)

    @objc(removeCenturiesObject:)
    @NSManaged public func removeFromCenturies(_ value: Century)

    @objc(addCenturies:)
    @NSManaged public func addToCenturies(_ values: NSSet)

    @objc(removeCenturies:)
    @NSManaged public func removeFromCenturies(_ values: NSSet)

}

// MARK: Generated accessors for marcs
extension Subject {

    @objc(addMarcsObject:)
    @NSManaged public func addToMarcs(_ value: Marc)

    @objc(removeMarcsObject:)
    @NSManaged public func removeFromMarcs(_ value: Marc)

    @objc(addMarcs:)
    @NSManaged public func addToMarcs(_ values: NSSet)

    @objc(removeMarcs:)
    @NSManaged public func removeFromMarcs(_ values: NSSet)

}

// MARK: Generated accessors for creators
extension Subject {

    @objc(addCreatorsObject:)
    @NSManaged public func addToCreators(_ value: Creator)

    @objc(removeCreatorsObject:)
    @NSManaged public func removeFromCreators(_ value: Creator)

    @objc(addCreators:)
    @NSManaged public func addToCreators(_ values: NSSet)

    @objc(removeCreators:)
    @NSManaged public func removeFromCreators(_ values: NSSet)

}
