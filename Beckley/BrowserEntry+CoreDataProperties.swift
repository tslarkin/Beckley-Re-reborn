//
//  BrowserEntry+CoreDataProperties.swift
//  Beckley
//
//  Created by Timothy Larkin on 3/25/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//
//

import Foundation
import CoreData


extension BrowserEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BrowserEntry> {
        return NSFetchRequest<BrowserEntry>(entityName: "BrowserEntry")
    }

    @NSManaged public var key: String?

}
