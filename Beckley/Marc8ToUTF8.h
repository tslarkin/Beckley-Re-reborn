//
//  Marc8 To UTF8.h
//  CodeTable
//
//  Created by Timothy Larkin on 6/6/09.
//  Copyright 2009 Abstract Tools. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
//#include "Utilities.h"
#import "Utilities.h"

NSString *Marc8ToUTF8(NSString* marc8String);
NSString* UTF8ToMarc8(NSString* utf8);
//NSString *decodeDiacritics(NSString *s);
NSString *encodeDiacritics(NSString *sin);
NSString *decodeHTMLEntities(NSString *string);
CodePtr lookup_by_marc8(UInt8 charset, NSString *chunk);
void makeCodeDictionary(void);
CodePtr getCode(NSString *key);
extern NSMutableDictionary *codeDictionary;

//const UInt16  SINGLE_G0_A	= 0x28;
//const UInt16  SINGLE_G0_B	= 0x2C;
//const UInt16  MULTI_G0_A		= 0x24;
//const UInt16  MULTI_G0_B		= 0x242C;
//
//const UInt16  ESCAPE		= 0x1B;
//
//const UInt16  SINGLE_G1_A	= 0x29;
//const UInt16  SINGLE_G1_B	= 0x2D;
//const UInt16  MULTI_G1_A		= 0x2429;
//const UInt16  MULTI_G1_B		= 0x242D;
//
//const UInt16  GREEK_SYMBOLS	= 0x67;
//const UInt16  SUBSCRIPTS		= 0x62;
//const UInt16  SUPERSCRIPTS	= 0x70;
//const UInt16  ASCII_DEFAULT	= 0x73;
//
//const UInt16  BASIC_ARABIC	= 0x33;
//const UInt16  EXTENDED_ARABIC	= 0x34;
//const UInt16  BASIC_LATIN	= 0x42;
//const UInt16  EXTENDED_LATIN	= 0x45;
//const UInt16  CJK		= 0x31;
//const UInt16  BASIC_CYRILLIC	= 0x4E;
//const UInt16  EXTENDED_CYRILLIC	= 0x51;
//const UInt16  BASIC_GREEK	= 0x53;
//const UInt16  BASIC_HEBREW	= 0x32;
//
//UInt8 DEFAULT_G0 = 0x73,
//DEFAULT_G1 = 0x45;
//
//UInt8 G0, G1;
