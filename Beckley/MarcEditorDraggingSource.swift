//
//  MarcEditorDraggingSource.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/7/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

let MarcPasteboardName = "com.abstracttoolsMarcPasteboardName"

extension NSPasteboard.PasteboardType {
	static let indexPath = NSPasteboard.PasteboardType(MarcPasteboardName)
}

class MarcPasteboardItem {
	let fieldTag: String
	let subfieldTag: String?
	let repeating: Bool
	
	init(fieldTag: String, subfieldTag: String?, repeating: Bool) {
		self.fieldTag = fieldTag
		self.subfieldTag = subfieldTag
		self.repeating = repeating
	}
}

extension MarcEditor {
	
	
	
}
