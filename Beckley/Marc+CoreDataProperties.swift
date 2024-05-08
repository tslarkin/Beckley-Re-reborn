//
//  Marc+CoreDataProperties.swift
//  Beckley Swift
//
//  Created by Timothy Larkin on 3/25/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//
//

import Foundation
import CoreData


extension Marc {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Marc> {
        return NSFetchRequest<Marc>(entityName: "Marc")
    }

    @NSManaged public var leader: String?
    @NSManaged public var author: String?
    @NSManaged public var dcn: String?
    @NSManaged public var title: String?
    @NSManaged public var sortTitle: String?
    @NSManaged public var rendered: NSData?
    @NSManaged public var LCNumber: String?
    @NSManaged public var creators: NSSet?
    @NSManaged public var fields: NSSet?
    @NSManaged public var loans: NSSet?
    @NSManaged public var century: Century?
    @NSManaged public var subjects: NSSet?

}

// MARK: Generated accessors for creators
extension Marc {

    @objc(addCreatorsObject:)
    @NSManaged public func addToCreators(_ value: Creator)

    @objc(removeCreatorsObject:)
    @NSManaged public func removeFromCreators(_ value: Creator)

    @objc(addCreators:)
    @NSManaged public func addToCreators(_ values: NSSet)

    @objc(removeCreators:)
    @NSManaged public func removeFromCreators(_ values: NSSet)

}

// MARK: Generated accessors for fields
extension Marc {

    @objc(addFieldsObject:)
    @NSManaged public func addToFields(_ value: Field)

    @objc(removeFieldsObject:)
    @NSManaged public func removeFromFields(_ value: Field)

    @objc(addFields:)
    @NSManaged public func addToFields(_ values: NSSet)

    @objc(removeFields:)
    @NSManaged public func removeFromFields(_ values: NSSet)

}

// MARK: Generated accessors for loans
extension Marc {

    @objc(addLoansObject:)
    @NSManaged public func addToLoans(_ value: Loan)

    @objc(removeLoansObject:)
    @NSManaged public func removeFromLoans(_ value: Loan)

    @objc(addLoans:)
    @NSManaged public func addToLoans(_ values: NSSet)

    @objc(removeLoans:)
    @NSManaged public func removeFromLoans(_ values: NSSet)

}

// MARK: Generated accessors for subjects
extension Marc {

    @objc(addSubjectsObject:)
    @NSManaged public func addToSubjects(_ value: Subject)

    @objc(removeSubjectsObject:)
    @NSManaged public func removeFromSubjects(_ value: Subject)

    @objc(addSubjects:)
    @NSManaged public func addToSubjects(_ values: NSSet)

    @objc(removeSubjects:)
    @NSManaged public func removeFromSubjects(_ values: NSSet)

}
