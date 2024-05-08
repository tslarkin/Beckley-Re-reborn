//
//  MarcReference.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/6/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

class MarcReference: NSObject, NSTableViewDataSource, NSTableViewDelegate {
	static var currentReference: MarcReference!
	
	struct IndicatorRef {
		var tag: String
		var description: String
		var values: Dictionary<String,String>
		var defaultValue: String
	}
	
	struct SubfieldRef {
		var tag: String
		var description: String
		var repeating: Bool
	}
	
	struct FieldRef {
		init(tag: String, description: String, subfields: [String:SubfieldRef], indicators: [IndicatorRef], repeating: Bool) {
			self.tag = tag
			self.description = description
			self.subfields = subfields
			self.indicators = indicators
			self.repeating = repeating
		}
		var tag: String
		var description: String
		var subfields: [String: SubfieldRef]
		var indicators: [IndicatorRef]
		var repeating: Bool
	}

	var fieldDictionary: Dictionary<String, FieldRef>
	
	override init() {
		var dictionary: Dictionary<String, FieldRef> = [:]
		typealias AnyDictionary = Dictionary<String, Any>
		let source = Bundle.main.path(forResource: "bigmarcreference", ofType: "plist")
		let data = try? Data.init(contentsOf: URL(fileURLWithPath: source!))
		let plist: Array<AnyDictionary> =
			try! PropertyListSerialization.propertyList(from: data!,
														options: [],
														format: nil) as! Array<AnyDictionary>
		let sections = plist.map{ (d: Dictionary) in d["fields"] }
		if let sections = sections as? Array<[AnyDictionary]> {
			for field in sections.joined() {
				let description = (field["description"] as! String).titleCased()
				let key = field["tag"] as! String
				let repeating = field["repeating"] as! Bool
				var subfieldDictionary: Dictionary<String,SubfieldRef> = [:]
				if let subfields = (field["subfields"] as? Array<AnyDictionary>) {
					for subfield in subfields {
						let tag = subfield["tag"] as! String
						let description = subfield["description"] as! String
						let repeating = subfield["repeating"] as! Bool
						let subfieldRef = SubfieldRef(tag: tag, description: description, repeating: repeating)
						subfieldDictionary[tag] = subfieldRef
					}
				}
				var indicatorList: [IndicatorRef] = []
				if let indicators = (field["indicators"] as? Array<AnyDictionary>),
					indicators.count >= 2 {
					for (index, indicator) in indicators.prefix(2).enumerated() {
						if let description = indicator["description"] as? String {
							if description == "Nonfiling characters" {
								let indicatorRef = IndicatorRef(tag: ":\(index+1)", description: description, values: [:], defaultValue: "0")
								indicatorList.append(indicatorRef)
							} else if let values = indicator["values"] as? [Dictionary<String, String>] {
								let defaultValue: String = values[0]["tag"]!
								var valueDictionary: Dictionary<String,String> = [:]
								values.forEach({ valueDictionary[$0["tag"]!] = $0["description"] })
								let indicatorRef = IndicatorRef(tag: ":\(index+1)", description: description, values: valueDictionary, defaultValue: defaultValue)
								indicatorList.append(indicatorRef)
							}
						}
					}
				}
				dictionary[key] = FieldRef(tag: key, description: description,
												subfields: subfieldDictionary,
												indicators: indicatorList,
												repeating: repeating)
			}
		}
		fieldDictionary = dictionary
		super.init()
		MarcReference.currentReference = self
	}
	
	
	func fieldRef(for tag: String)-> FieldRef? {
		guard let field = fieldDictionary[tag] else { return nil }
		return field
	}
	
	func fieldDescription(for tag: String)-> String {
		guard let fieldRef = fieldRef(for: tag) else { return "Unknown Field" }
		return fieldRef.description
	}
	
	func fieldRepeats(for tag: String)-> Bool {
		guard let fieldRef = fieldRef(for: tag) else { return false }
		return fieldRef.repeating
	}
	
	func subfieldRef(for tag: String, of field: String)-> SubfieldRef? {
		guard let field = fieldRef(for: field) else { return nil }
		guard let subfield = field.subfields[tag] else { return nil }
		return subfield
	}
	
	func subfieldDescription(for tag: String, of field: String)-> String {
		guard let subfield = subfieldRef(for: tag, of: field) else { return "Unknown Subfield" }
		let description = subfield.description
		return description
	}
	
	func subfieldRepeats(for tag: String, of field: String)-> Bool {
		guard let subfield = subfieldRef(for: tag, of: field) else { return false }
		return subfield.repeating
	}
	
	func indicators(for field: String)-> Array<IndicatorRef>? {
		guard let field = fieldRef(for: field) else { return nil }
		return field.indicators
	}
	
	func indicator(for index: Int, of field: String)-> IndicatorRef? {
		guard let field = fieldRef(for: field) else { return nil }
		return field.indicators[index-1]
	}

	func indicatorDescription(_ index: Int, for field: String)-> String {
		guard let indicator = indicator(for: index, of: field) else  { return "Unknown Indicator" }
		return indicator.description
	}
	
	func indicatorValues(for index: Int, field: String)-> Dictionary<String,String>? {
		guard let indicator = indicator(for: index, of: field) else { return nil }
		return indicator.values
	}
	
	func indicatorValueDescription(for tag: String, index: Int, field: String)-> String? {
		guard let values = indicatorValues(for: index, field: field) else { return nil }
		return values[tag]
	}
	
	func indicatorDefaultValue(for index: Int, field: String)-> String {
		guard let indicator = indicator(for: index, of: field) else { return "" }
		return indicator.defaultValue
	}
	
	func indicatorValueIsNumber(for index: Int, field: String)-> Bool {
		guard let indicator = indicator(for: index, of: field) else { return false }
		return indicator.description == "Nonfiling characters"
	}
	
	func subDescription(for tag: String, of field: String)-> String {
		if tag.prefix(1) == ":" {
			let index = Int(tag.prefix(2).dropFirst())!
			return indicatorDescription(index, for: field)
		} else {
			return subfieldDescription(for: tag, of: field)
		}
	}
	

}
