//
//  Update Database.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/29/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

var updated = true

func updateDatabase(_ moc: NSManagedObjectContext) {
	
	func removeOrphans(in entity: String, moc: NSManagedObjectContext) {
		let request = NSFetchRequest<NSManagedObject>.init(entityName: entity)
		let predicate = NSPredicate.init(format: "marcs.@count == 0")
		request.predicate = predicate
		let hits = try? moc.fetch(request)
		hits?.forEach({ moc.delete($0)})
	}
	
	
	if updated { return }
	updated = true
	removeOrphans(in: "Subject", moc: moc)
	removeOrphans(in: "Creator", moc: moc)
	
	var counts = ((0, 0), (0, 0), (0, 0))
	let request1: NSFetchRequest<Subfield> = Subfield.fetchRequest()
	if let hits = try? moc.fetch(request1) {
		counts.0.0 = hits.count
		for hit in hits {
			let new = Marc8ToUTF8(hit.text)
			if hit.text != new && !hit.text!.contains("£") {
				hit.text = new
				counts.0.1 += 1
			}
		}
	}
	let request2: NSFetchRequest<Marc> = Marc.fetchRequest()
	if let hits = try? moc.fetch(request2) {
		for hit in hits {
			hit.updateTitle()
			hit.updateAuthor()
		}
	}
	let request3: NSFetchRequest<Subject> = Subject.fetchRequest()
	if let hits = try? moc.fetch(request3) {
		counts.1.0 = hits.count
		for hit in hits {
			let new = Marc8ToUTF8(hit.key)
			if new != hit.key {
				hit.key = new
				counts.1.1 += 1
			}
		}
	}
	let request4: NSFetchRequest<Creator> = Creator.fetchRequest()
	if let hits = try? moc.fetch(request4) {
		counts.2.0 = hits.count
		for hit in hits {
			let key = hit.value(forKey: "key") as! String
			let new = Marc8ToUTF8(key)
			if new != key {
				hit.setValue(new, forKey: "key")
				counts.2.1 += 1
			}
		}
	}

	print(counts)
	removeOrphans(in: "Subject", moc: moc)
	removeOrphans(in: "Creator", moc: moc)
}
