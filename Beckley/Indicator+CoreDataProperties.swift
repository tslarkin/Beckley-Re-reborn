//
//  Indicator+CoreDataProperties.swift
//  Beckley Swift
//
//  Created by Timothy Larkin on 3/25/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//
//

import Foundation
import CoreData


extension Indicator {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Indicator> {
        return NSFetchRequest<Indicator>(entityName: "Indicator")
    }


}
