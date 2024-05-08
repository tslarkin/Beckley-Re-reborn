//
//  PrettyPrint.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/22/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

let headerFont = NSFont.init(name: "Hoefler Text Black", size: 16)!
let bodyFont = NSFont.init(name: "Hoefler Text", size: 15)!
let titleFont = NSFont.init(name: "Hoefler Text Italic", size: 15.0)!

func sideMargin(for frameWidth: CGFloat)-> CGFloat {
	let xsize = ("x" as NSString).size(withAttributes: [NSAttributedString.Key.font: bodyFont])
	let margin = max(10.0, (frameWidth - xsize.width * 52) / 2.0)
	return margin
}

extension Marc {
	
	func repeatedTags(_ tag: String)-> [Field]? {
		guard let fields = fields as? Set<Field> else { return nil }
		let hits = fields.filter({ $0.tag! == tag })
		return hits.count == 0 ? nil : Array(hits)
	}
	
	func flattenRepeatedTags(_ tag: String,
							 terminator: String,
							 separator: String)-> String? {
        guard let fields = repeatedTags(tag) else { return nil }
		let strings = fields.map({ flattenField($0, with: separator) })
		if strings.count == 0 {
			return nil
		} else {
			return strings.joined(separator: separator) + terminator
		}
	}
	
	func collectTags(tags: [String], subfieldList:Set<String>)-> [String]? {
		var collection:[String] = []
		for tag in tags {
            guard let fields = repeatedTags(tag) else { continue }
			for field in fields {
				var subfieldTexts: [String] = []
				for subfield in (field.subfields as! Set<Subfield>).sorted(by: < ) {
					guard let tag = subfield.tag,
						subfieldList.contains(tag),
						let text = subfield.text,
						text.count > 0 else { continue }
					subfieldTexts.append(removeTrailingPunctuation(text))
				}
				collection.append(subfieldTexts.joined(separator: " "))
			}
		}
		return collection.count > 0 ? collection : nil
	}
	
	func calculateTabStops(for font: NSFont)-> [NSTextTab] {
		var tabs: [NSTextTab] = []
		let attributes: [NSAttributedString.Key: Any] = [.font: font]
		var size: CGFloat = 0
		for text in ["000", "00", "$x"] {
			size = (text as NSString).size(withAttributes: attributes).width + size + 8
			tabs.append(NSTextTab(type: .leftTabStopType, location: size))
		}
		return tabs
	}
	
	func links()-> NSMutableAttributedString? {
		let s = NSMutableAttributedString()
        guard let fields = repeatedTags("856") else { return nil }
		for field in fields {
			if let z = field.subfieldText(for: "3") {
				s.append(NSAttributedString(string: z + ": "))
			}
			if let z = field.subfieldText(for: "u"),
				let url = URL.init(string: z) {
				s.append(NSAttributedString.init(string: "\(z)\n",
												attributes: [NSAttributedString.Key.link: url]))
			}
		}
		return s
	}
	
	func linkField(for field: Field)->Field? {
		return nil
		var linkField: Field? = nil
		if let linkEntry = field.subfield(for: "6"),
			let text = linkEntry.text {
			let linkTag = String(text.prefix(3))
			let linkSubfieldTag6 = field.tag! + text.suffix(3)
			if let fields = repeatedTags(linkTag) {
				linkField = fields.first(where: {
					if let text = $0.subfieldText(for: "6") {
						return text.prefix(6) == linkSubfieldTag6 }
					else { return false }
				})
			}
		}
		return linkField
	}
	
	func completeText(for field: Field, _ subfieldTag: String)-> String? {
		guard let text = field.subfieldText(for: subfieldTag) else { return nil }
		var result = removeTrailingPunctuation(text)
		if let link = linkField(for: field),
			let linktext = link.subfieldText(for: subfieldTag) {
			result = removeTrailingPunctuation(linktext) + " " + text
		}
		return result
	}
	
	func flattenField(_ field: Field, with separator: String, ignoring: Set<String> = [])-> String {
		guard let subfields = field.subfields as? Set<Subfield> else { return "" }
		let removePunctuation = separator.count > 0 && separator != " "
		let link = linkField(for: field)
		var u: [String] = []
		var v: [String] = []
		for subfield in subfields.filter({ $0.tag!.count == 1 }).sorted(by: < ) {
            if subfield.tag! < "a" { continue }
			let tag = subfield.tag!
			if ignoring.contains(tag) { continue }
			if let sub = link?.subfield(for: tag),
                let text = sub.text {
				v.append(text)
			}
			if subfield.text != nil {
				var text = subfield.text!
				if removePunctuation {
					text = removeTrailingPunctuation(text)
				}
				u.append(text)
			}
		}
		return v.count == 0
			? u.joined(separator: separator)
			: v.joined(separator: separator) + "\n" + u.joined(separator: separator)
	}
	
