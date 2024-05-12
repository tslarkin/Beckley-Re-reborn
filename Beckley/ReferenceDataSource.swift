//
//  ReferenceDataSource.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/7/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

class ReferenceDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
	
	@IBOutlet weak var fieldTableView: NSTableView!
	@IBOutlet weak var subfieldTableView: NSTableView!
	@IBOutlet weak var reference: MarcReference!
	

	struct Entry {
		var field: MarcReference.FieldRef
		var subfields: Array<MarcReference.SubfieldRef>
	}
	var sortedFields: Array<Entry>!
	var filteredFields: Array<Entry> = []

	override func awakeFromNib() {
		sortedFields = reference.fieldDictionary.values.map{ Entry(field: $0,
																   subfields: $0.subfields.values.sorted(by: { $0.tag < $1.tag })) }
			.sorted(by: { $0.field.tag < $1.field.tag })
		filteredFields = sortedFields
	}

	func numberOfRows(in tableView: NSTableView) -> Int {
		switch tableView.tag {
		case 0:
			return filteredFields.count
		case 1:
			let selectedFieldRow = fieldTableView.selectedRow
			if selectedFieldRow >= 0 {
				return filteredFields[selectedFieldRow].subfields.count
			}
			fallthrough
		default:
			return 0
		}
	}
	
	@IBAction func search(_ sender: NSSearchField) {
		if sender.stringValue.count == 0 {
			filteredFields = sortedFields
		} else {
			filteredFields = sortedFields.filter({ entry in entry.field.description.contains(sender.stringValue)
                || entry.field.tag.starts(with: (sender.stringValue))
            })
		}
		fieldTableView.reloadData()
		subfieldTableView.reloadData()
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		switch tableView.tag {
		case 0:
			switch tableColumn?.identifier.rawValue {
			case "TagColumn":
				let tag = filteredFields[row].field.tag
				let repeating = reference.fieldRepeats(for: tag)
				return repeating ? "+" + tag : tag
			case "DescriptionColumn":
				return filteredFields[row].field.description
			default:
				return nil
			}
		case 1:
			let selectedFieldRow = fieldTableView.selectedRow
			if selectedFieldRow >= 0 {
				let entry = filteredFields[selectedFieldRow].subfields[row]
				switch tableColumn?.identifier.rawValue {
				case "TagColumn":
					let tag = entry.tag
					let fieldTag = filteredFields[selectedFieldRow].field.tag
					let repeating = reference.subfieldRepeats(for: tag, of: fieldTag)
					return repeating ? "+" + tag : tag
				case "DescriptionColumn":
					return entry.description
				default:
					return nil
				}
			}
			fallthrough
		default:
			return nil
		}
	}
	
	func tableViewSelectionDidChange(_ notification: Notification) {
		switch (notification.object as! NSTableView).tag {
		case 0:
			subfieldTableView.reloadData()
			subfieldTableView.needsDisplay = true
		default:
			()
		}
	}
}
