//
//  OutlineDataSource.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/10/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

extension MarcEditor {
	// MARK: Outline Data Source
	
	func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
		return itemsAreExpandable
	}
	
	// This is less complicated than it looks.
	// First, determine the type of item, then switch on the column.
	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		var view: NSTableCellView? = nil
		
		if let fieldItem = item as? Field {
			// This is a Field item
			
			let fieldTag = fieldItem.tag!
			switch tableColumn?.identifier.rawValue {
			case "TagColumn":
				view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FieldTag"),
											owner: self) as? NSTableCellView
				view?.textField?.stringValue = fieldTag
			case "DescriptionColumn":
				view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Description"),
											owner: self) as? NSTableCellView
				view?.textField?.stringValue = reference.fieldDescription(for: fieldTag)
			default:
				return nil
			}
			
		} else if let indicator = item as? Indicator {
			// This is an Indicator item
			let subTag = indicator.tag!
			switch tableColumn?.identifier.rawValue {
			case "TagColumn":
				// Return the a text view with the subtag
				view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SubfieldTag"),
											owner: self) as? NSTableCellView
				view?.textField?.stringValue = subTag
			case "SubfieldInfoColumn":
				// Return an NSPopupButton appropriately populated
				let fieldTag = indicator.field!.tag!
				let index = Int(subTag.prefix(2).dropFirst())!
				view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SubfieldChoices"),
											owner: self) as? NSTableCellView
				guard let popup = view?.subviews[0] as? NSPopUpButton else { return view }
				popupDirectory[popup] = indicator
				popup.removeAllItems()
				// The Info column is almost always a text view that allows arbitrary text.
				// Fields that provide title properties have a special indicator for nonfiling characters,
				// which is a number between 0 and 9. In this case, the popup menu prosents the 0...9 range.
				if reference.indicatorValueIsNumber(for: index, field: fieldTag) {
					(0...9).forEach( {
						popup.addItem(withTitle: String($0))
						popup.lastItem!.tag = $0
					} )
					popup.selectItem(withTitle: indicator.text!)
				} else {
					// Otherwise present a choice of the indicator's possible values.
					if let values = reference.indicatorValues(for: index, field: fieldTag) {
						for value in values {
							popup.addItem(withTitle: value.value)
							let scalar = Int(value.key.unicodeScalars.first!.value)
							popup.menu!.items.last!.tag = scalar
						}
					}
					let tag = Int(indicator.text!.unicodeScalars.first!.value)
					popup.selectItem(withTag: tag)
				}
				popup.sizeToFit()
				return view
			case "DescriptionColumn":
				// Return a text view with a description
				view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Description"),
											owner: self) as? NSTableCellView
				view?.textField?.stringValue = reference.subDescription(for: indicator.tag!, of: indicator.field!.tag!)
			default: return nil
			}
			
		} else if let subfieldItem = item as? Subfield {
			// This is a Subfield item
			
			switch tableColumn?.identifier.rawValue {
			case "TagColumn":
				let subfieldTag = subfieldItem.tag!
				// Return a text view with the tag
				view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SubfieldTag"),
											owner: self) as? NSTableCellView
				view?.textField?.stringValue = subfieldTag
			case "SubfieldInfoColumn":
				// Return a text view with the subfield text
				view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SubfieldInfo"),
											owner: self) as? NSTableCellView
				view?.textField?.stringValue = subfieldItem.text!
			case "DescriptionColumn":
				// Return a text view with the description
				view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Description"),
											owner: self) as? NSTableCellView
				view?.textField?.stringValue = reference.subDescription(for: subfieldItem.tag!, of: subfieldItem.field!.tag!)
			default: return nil
			}
		}
		view?.textField?.sizeToFit()
		return view
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		return item is Field
	}
	
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		if currentFields == nil {
			return 0
		} else if item == nil {
			return currentFields!.count
		} else {
			return (item as! Field).subfields!.count
		}
	}
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		if item == nil {
			return currentFields![index].field
		} else {
			return currentFields!.first(where: { $0.field == (item as! Field) })!.subfields[index]
		}
	}
	
	// MARK: Outline Delegate
	
	func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
		return tableColumn?.identifier.rawValue == "SubfieldInfoColumn"
	}
	
	@IBAction func popupDidChange(_ popup: NSPopUpButton) {
		let item = popupDirectory[popup]!
		let index = Int(item.tag!.prefix(2).dropFirst())!
		if reference.indicatorValueIsNumber(for: index, field: item.field!.tag!) {
			item.text = String(Character(UnicodeScalar(popup.selectedTag() + 48)!))
		} else {
			item.text = String(Character(UnicodeScalar(popup.selectedTag())!))
		}
		currentMarc?.updateFromTags()
		marcController.rearrangeObjects()
	}
	
	@IBAction func didEditSubfield(_ sender: NSTextField) {
		let row = outlineView.selectedRow
		if row >= 0 {
			let item: Subfield = outlineView.item(atRow: row) as! Subfield
			item.text = sender.stringValue
			if let marc = item.field?.marc {
				marc.updateFromTags()
				if let index = (marcController.arrangedObjects as! Array<Marc>)
                    .firstIndex(of: marc) {
                    tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integersIn: 0...2))
                    let pretty = marc.prettyPrint(width: prettyPrintView.frame.size.width)
                    prettyPrintView.textStorage?.setAttributedString(pretty)
                }
			}
		}
	}
	
	func outlineViewColumnDidResize(_ notification: Notification) {
		if let column = notification.userInfo!["NSTableColumn"] as? NSTableColumn,
			column.identifier.rawValue == "SubfieldInfoColumn" {
			outlineView.noteHeightOfRows(withIndexesChanged: IndexSet(integersIn: 0..<outlineView.numberOfRows))
		}
	}
	
	@objc func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
		let standardHeight: CGFloat = 22.0
		guard let column = outlineView.tableColumns.first(where: { $0.identifier == NSUserInterfaceItemIdentifier("SubfieldInfoColumn")}),
			let subfield = item as? Subfield,
			![":1", ":2"].contains(subfield.tag),
			let text = subfield.text,
			text.count > 20 else { return standardHeight }
		let columnWidth = column.width
		let attributes: [NSAttributedString.Key : Any] = [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]
		let rect = (text as NSString).boundingRect(with: NSMakeSize(columnWidth, 1000),
												   options: .usesLineFragmentOrigin,
												   attributes: attributes)
		return max(standardHeight, rect.size.height + 2)
	}
	

}
