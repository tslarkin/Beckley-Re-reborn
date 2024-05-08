//
//  OutlineViewDragTarget.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/7/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

extension MarcEditor {
	
	func outlineView(_ view: NSOutlineView, validateDrop: NSDraggingInfo, proposedItem: Any?, proposedChildIndex: Int) -> NSDragOperation {
		let noDrag: NSDragOperation = []
		let pasteboard = validateDrop.draggingPasteboard
        guard let items = pasteboard.pasteboardItems,
            items.count > 0 else { return noDrag }
        guard let dragArray = pasteboard.readObjects(forClasses: [MarcPasteboardItem.self], options: nil) as? Array<MarcPasteboardItem> else { return noDrag }
		guard let marc = currentFields else { return noDrag }
		guard let proposedItem = proposedItem as? Field else { return noDrag}
		itemsAreExpandable = true
		if proposedItem.tag! != dragArray[0].fieldTag {
			itemsAreExpandable = false
		}
        guard let subfields = proposedItem.subfields as? Set<Subfield> else { return noDrag }
		let tag = dragArray.first!.fieldTag
		if	proposedItem.tag! == tag {
			let subTags = subfields.map({ $0.tag! }).sorted()
			let nonRepeaters = subTags.filter({ !reference.subfieldRepeats(for: $0, of: tag) })
			let newTags = dragArray.map({ $0.subfieldTag })
			if Set(nonRepeaters).intersection(newTags).count == 0 {
				if view.isItemExpanded(proposedItem) {
					let firstSubtag = dragArray.first!.subfieldTag + "*"
					let subTags = (subfields.map({ $0.tag! }) + [firstSubtag]).sorted()
					let index = subTags.firstIndex(of: firstSubtag)!
					view.setDropItem(proposedItem, dropChildIndex: index)
				} else {
					view.setDropItem(proposedItem, dropChildIndex: NSOutlineViewDropOnItemIndex)
				}
				return .copy
			}
		}
		let tags = marc.map({ $0.field.tag! + "*" }).sorted()
		let nonRepeaters = tags.filter({ !reference.fieldRepeats(for: $0) })
		if !Set(nonRepeaters).contains(tag) {
			// Figure the child index for the new field.
			let firstFieldTag = dragArray.first!.fieldTag + " "
			let proposedTags = (tags + [firstFieldTag]).sorted()
			let index = proposedTags.firstIndex(of: firstFieldTag)!
			view.setDropItem(nil, dropChildIndex: index)
			return .copy

		}
		return noDrag
	}
	
	func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
		let pasteboard = info.draggingPasteboard
		guard let items = pasteboard.pasteboardItems,
			items.count > 0 else { return false }
		guard let dragArray = pasteboard.readObjects(forClasses: [MarcPasteboardItem.self],
													 options: nil) as? Array<MarcPasteboardItem> else { return false }
		let moc = marcController.managedObjectContext!
		var field: Field
		if item != nil {
			field = item as! Field
		} else {
			field = addField(with: dragArray.first!.fieldTag, to: currentMarc!)
		}
		for dragInfo in dragArray {
			let subfield = NSEntityDescription.insertNewObject(forEntityName: "Subfield", into: moc) as! Subfield
			subfield.tag = dragInfo.subfieldTag
			subfield.text = ""
			field.addToSubfields(subfield)
		}
		currentMarc!.updateFromTags()
		updateCurrentFields()
		tableView.reloadData(forRowIndexes: IndexSet(integer: tableView.selectedRow),
							 columnIndexes: IndexSet(integersIn: 0...2))
		outlineView.reloadData()
		itemsAreExpandable = true
		outlineView.expandItem(field)
		return true
	}
}
