//
//  Subfield+CoreDataProperties.swift
//  Beckley Swift
//
//  Created by Timothy Larkin on 3/25/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//
//

import Foundation
import CoreData


extension Subfield {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Subfield> {
        return NSFetchRequest<Subfield>(entityName: "Subfield")
    }

    @NSManaged public var index: NSNumber?
    @NSManaged public var tag: String?
    @NSManaged public var text: String?
    @NSManaged public var field: Field?

}
