//
//  MarcTranslator.swift
//  Beckley
//
//  Created by Timothy Larkin on 3/30/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

let leaderLength = 24
let directoryLength = 12
let dataBaseAddressOffset = 12
let dataBaseAddressSize = 5
let recordLengthOffset = 0
let recordLengthSize = 5
let tagSize = 3
let lengthSize = 4
let offsetSize = 5

let fieldSeparator = UInt8(0x1e)
let recordSeparator = UInt8(0x1d)
let subfieldSeparator = "$"


@discardableResult func makeMarc(_ raw: Data, moc: NSManagedObjectContext, isOxford: Bool)-> Marc
{
	func dataToInt(_ data: Data)-> Int {
		return Int(data.reduce(0, {
                                let a = ($0 * 10)
                                let b = Int($1 - 48)
                                return a + b
        }))
	}
	
	func dataToString(_ data: Data)-> String {
		let isUTF8 = raw[9] == 0x61
		let str = isUTF8 ? String(data: data, encoding: .utf8)! : _marc8ToUTF8(Data(data))
		return str
	}
	
	let marc = NSEntityDescription.insertNewObject(forEntityName: "Marc", into: moc) as! Marc
	
	let leader = raw[0..<leaderLength]
//	let encoding = leader[9]
//	switch encoding {
//	case 0x20: // " "
//		print("Marc8")
//	case 0x61: // "a"
//		print("UTF-8")
//	default:
//		print("Unknown")
//	}
	let leaderData = leader[Range(NSRange(location: recordLengthOffset, length: recordLengthSize))!]
	var size = dataToInt(leaderData)
	
	// parse the fields.  Trim off the record terminator and the last field terminator
	if raw[size - 1] == recordSeparator {
		size -= 2
	}
	let fields = raw[leaderLength...].split(separator: fieldSeparator)
	var tagList = Data(fields[0])
	let bytes = tagList.count
	var i: Int = 0
	for fieldData in fields[1...] {
		if i + tagSize > bytes { break }
		let tag = tagList[Range(NSMakeRange(i, tagSize))!]
		i += directoryLength
		let itag = dataToInt(tag)
		if itag > 900 { continue }
		let field = NSEntityDescription.insertNewObject(forEntityName: "Field", into: moc) as! Field
		marc.addToFields(field)
		field.tag = dataToString(tag)
		
		var needIndicators = true
		for subfieldDatum in fieldData.split(separator: UInt8(0x1f)) {
			if 10...900 ~= itag && needIndicators {
				needIndicators = false
				let indicatorString = dataToString(subfieldDatum)
				var index = indicatorString.startIndex
				for i in 1...2 {
					let indicator: Indicator
						= NSEntityDescription.insertNewObject(forEntityName: "Indicator",
															  into: moc) as! Indicator
					indicator.tag = ":\(i)"
					indicator.text = String(indicatorString[index])
					index = indicatorString.index(after: index)
					field.addToSubfields(indicator)
				}
				continue
			}
			var sub = dataToString(subfieldDatum)
			let subfield
				= NSEntityDescription.insertNewObject(forEntityName: "Subfield", into: moc) as! Subfield
			field.addToSubfields(subfield)
			let key: String
			if 10...900 ~= itag {
				key = String(sub.prefix(1))
				sub.remove(at: sub.startIndex)
			} else {
				key = "?"
			}
			subfield.tag = key
			subfield.text = sub
		}
	}
	marc.updateFromTags()
	return marc
}
