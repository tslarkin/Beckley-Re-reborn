/*
 *  Constants.h
 *  CodeTable
 *
 *  Created by Timothy Larkin on 6/6/09.
 *  Copyright 2009 Abstract Tools. All rights reserved.
 *
 */

#import "Cocoa/Cocoa.h"

typedef NSString *NSStringPtr;

struct Code {
	UInt8 marc[3];
	UInt8 ucs[2];
	UInt8 utf8[3];
	void *name;
	UInt8 alt[2];
	UInt8 altutf8[3];
	UInt8 charset;
	BOOL isCombining;
};
#pragma mark Constants
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
extern UInt8 DEFAULT_G0, DEFAULT_G1;

extern UInt8 G0, G1;

extern const UInt16  SINGLE_G0_A;
extern const UInt16  SINGLE_G0_B;
extern const UInt16  MULTI_G0_A;
extern const UInt16  MULTI_G0_B;

extern const UInt16  ESCAPE;

extern const UInt16  SINGLE_G1_A;
extern const UInt16  SINGLE_G1_B;
extern const UInt16  MULTI_G1_A;
extern const UInt16  MULTI_G1_B;

extern const UInt16  GREEK_SYMBOLS;
extern const UInt16  SUBSCRIPTS;
extern const UInt16  SUPERSCRIPTS;
extern const UInt16  ASCII_DEFAULT;

extern const UInt16  BASIC_ARABIC;
extern const UInt16  EXTENDED_ARABIC;
extern const UInt16  BASIC_LATIN;
extern const UInt16  EXTENDED_LATIN;
extern const UInt16  CJK;
extern const UInt16  BASIC_CYRILLIC;
extern const UInt16  EXTENDED_CYRILLIC;
extern const UInt16  BASIC_GREEK;
extern const UInt16  BASIC_HEBREW;


typedef enum {
	g0, g1
} CodePage;

