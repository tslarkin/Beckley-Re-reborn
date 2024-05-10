//
//  Search Engine.swift
//  
//
//  Created by Timothy Larkin on 4/3/19.
//

import Cocoa

enum SearchEngineType {
	case local
	case remote(String)
}

let searchMenuItems: [(name: String, code: Int)] = [
	("Author", 1013), ("Title", 4), ("Subject", 21), ("ISBN", 7), ("LCCN", 9), ("Dewey", 13),
	("Date", 30), ("Note", 63), ("Any", 1016)
]


protocol SearchEngine {
	var searchKeys: Dictionary<Int, String> { get }
	var moc: NSManagedObjectContext? { get }
	func makeQuery(key: Int, term: String)-> String?
	func doSearch(query: String, type: SearchEngineType)
	func filterPredicate(query: String)-> NSPredicate?
	func prepareContext()
	func copy(_ marc: Marc, to context: NSManagedObjectContext)-> Marc?
	func searchMenuTemplates()->NSMenu
}

extension SearchEngine {
	
	func searchMenuTemplates()->NSMenu {
		let menu = NSMenu()
		menu.title = "Search For:"
		for (i, values) in searchMenuItems
			.filter( { searchKeys.index(forKey: $0.code) != nil })
			.enumerated() {
			let item = NSMenuItem(title: values.name,
								  action: #selector(SearchManager.setSearchKey(_:)), keyEquivalent: "\(i+1)")
			item.tag = values.code
			item.isEnabled = true
			menu.addItem(item)
		}
		return menu
	}
}
