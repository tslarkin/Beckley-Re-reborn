//
//  RemoteSearch.swift
//  Beckley
//
//  Created by Timothy Larkin on 3/30/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

class RemoteSearch: NSObject, SearchEngine {
	
	static let searchKeys: Dictionary<Int, String> = [
		1013: "au", 4: "ti", 7: "isbn", 9: "lccn", 21: "su", 30: "date", 1016: "af"
	]
	
	var searchKeys: Dictionary<Int, String> {
		get {
			return RemoteSearch.searchKeys
		}
	}
	
	var container: NSPersistentContainer?
	
	var moc: NSManagedObjectContext? {
		get {
			return container?.viewContext
		}
	}
	
	func makeQuery(key: Int, term: String)-> String? {
		if term.count == 0 { return nil }
		if key == 1016 { return term }
		guard let index = searchKeys.index(forKey: key) else { return nil }
		return "\(searchKeys[index].value) = \(term)"
	}
	
	func doSearch(query: String, type: SearchEngineType) {
		if case let .remote(url) = type {
			search(server: url, query: query)
		}
	}
	
	func filterPredicate(query: String)-> NSPredicate? {
		return nil
	}
	
	func search(server: String, query: String) {
		results = [:]
		var z = ZoomConnection(path: server)
		let zq = ZoomQuery(search: query)
		z.doSearch(zq)
		DispatchQueue.global(qos: .userInitiated).async {
			z.getResults(callBack: self.gettingResults(_:))
		}
//		z.getResults(callBack: self.gettingResults(_:))
		
//		z.close()
	}
	
	func prepareContext() {
		container = mockPersistantContainer()
	}
	
	func copy(_ marc: Marc, to context: NSManagedObjectContext)-> Marc? {
		return makeMarc(results[marc]!, moc: context, isOxford: false)
	}
	
	var results: Dictionary<Marc,Data> = [:]
	
	func mockPersistantContainer()-> NSPersistentContainer {
		let model = (NSApp.delegate as! AppDelegate).persistentContainer.managedObjectModel
		let container = NSPersistentContainer(name: "RemoteResults", managedObjectModel: model)
		let description = NSPersistentStoreDescription()
		description.type = NSInMemoryStoreType
		description.shouldAddStoreAsynchronously = false // Make it simpler in test env
		
		container.persistentStoreDescriptions = [description]
		container.loadPersistentStores { (description, error) in
			// Check if the data store is in memory
			precondition( description.type == NSInMemoryStoreType )
			
			// Check if creating container wrong
			if let error = error {
				fatalError("Create an in-mem coordinator failed \(error)")
			}
		}
		return container
	}
	
	func gettingResults(_ partialResults: [Data]) {
		for result in partialResults {
			let marc = makeMarc(result, moc: moc!, isOxford: false)
			results[marc] = result
		}
	}
	
}
