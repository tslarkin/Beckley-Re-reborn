//
//  Loan+CoreDataProperties.swift
//  Beckley Swift
//
//  Created by Timothy Larkin on 3/25/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//
//

import Foundation
import CoreData


extension Loan {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Loan> {
        return NSFetchRequest<Loan>(entityName: "Loan")
    }

    @NSManaged public var note: String?
    @NSManaged public var checkedIn: NSDate?
    @NSManaged public var borrower: String?
    @NSManaged public var checkedOut: NSDate?
    @NSManaged public var book: Marc?

}