	func formatTopic(_ field: Field)-> String {
		var s = ""
		var subdivisions = ""
		for subfield in field.subfields as! Set<Subfield>
			where subfield.tag!.count == 1 && subfield.tag! >= "a" {
			guard let text = subfield.text else { continue }
			if subfield.tag! == "a" {
				s += text
			} else {
				subdivisions += " —\(text)"
			}
		}
		s += subdivisions
		return s
	}
	
	func formatName(_ field: Field)-> String {
		guard let text = field.subfieldText(for: "a") else { return "" }
		var linkText = ""
		if let link = linkField(for: field) {
			let texts = ["a", "c", "q", "d", "e"]
			.compactMap({ link.subfieldText(for: $0) })
			linkText = texts.joined(separator: " ")
		}
		var name = linkText + " " + removeTrailingPunctuation(text)
		if let title = field.subfieldText(for: "c") {
			let parts = name.components(separatedBy: ", ")
			if parts.count > 1 {
				name = "\(parts[0]), \(removeTrailingPunctuation(title)) "
						+ "\(parts[1...].joined(separator: ", "))"
			} else {
				name = "\(title) \(name)"
			}
		}
		var s: String = name
		// Add fuller form
		if let text = field.subfieldText(for: "q"),
			text.count > 0 { s += ", " + removeTrailingPunctuation(text) }
			if let text = field.subfieldText(for: "d"),
			text.count > 0 { s += ", " + removeTrailingPunctuation(text) }
		if let text = field.subfieldText(for: "e"),
			text.count > 0 { s += ", " + removeTrailingPunctuation(text) }
		return s
	}
	
