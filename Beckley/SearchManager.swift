//
//  SearchManager.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/3/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

var searchEngines: [(name: String, url: String?)] = [
	("Local", nil),
	("Cornell", "catalog.library.cornell.edu:7090/Voyager"),
	("LoC", "z3950.loc.gov:7090/voyager"),
	("Oxford", "library.ox.ac.uk:210/MAIN*BIBMAST")
]

class SearchManager: NSResponder {
	
	@IBOutlet weak var searchEnginesPopup: NSPopUpButton!
	@IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var marcController: NSArrayController!
	@IBOutlet weak var marcEditor: MarcEditor!
	@objc dynamic var currentEngineName = "Local" {
		didSet {
		}
	}
	
	var remoteEngine: RemoteSearch?
	var localEngine: LocalSearch?
	var currentEngine: SearchEngine?
	var engineType: SearchEngineType = .local
	var searchCode: Int = 1013
	var nextMarc: Marc? = nil

	@objc dynamic var searchEngineIndex = 0 {
		didSet {
			let engine = searchEngines[searchEngineIndex]
			if engine.url == nil {
				engineType = .local
				searchField.searchMenuTemplate = localEngine?.searchMenuTemplates()
                currentEngine = localEngine
                searchField.sendsWholeSearchString = false
                setItemOn(searchField.searchMenuTemplate!.items[0])
                if nextMarc != nil {
					DispatchQueue.main.async {
						self.marcEditor.display(self.nextMarc!)
					}
				}
			} else {
				engineType = SearchEngineType.remote(engine.url!)
				if oldValue == 0 {
					nextMarc = marcEditor.currentMarc
					marcEditor.currentMarc = nil
					searchField.searchMenuTemplate = remoteEngine?.searchMenuTemplates()
					currentEngine = remoteEngine
					searchField.sendsWholeSearchString = true
                    setItemOn(searchField.searchMenuTemplate!.items[3])
                    //searchCode = 9
				}
			}
            guard let currentEngine = currentEngine else { return }
            currentEngine.prepareContext()
            marcController.managedObjectContext = currentEngine.moc
            marcController.filterPredicate = nil
		}
	}
	
    // Used to populate the Search Engines Popup with menu items.
	@objc dynamic var searchEngineNames: [String] {
		get {
			return searchEngines.map{ $0.name }
		}
	}
	
	@IBAction func editMarc(_ sender: NSTableView) {
		marcEditor.editMarc(sender)
	}
	
	@IBAction func importMarc(_ table: NSTableView) {
        if case SearchEngineType.local = engineType { return }
		let marc = marcController.selectedObjects[0] as! Marc
        localEngine?.prepareContext()
        let copy = currentEngine?.copy(marc, to: localEngine!.moc!)
		marcEditor.announce("Copied \"\(copy!.title!)\".")
		nextMarc = copy
	}
	
	@IBAction func search(_ item: NSSearchField) {
        guard let currentEngine = currentEngine else { return }
		currentEngine.prepareContext()
		marcController.managedObjectContext = currentEngine.moc
		marcController.filterPredicate = nil
        guard let query = currentEngine.makeQuery(key: searchCode, term: item.stringValue)
            else { return }
		currentEngine.doSearch(query: query, type: engineType)
        let filter = currentEngine.filterPredicate(query: query)
        marcController.filterPredicate = filter
        
	}
	
	override func awakeFromNib() {
		localEngine = LocalSearch()
		remoteEngine = RemoteSearch()
		currentEngine = localEngine
		searchField.searchMenuTemplate = currentEngine?.searchMenuTemplates()
        setItemOn(searchField.searchMenuTemplate!.items[0])
		let window = searchField.window
		nextResponder = window?.nextResponder
		window?.nextResponder = self
	}
    
    func setItemOn(_ item: NSMenuItem) {
        searchCode = item.tag // == 1013 ? 1003 : item.tag
        searchField.placeholderString = item.title
        searchField.stringValue = ""
    }
	
	@objc func setSearchKey(_ item: NSMenuItem) {
        setItemOn(item)
	}
}
