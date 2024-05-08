//
//  SubjectCreatorExtraction.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/11/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

let subjectTags: Set<String> = ["600", "610", "611", "648", "650", "651", "654",
	 "690", "691", "692", "693", "694", "695", "696", "657", "698", "699"]
let creatorTags: Set<String> = ["100", "110", "111", "400", "410", "411", "700", "705", "710",
				   "711", "800", "810", "811"]

extension Marc {
	
	func removeTrailingPunctuation(_ string: String)-> String {
//		guard var str = str else { return nil }
		var str = string
		guard str.count > 1 else { return str }
		let foc = " [from old catalog]"
		if str.hasSuffix(foc) {
			str = String(str.dropLast(foc.count))
		}
		let dropSet: Set<Character> = ["/", ":", ";", ",", ".", " ", "=", "／"]
		str = String(str.reversed().drop(while: { dropSet.contains($0) }).reversed())
		return str
	}
	
	func repeatingTags(_ tag: String)-> [Field] {
		return (fields as! Set<Field>).filter({ $0.tag == tag })
	}
	
	func fieldByTag(_ tag: String)-> Field? {
		let tags = repeatingTags(tag)
		return tags.count == 0 ? nil : tags[0]
	}
	
	func updateAuthor() {
		let oldAuthor: String? = author == "" ? nil : author
		var newAuthor: String?
		for tag in ["100"] {
			newAuthor = fieldByTag(tag)?.subfieldText(for: "a")
			if newAuthor != nil { break }
		}
		if newAuthor == nil {
			var subauthors: [Field] = []
			for tag in ["700", "705"] {
				subauthors = repeatingTags(tag)
				if subauthors.count > 0 { break }
			}
			if subauthors.count == 0 {
				newAuthor = nil
				author = nil
				return
			} else if subauthors.count == 1 {
				newAuthor = subauthors[0].subfieldText(for: "a") ?? "?"
				if let text = subauthors[0].subfieldText(for: "e"),
					text.count > 0 {
					newAuthor = newAuthor! + " " + text
				}
			} else {
				newAuthor = subauthors[0].subfieldText(for: "a") ?? ""
				newAuthor = newAuthor! + " et. al."
			}
		}
		if newAuthor != nil {
			newAuthor = removeTrailingPunctuation(newAuthor!)
		}
		if newAuthor != oldAuthor {
			author = newAuthor
		}
	}
	
	func updateLCCN() {
		let field = fieldByTag("010")
		if let lccn = field?.subfieldText(for: "a") {
			LCNumber = lccn
		}
	}
	
	func updateTitle() {
		guard let titleField = fieldByTag("245") else {
			title = nil
			sortTitle = nil
			return
		}
		let oldTitle: String? = title == "" ? nil : title
		guard let text = titleField.subfieldText(for: "a")
			else { title = nil; sortTitle = nil; return }
		let newTitle = removeTrailingPunctuation(text)
		var newSortTitle = newTitle
		if let nonFilingChars = titleField.indicator(for: ":2")?.text,
			nonFilingChars.count > 0,
			newTitle.count > 2 {
			let view = nonFilingChars.utf8
			let n = Int(view[view.startIndex]) - 48
			if n >= 2,
				1..<newTitle.count ~= n {
				newSortTitle = String(newSortTitle.dropFirst(n))
            }
        }
        if newSortTitle != sortTitle {
            sortTitle = newSortTitle
        }
		if oldTitle == nil || newTitle != oldTitle! {
			title = newTitle
		}
	}
	
	func updateDCN() {
		var dewey = "Unclassified"
		guard let t82 = fieldByTag("082") else { return }
		guard let asubs = t82.subfields(for: "a") else { return }
		for adewey in asubs {
			guard let text = adewey.text,
				text.count >= 3 else { continue }
			if text.first!.isNumber {
				dewey = text
				break
			}
		}
		dcn = dewey
	}
	
	func updateFromTags() {
		updateTitle()
		updateAuthor()
		updateDCN()
		updateLCCN()
		updateSubjectsAndCreators()
	}
	
	func findObject(for key: String, in entity: String)-> NSManagedObject {
		let request = NSFetchRequest<NSManagedObject>(entityName: entity)
		let predicate = NSPredicate(format: "key == %@", removeTrailingPunctuation(key))
		request.predicate = predicate
		let result = try? managedObjectContext!.fetch(request)
		if result!.count > 0 {
			return result![0]
		} else {
			let object = NSEntityDescription
				.insertNewObject(forEntityName: entity,
								 into: managedObjectContext!)
			object.setValue(key, forKey: "key")
			return object
		}
	}
	
	func getRelatedObjects(from tags:Set<String>, in entity: String, replacing old: Set<NSManagedObject>)-> Set<NSManagedObject> {
		guard let fields = (fields as? Set<Field>)?.filter({ tags.contains($0.tag!)})
			else { return [] }
		var newObjects: Set<NSManagedObject> = []
		for field in fields {
			if let subfieldA = (field.subfields as? Set<Subfield>)?.first(where: { $0.tag == "a" }) {
				let object = findObject(for: subfieldA.text!, in: entity)
				newObjects.insert(object)
			}
		}
		for removed in old.subtracting(newObjects) {
			if let marcs = removed.value(forKey: "marcs") as? Set<Marc>,
				marcs.count == 1 {
				removed.setValue(NSSet(), forKey: "marcs")
				managedObjectContext!.delete(removed)
			}
		}
		return newObjects
	}
	
	func updateSubjectsAndCreators() {
		let newSubjects = getRelatedObjects(from: subjectTags,
											in: "Subject",
											replacing: subjects as! Set<Subject>)
		subjects = newSubjects as NSSet
		
		let newCreators = getRelatedObjects(from: creatorTags,
											in: "Creator",
											replacing: creators as! Set<Creator>)
		creators = newCreators as NSSet
	}
	
}
