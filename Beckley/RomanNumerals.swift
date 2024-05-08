//
//  RomanNumerals.swift
//  helloWorld
//
//  Created by Adrian Bilescu on 5/17/16.
//  Copyright © 2016 exercism.io. All rights reserved.
//
// Revised to compile under Swift 5.0 by Tim Larkin

import Foundation


struct RomanNumeral {
	let number: Int
	
	init(_ value: Int) {
		self.number = value
	}
	
	static let romanNumbers = [(1, "I"), (4, "IV"), (5, "V"), (9, "IX"), (10, "X"), (40, "XL"), (50, "L"), (90, "XC"), (100, "C"), (400, "CD"), (500, "D"), (900, "CM"), (1000, "M")]
	
	static func romanNumbers(range: ClosedRange<Int>) -> [(Int, String)] {
		return romanNumbers.filter {
			range.contains($0.0)
		}
	}
	
	static func romanValue(_ value: Int) -> String {
		if value == 0 {
			return ""
		}
		
		for (arabic, roman) in self.romanNumbers(range: 1...value).reversed() {
			if value - arabic >= 0 {
				return roman + romanValue(value - arabic)
			}
		}
		
		return ""
	}
	
}

extension String {
	
	init(_ romanNumeral: RomanNumeral) {
		self = RomanNumeral.romanValue(romanNumeral.number)
	}
}
