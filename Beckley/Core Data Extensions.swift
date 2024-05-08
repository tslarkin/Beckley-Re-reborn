//
//  Marc+TreeNode.swift
//  Beckley
//
//  Created by Timothy Larkin on 3/25/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa
//import CharacterConversion

func isIndicator(_ subfield: Subfield)-> Bool {
	guard let tag = subfield.tag else { return false }
	return tag.prefix(1) == ":"
}

extension Subfield: Comparable {
	public static func < (lhs: Subfield, rhs: Subfield) -> Bool {
		let lhsTag = lhs.tag!
		let rhsTag = rhs.tag!
		if lhsTag.count == rhsTag.count {
			return lhsTag < rhsTag
		} else {
			if lhsTag.count > rhsTag.count {
				return true
			} else {
				return false
			}
		}
	}
	
	
	var isLeaf: Bool {
		return true
	}
}

extension Field
{
	var isLeaf: Bool {
		return false
	}
	
	func subfields(for tag: String)-> [Subfield]? {
		let subs = subfields as! Set<Subfield>
		let matches = subs.filter({ $0.tag == tag })
		return matches.count > 0 ? Array(matches) : nil
	}
	
	func subfield(for tag: String)-> Subfield? {
		let s = subfields(for: tag)
		return s == nil ? nil : s![0]
	}
	
	func subfieldText(for tag: String)-> String? {
		guard let s = subfields(for: tag) else { return nil }
		let texts = s.compactMap({ $0.text })
		return texts.joined(separator: ", ")
	}
	
	func indicator(for tag: String)-> Subfield? {
		if let subfields = subfields as? Set<Subfield> {
			return subfields.first(where: { $0.tag! == tag })
		} else {
			return nil
		}
	}
}

extension Marc
{

}
