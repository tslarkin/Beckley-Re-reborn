//
//  MessageView.swift
//  Beckley
//
//  Created by Timothy Larkin on 4/11/19.
//  Copyright © 2019 Abstract Tools. All rights reserved.
//

import Cocoa

class MessageView: NSView {
	static let attributes: [NSAttributedString.Key: Any]
		= [NSAttributedString.Key.font: NSFont(name: "LucidaGrande", size: 20)!,
		   NSAttributedString.Key.foregroundColor: NSColor.white]
	
	var message: String = ""
	var messageWidth: CGFloat = 0.0
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
		let path = NSBezierPath.init(roundedRect: dirtyRect, xRadius: 20.0, yRadius: 20.0)
		NSColor.gray.set()
		path.fill()
        // Drawing code here.
		
		let point = NSMakePoint(NSMidX(dirtyRect) - messageWidth / 2.0, NSMidY(dirtyRect) - 10)
		(message as NSString).draw(at: point, withAttributes: MessageView.attributes)
    }
    
}
