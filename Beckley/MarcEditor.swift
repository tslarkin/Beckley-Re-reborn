//
//  MarcEditor.swift
//  Beckley
//
//  Created by Timothy Larkin on 3/25/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

extension String {
    
    func titleCased()-> String {
        let exceptions: Set<String> = ["OF", "THE", "A"]
        var t: Array<String> = []
        for word in self.split(separator: " ") {
            let w = String(word)
            if exceptions.contains(w) {
                t.append(w.lowercased())
            } else {
                t.append(w.prefix(1) + w.dropFirst().lowercased())
            }
        }
        return t.joined(separator: " ")
    }
}

var subfieldsConverted = true
var itemsAreExpandable = true
@objc class MarcEditor: NSObject, NSMenuItemValidation,
	NSOutlineViewDataSource, NSOutlineViewDelegate,
	NSTableViewDelegate
{
	
	struct Entry {
		var field: Field
		var subfields: Array<Subfield>
	}
	
	@IBOutlet weak var marcController: NSArrayController!
	@IBOutlet weak var outlineView: NSOutlineView!
	@IBOutlet weak var expansionButton: NSButton!
	@IBOutlet weak var tableView: NSTableView!
	@IBOutlet weak var reference: MarcReference!
	@IBOutlet weak var searchManager: SearchManager!
    @IBOutlet var prettyPrintView: PrettyPrintView!
    
	var currentFields: [Entry]?
	var currentMarc: Marc? {
		didSet {
			updateCurrentFields()
			outlineView.reloadData()
		}
	}
	
	weak var moc: NSManagedObjectContext!
	
	// How to know which Indicator goes with an NSPopupButton?
	// Apparently we have to keep track.
	var popupDirectory: Dictionary<NSPopUpButton,Indicator> = [:]
	
	func updateCurrentFields() {
		if currentMarc == nil {
			currentFields = nil
			prettyPrintView.textStorage?.setAttributedString(NSAttributedString())
		} else {
			let fields = Array(currentMarc!.fields!) as! Array<Field>
			currentFields = fields
                .filter({ reference.fieldRef(for: $0.tag!) != nil || $0.tag! == "880" })
				.sorted(by: { $0.tag! < $1.tag! })
				.map { (field: Field) in
					Entry(field: field,
						  subfields: (Array(field.subfields!) as! Array<Subfield>).sorted(by: <))
			}
		}
	}
	
	func convertIndicators() {
		if subfieldsConverted == true { return }
		subfieldsConverted = true
		let request: NSFetchRequest<Subfield> = Subfield.fetchRequest()
		let predicate = NSPredicate(format: "tag == \":1\" OR tag == \":2\"")
		request.predicate = predicate
		let hits = try? moc.fetch(request)
		let subfields = Set(hits!)
		let request2: NSFetchRequest<Indicator> = Indicator.fetchRequest()
		let hits2 = try? moc.fetch(request2)
		let indicators = Set(hits2!) as Set<Subfield>
		let difference = subfields.subtracting(indicators)
		for subfield in difference {
			let indicator = NSEntityDescription
				.insertNewObject(forEntityName: "Indicator", into: moc) as! Indicator
			indicator.tag = subfield.tag
			indicator.text = subfield.text
			indicator.field = subfield.field
			indicator.index = subfield.index
		}
		print("Converted \(difference.count) Subfields.")
		difference.forEach({ moc.delete($0) })
	}
	
	override func awakeFromNib() {
		outlineView.registerForDraggedTypes([.marcPasteboardItem])
		let delegate = NSApp.delegate as! AppDelegate
		moc = delegate.persistentContainer.viewContext
		updateDatabase(moc)
        convertIndicators()
	}
	
	// MARK: Edit and display Marc

	@IBAction func expand(_ outline: NSOutlineView) {
		let item = outline.item(atRow: outline.selectedRow)
		if !outline.isExpandable(item) { return }
		if outline.isItemExpanded(item) {
			outline.collapseItem(item)
		} else {
			outline.expandItem(item)
		}
	}
	
	@IBAction func outlineExpansion(_ button: NSButton) {
		guard let currentFields = currentFields else { return }
		if button.state == .on {
			currentFields.forEach({ if Int($0.field.tag!)! > 10 { outlineView.expandItem($0.field)}})
		} else {
			currentFields.forEach({ outlineView.collapseItem($0.field)})
		}
	}
	
	
	@IBAction func editMarc(_ sender: NSTableView) {
		let selectedObjects = marcController.selectedObjects!
		popupDirectory = [:]
		if selectedObjects.count == 0 {
			currentMarc = nil
		} else {
			expansionButton.state = .off
			guard let marc = selectedObjects[0] as? Marc else { return }
			currentMarc = marc
//            if marc.rendered == nil {
//                let pretty = marc.prettyPrint()
//                marc.rendered = try? NSKeyedArchiver.archivedData(withRootObject: pretty,
//                                                             requiringSecureCoding: true) as NSData
//            }
//            if let pretty = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(marc.rendered! as Data)
//                as? NSAttributedString) {
//                prettyPrintView.textStorage?.setAttributedString(pretty)
//            }
			let pretty = marc.prettyPrint(width: prettyPrintView.frame.size.width)
            prettyPrintView.textStorage?.setAttributedString(pretty)
		}
	}
	
	func display(_ marc: Marc) {
		guard let index = (marcController.arrangedObjects as! Array<Marc>).firstIndex(of: marc)
			else { return }
		tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
		tableView.scrollRowToVisible(index)
		currentMarc = marc
		currentFields!.forEach({ if Int($0.field.tag!)! > 10 { outlineView.expandItem($0.field)}})
	}
	
	func announce(_ message: String) {
		let messageRect = (message as NSString)
			.boundingRect(with: NSMakeSize(1000, 40),
						  options: NSString.DrawingOptions(rawValue: 0),
						  attributes: MessageView.attributes)
		let window = outlineView.window!
		let windowFrame = window.contentView!.frame
		let windowCenter = NSPoint(x: NSMidX(windowFrame), y: NSMidY(windowFrame))
		let messageFrame = NSRect(x: windowCenter.x - messageRect.size.width / 2.0 - 20,
								  y: windowCenter.y - 20,
								  width: messageRect.size.width + 40,
								  height: messageRect.size.height + 30)
		let view = MessageView(frame: messageFrame)
		view.message = message
		view.messageWidth = messageRect.size.width
		view.isHidden = false
		view.alphaValue = 0.0
		window.contentView!.addSubview(view, positioned: .above, relativeTo: nil)
		// Create an animation that ramps the view's alpha from zero to 1 over X seconds.
		// The completion handler dispatches a block to be executed in Y seconds. This
		// block introduces another animation to deccrease the view's alpha back to zero
		// in X seconds. The second animation has a completion handler to remove the view.
		NSAnimationContext.runAnimationGroup({
			$0.duration = 1
			view.animator().alphaValue = 1.0 },
		 completionHandler: {
			DispatchQueue.main.asyncAfter(deadline: .now() + 2,
										  execute: {
											NSAnimationContext.runAnimationGroup({
												$0.duration = 1
												view.animator().alphaValue = 0.0 },
											 completionHandler: { view.removeFromSuperview() } )})
		})
	}
	
	// MARK: Deletion of Fields and Subfields
	
	func itemToDelete()-> NSManagedObject? {
		var item: NSManagedObject? = nil
		let responder = tableView.window?.firstResponder
		if responder == tableView {
			let row = tableView.selectedRow
			if row >= 0 {
				item = (marcController.arrangedObjects as! Array<Marc>)[row]
			}
		}
		if responder == outlineView {
			let row = outlineView.selectedRow
			if row >= 0 {
				let thing = (outlineView.item(atRow: row) as! NSManagedObject)
				if !(thing is Indicator) {
					item = thing
				}
			}
		}
		return item
	}
	
	@IBAction func delete(_ sender: Any) {
		guard let toDelete = itemToDelete() else { return }
		if toDelete is Indicator { return }
		let alert = NSAlert()
		alert.alertStyle = .warning
		alert.messageText = "Are you sure you want to delete "
		let itemToDelete: NSManagedObject
		if let item = toDelete as? Field {
			itemToDelete = item
			let description = reference.fieldDescription(for: item.tag!)
			let extra = "Field \(item.tag!) (\(description))?"
			alert.messageText += extra
		} else if let item = toDelete as? Subfield {
			itemToDelete = item
			let fieldTag = item.field!.tag!
			let description1 = reference.subfieldDescription(for: item.tag!,
															 of: fieldTag)
			let description2 = reference.fieldDescription(for: fieldTag)
			let extra = "\nSubfield \"\(item.tag!)\" (\(description1)) \nof Field \(fieldTag) (\(description2))?"
			alert.messageText += extra
		} else if let item = toDelete as? Marc {
			itemToDelete = item
			var title = item.title
			if title == nil || title!.count == 0 {
				title = "Unknown Title"
			} else {
				title = "\"\(title!)\""
			}
			var author = item.author
			if author?.count == 0 {
				author = nil
			}
			let extra = author != nil ? "the book \(title!) by \(author!)?" : "the book \(title!)?"
			alert.messageText += extra

		} else {
			return
		}
		alert.addButton(withTitle: "Yes")
		alert.addButton(withTitle: "Cancel")
		alert.beginSheetModal(for: tableView.window!, completionHandler: { response in
			if response == NSApplication.ModalResponse.alertFirstButtonReturn {
				self.moc.delete(itemToDelete)
				if itemToDelete === self.currentMarc {
					self.currentMarc = nil
				} else {
                    if let field = itemToDelete as? Field {
                        self.currentMarc!.removeFromFields(field)
                    } else if let subfield = itemToDelete as? Subfield {
                        subfield.field!.removeFromSubfields(subfield)
                    }
                    self.currentMarc!.updateFromTags()
					self.updateCurrentFields()
					let index = self.tableView.selectedRow
					self.tableView.reloadData(forRowIndexes: IndexSet(integer: index),
											  columnIndexes: IndexSet(0...2))
                }
                self.outlineView.reloadData()
			}
		})	}
	
	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		if menuItem.title == "Delete" {
			return itemToDelete() != nil
		}
		if menuItem.title == "New Record" {
			if case SearchEngineType.local = searchManager.engineType  {
				return true
			}
		}
		return false
	}
	
	// Adding new Marcs and Fields
	
	@IBAction func newMarc(_ sender: Any) {
        searchManager.searchField.stringValue = ""
		let marc = NSEntityDescription.insertNewObject(forEntityName: "Marc", into: moc) as! Marc
		for tag in ["082", "100", "245", "260"] {
			let field = addField(with: tag, to: marc)
			let subfield = NSEntityDescription.insertNewObject(forEntityName: "Subfield", into: moc) as! Subfield
			field.addToSubfields(subfield)
			subfield.tag = "a"
			subfield.text = ""
			if tag == "082" {
				subfield.text = "000"
			} else if tag == "260" {
				for subTag in ["b", "c"] {
					let subfield = NSEntityDescription.insertNewObject(forEntityName: "Subfield", into: moc) as! Subfield
					field.addToSubfields(subfield)
					subfield.tag = subTag
					subfield.text = ""
				}
			}
		}
		marcController.addObject(marc)
		marcController.rearrangeObjects()
		if let index = (marcController.arrangedObjects as! Array<Marc>).firstIndex(of: marc) {
			tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
			tableView.scrollRowToVisible(index)
			marcController.setSelectionIndex(index)
			currentMarc = marc
			editMarc(tableView)
			currentFields!.forEach({ if Int($0.field.tag!)! > 10 { outlineView.expandItem($0.field)}})
		}
	}
	
	@discardableResult func addField(with tag: String, to marc: Marc)-> Field {
		let moc = marc.managedObjectContext!
		let field = NSEntityDescription.insertNewObject(forEntityName: "Field",
														into: moc) as! Field
		field.tag = tag
		marc.addToFields(field)
		for index in 1...2 {
			let indicator = NSEntityDescription.insertNewObject(forEntityName: "Indicator",
																into: moc) as! Indicator
			field.addToSubfields(indicator)
			indicator.tag = ":\(index)"
			indicator.text = reference.indicatorDefaultValue(for: index, field: tag)
		}
		return field
	}
	
	// MARK: Table Delegate
	
	func tableViewSelectionDidChange(_ notification: Notification) {
		editMarc(tableView)
	}
}
