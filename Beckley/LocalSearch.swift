//
//  LocalSearch.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/3/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

class LocalSearch: NSObject, SearchEngine {
	
	static let searchKeys: Dictionary<Int, String> = [
		1013: "author", 4: "title", 13: "dw", 21: "subject", 1016: "af"
	]
	
	var searchKeys: Dictionary<Int, String> {
		get {
			return LocalSearch.searchKeys
		}
	}
	
	var moc: NSManagedObjectContext?
	
	func makeQuery(key: Int, term: String)-> String? {
		guard let index = searchKeys.index(forKey: key),
        term.count > 0 else { return nil }
		switch key {
		case 1013:
			return #"ANY creators.key contains[cd] "\#(term)""#
		case 1016:
			return #"ANY creators.key contains[cd] "\#(term)" OR title contains[cd] "\#(term)" OR ANY subjects.key contains[cd] "\#(term)""#
		case 13:
			return #"dcn BEGINSWITH "\#(term)""#
		case 21:
			return "ANY subjects.key contains[cd] \"\(term)\""
		default:
			return #"\#(searchKeys[index].value) contains[cd] "\#(term)""#
		}
	}
	
	func doSearch(query: String, type: SearchEngineType) {
		
	}
	
	func filterPredicate(query: String)-> NSPredicate? {
		let predicate = NSPredicate(format: query)
		return predicate
	}
	
	func prepareContext() {
		moc = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
	}
	
	func copy(_ marc: Marc, to context: NSManagedObjectContext)-> Marc? {
		return nil
	}
	
}
