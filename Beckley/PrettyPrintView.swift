//
//  PrettyPrintView.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/25/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

class PrettyPrintView: NSTextView {
	

	// Whenever the view is drawn, we need to recalculate the margin, in case
	// the width of the view has changed.
    override func draw(_ dirtyRect: NSRect) {
		let margin = sideMargin(for: frame.width)
		if textStorage != nil && textStorage!.length > 0 {
			textStorage!
				.enumerateAttribute(NSAttributedString.Key.paragraphStyle,
									in: NSRange(0..<textStorage!.length),
									options: NSAttributedString.EnumerationOptions(),
									using: { (value, range, stop) in
										if let value = value as? NSMutableParagraphStyle {
											value.headIndent = margin
											value.firstLineHeadIndent = margin
											value.tailIndent = -margin
										}
				})
		}
		
        super.draw(dirtyRect)
    }
    
}
