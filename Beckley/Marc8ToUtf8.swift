//
//  Marc8ToUTF8.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/27/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Foundation

func process_escape(_ bytes: Data, left: Int, right: Int)-> Int {
	// this stuff is kind of scary ... for an explanation of what is
	// going on here check out the MARC-8 specs at LC.
	// http://lcweb.loc.gov/marc/specifications/speccharmarc8.html
	
	// first char needs to be an escape or else this isn't an escape sequence
	if bytes[left] != ESCAPE { return left }
	
	// if we don't have at least one character after the escape
	// then this can't be a character escape sequence
	if left + 1 > right { return left }
	
	// pull off the first escape
	let esc_char_1 = UInt16(bytes[left + 1])
	
	// the first method of escaping to small character sets
	if ([GREEK_SYMBOLS, SUBSCRIPTS, SUPERSCRIPTS, ASCII_DEFAULT] as Set<UInt16>)
		.contains(esc_char_1) {
		G0 = UInt8(esc_char_1)
		return left + 2
	}
	
	if left + 2 > right { return left }
	
	// the second more complicated method of escaping to bigger charsets
	let esc_char_2 = bytes[left + 2]
	let esc_chars = esc_char_1 * 256 + UInt16(esc_char_2)
	if esc_char_1 == SINGLE_G0_A || esc_char_1 == SINGLE_G0_B {
		G0 = esc_char_2
		return left + 3
	} else if esc_char_1 == SINGLE_G1_A || esc_char_1 == SINGLE_G1_B {
		G1 = esc_char_2
		return left + 3
	}
	else if esc_char_1 == MULTI_G0_A {
		G0 = esc_char_2
		return left + 3
	} else if esc_chars == MULTI_G0_B && left + 3 < right {
		G0 = bytes[left + 3]
		return left + 4
	} else if (esc_chars == MULTI_G1_A || esc_chars == MULTI_G1_B)
		&& left + 3 < right {
		G1 = bytes[left + 3]
		return left + 4
	}
	// we should never get here
	assert(false, "Failure to get escape code.")
	return 0
}

func _marc8ToUTF8(_ bytes: Data)-> String {
	
	G0 = DEFAULT_G0
	G1 = DEFAULT_G1
	if codeDictionary == nil {
		makeCodeDictionary()
	}
	
	var utf8: String = ""
	var index = 0
	let length = bytes.count
	let whitespace = NSCharacterSet.whitespacesAndNewlines
	var combining = ""
	var hexChunk = ""
	while index < length {
		
		// whitespace, line feeds and carriage returns just get added on unmolested
		if whitespace.contains(UnicodeScalar(bytes[index])){
			utf8 += " "
			index += 1
			continue
		}
		
		// look for any escape sequences
		let new_index = process_escape(bytes, left: index, right: length)
		if new_index > index {
			index = new_index
			continue
		}
		var chunk: Data
		var map: UInt8
		var char_size: Int
		if G0 == CJK {
			char_size = 3
			chunk = bytes[index..<index + char_size]
			map = G0
		} else {
			char_size = 1
			chunk = bytes[index..<index + char_size]
			map = chunk.first! < 128 ? G0 : G1
		}
		
		hexChunk = chunk.reduce("", { $0 + String(format: "%02X", $1) })
		let codePtr = lookup_by_marc8(map, hexChunk)
		if codePtr == nil {
			if ![0x81, 0x82, 0x83].contains(chunk.first) {
				utf8 += "�"
			}
		} else {
			let code = codePtr!.pointee
			// gobble up all combining characters for appending later
			// this is necessary because combinging characters precede
			// the character they modifiy in MARC-8, whereas they follow
			// the character they modify in UTF-8.
			let char = Unicode.Scalar(UInt16(code.ucs.0) * 256 + UInt16(code.ucs.1))
			assert(char != nil)
			if let char = char {
				if code.isCombining.boolValue {
					combining += String(char)
				} else {
					utf8 += String(char) + combining
					combining = ""
				}
			}
		}
		index += char_size
	}
	return decodeHTMLEntities(utf8.precomposedStringWithCanonicalMapping)
}

func decodeDiacritics(_ s: String)-> String {
//	let string = _marc8ToUTF8(s.precomposedStringWithCanonicalMapping.data(using: .utf8)!)
//	return string
	return s
}
