//
//  OutlineView.swift
//  Beckley
//
//  Created by Timothy Larkin on 5/2/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

class OutlineView: NSOutlineView {
	
	override func shouldCollapseAutoExpandedItems(forDeposited deposited: Bool)-> Bool {
		itemsAreExpandable = true
		return false
	}
	
}