	func prettyPrint(width: CGFloat)-> NSAttributedString {
		// Fonts and tabs
		let notesFont = bodyFont
		let margin = sideMargin(for: width)
		// Styles
		let style = NSMutableParagraphStyle()
		style.lineBreakMode = .byWordWrapping
		style.alignment = .left
		style.headIndent = margin
		style.firstLineHeadIndent = margin
		style.tailIndent = -margin
		style.paragraphSpacing = 6
		style.lineSpacing = 1.1

		let mainEntryStyle = style.mutableCopy() as! NSMutableParagraphStyle		
		let titleStyle = style.mutableCopy() as! NSMutableParagraphStyle
		
		let linkStyle = style.mutableCopy() as! NSMutableParagraphStyle
		linkStyle.paragraphSpacing = 0
		linkStyle.alignment = .left
		
		let unreportedTagsStyle = style.mutableCopy() as! NSMutableParagraphStyle
		unreportedTagsStyle.firstLineHeadIndent = 5
		
		let pretty = NSMutableAttributedString()
		var s: String = ""

		// Start with the author
		var headerIsAuthor: Bool = true
		if let tag = ["100", "110", "111"]
			.first(where: { fieldByTag($0) != nil }) {
			s = formatName(fieldByTag(tag)!)
		}
        if s.count > 0 {
            s += "\n"
		} else if let authors = repeatedTags("700") {
			let text = authors.map { completeText(for: $0, "a")! }
			switch text.count {
			case 1: s = text[0]
			case 2: s = text[0] + " and " + text[1]
			default: s = text[0] + " et. al."
			}
			s += "\n"
		}
		if s.count == 0,
			let field = fieldByTag("245") {
			headerIsAuthor = false
			s = removeTrailingPunctuation(completeText(for: field, "a")!) + "\n"
		}
		pretty.append(NSAttributedString(string: s))
		pretty.addAttributes([NSAttributedString.Key.font: headerFont,
							  NSAttributedString.Key.paragraphStyle: mainEntryStyle],
							 range: NSMakeRange(0, pretty.length))
		s = ""
		// Uniform Title
		if let t = fieldByTag("240") {
			s += " " + flattenField(t, with: " ") + "\n"
		}
		// Title Statement
		if let t = fieldByTag("245") {
			let ignore = Set(arrayLiteral: "a")
			s += flattenField(t, with: " ", ignoring: ignore) + "."
		}
		
		// Unrelated/Analytical titles
		if let text = flattenRepeatedTags("740", terminator: "", separator: ", ") {
			s += " " + text
		}
        
		// series statement
        var series = (flattenRepeatedTags("440", terminator: ". ", separator: " ") ?? "")
        series += (flattenRepeatedTags("490", terminator: ". ", separator: " ") ?? "")
        series += (flattenRepeatedTags("800", terminator: " ", separator: " ") ?? "")
        series += (flattenRepeatedTags("810", terminator: " ", separator: " —") ?? "")
        series += flattenRepeatedTags("830", terminator: " ", separator: " ") ?? ""
        if series.count > 0 {
            s += " " + series
        }
        
        // Edition statement
        if let field = fieldByTag("250"),
            let text = field.subfieldText(for: "a") {
            s += " —" + text
        }
        
        // Publication
        if let field = fieldByTag("260") {
            s += " —" + flattenField(field, with: " ")
        }
        s += "\n"
		
		if headerIsAuthor == true,
			let field = fieldByTag("245"),
			let mainTitle = field.subfieldText(for: "a") {
			if let link = linkField(for: field) {
				let text = flattenField(link, with: " ")
				let title = NSAttributedString(string: text + "\n",
											   attributes: [NSAttributedString.Key.font: bodyFont,
															NSAttributedString.Key.paragraphStyle: titleStyle])
				pretty.append(title)

			}
			let title = NSAttributedString(string: mainTitle + " ",
										   attributes: [NSAttributedString.Key.font: titleFont,
														NSAttributedString.Key.paragraphStyle: titleStyle])
			pretty.append(title)
		}
		var p1 = NSMutableAttributedString(string: s,
										   attributes: [NSAttributedString.Key.font: bodyFont,
														NSAttributedString.Key.paragraphStyle: titleStyle])
		pretty.append(p1)
        
        s = ""
        // physical description
        if let text = flattenRepeatedTags("300", terminator: "\n", separator: " ") {
            s += text
        }
        
        // Annotations
        for tag in ["500", "504", "505"] {
            s += flattenRepeatedTags(tag, terminator: ". ", separator: ". ") ?? ""
        }
        if s.count > 0 && s.last != "\n" {
            s += "\n"
        }
        
        if let notes = repeatedTags("520") {
            var label: String = ""
            
            for note in notes {
                let text = flattenField(note, with: " ")
                if text.count == 0 { continue }
                if let typeText = note.subfieldText(for: ":1"),
                    let type = typeText.first {
					let labels: [Character: String]
						= [" ": "Summary: ", "1": "Review: ", "2": "Scope and Content: ",
								  "3": "Abstract: "]
					label = labels[type] ?? ""
                 }
                s += label + text + "\n"
            }
        }
        
        p1 = NSMutableAttributedString(string: s,
                                       attributes: [NSAttributedString.Key.font: notesFont,
                                                    NSAttributedString.Key.paragraphStyle: style])
        pretty.append(p1)
		
		s = ""
		// Subjects
		var subjects = ["600", "610", "630"].compactMap({ repeatedTags($0) }).joined()
		var texts = subjects.enumerated().map({ "\($0.0 + 1). \(formatName($0.1))" })
		s += texts.joined(separator: "  ")
		if texts.count > 0 { s += "\n" }
		subjects = ["650", "651"].compactMap({ repeatedTags($0) }).joined()
		texts = subjects.enumerated().map({ "\($0.0 + 1). \(formatTopic($0.1))" })
		s += texts.joined(separator: "  ")
		if texts.count > 0 { s += "\n" }
		// Other authors
		let authors = ["700", "710", "730"].compactMap({ repeatedTags($0) }).joined()
		texts = authors.enumerated().map({ RomanNumeral.romanValue($0.0 + 1) + ". " + formatName($0.1) })
		s += texts.joined(separator: "  ")
		if texts.count > 0 { s += "\n" }
		
		// Dewey and other numbers
		var numbers: [String] = []
		numbers.append((collectTags(tags: ["082"], subfieldList: ["a"]) ?? ["---"])
			.joined(separator: " / "))
		// LC Catalog Number
		numbers.append((collectTags(tags: ["050"], subfieldList: ["a", "b"]) ?? ["---"])
				.joined(separator: " / "))
		// LC Control Number
		if let field = fieldByTag("010") {
			numbers.append(flattenField(field, with: " "))
		} else {
			numbers.append("---")
		}
		// ISBN number
		numbers.append((collectTags(tags: ["020"], subfieldList: ["a"]) ?? ["---"])
			.joined(separator: " / "))

		s += numbers.joined(separator: ", ")
		p1 = NSMutableAttributedString(string: s,
									   attributes: [NSAttributedString.Key.font: bodyFont,
													NSAttributedString.Key.paragraphStyle: style])
		pretty.append(p1)
		
		// Links
		if let links = self.links() {
			pretty.append(NSAttributedString(string: "\n"))
			links.addAttributes([NSAttributedString.Key.font: notesFont,
								 NSAttributedString.Key.paragraphStyle: linkStyle],
								range: NSMakeRange(0, links.length))
			pretty.append(links)
		}

		return pretty
	}
}
