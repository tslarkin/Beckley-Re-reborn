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
	static let marcPasteboardItem = NSPasteboard.PasteboardType(MarcPasteboardName)
}

class MarcPasteboardItem: NSObject, NSPasteboardWriting, NSPasteboardReading, NSSecureCoding {
	static var supportsSecureCoding: Bool = true
	
	
	func encode(with coder: NSCoder) {
		coder.encode(fieldTag, forKey: "FieldTag")
		coder.encode(subfieldTag, forKey: "SubfieldTag")
		coder.encode(NSNumber(value: repeating), forKey: "Repeating")
	}
	
	required init?(coder decoder: NSCoder) {
		fieldTag = decoder.decodeObject(forKey: "FieldTag") as! String
		subfieldTag = decoder.decodeObject(forKey: "SubfieldTag") as! String
		let thing = decoder.decodeObject(forKey: "Repeating") as! NSNumber
		repeating = thing.boolValue
		fieldOnly = subfieldTag == ""
	}
	
	
	static func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
		return [NSPasteboard.PasteboardType.marcPasteboardItem]
	}
	
	static func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions {
		return .asKeyedArchive
	}
	
	required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
		let data = propertyList as! Data
		let properties = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! Array<Any>
		fieldTag = properties[0] as! String
		subfieldTag = properties[1] as! String
		repeating = properties[2] as! Bool
		fieldOnly = subfieldTag == ""
		super.init()
	}
	
	func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
		return [NSPasteboard.PasteboardType.marcPasteboardItem]
	}
	
	func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
		guard type == .marcPasteboardItem else { return nil }
		let data = try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
		return data
	}
	
	let fieldTag: String
	let subfieldTag: String
	let repeating: Bool
	let fieldOnly: Bool
	
	init(fieldTag: String, subfieldTag: String, repeating: Bool) {
		self.fieldTag = fieldTag
		self.subfieldTag = subfieldTag
		self.repeating = repeating
		fieldOnly = subfieldTag == ""
	}
	
}

extension ReferenceDataSource {
	
	func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
		var dragData: Array<MarcPasteboardItem> = []
		if tableView == subfieldTableView {
			let fieldIndex = fieldTableView.selectedRow
			let fieldEntry = filteredFields[fieldIndex]
			for index in rowIndexes {
				let subfield = fieldEntry.subfields[index]
				dragData.append(MarcPasteboardItem(fieldTag: fieldEntry.field.tag, subfieldTag: subfield.tag, repeating: subfield.repeating))
			}
		} else { return false }
		pboard.writeObjects(dragData)
		return true
	}	
}
