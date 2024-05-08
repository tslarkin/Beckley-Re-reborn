/*
 *  Utilities.m
 *  CodeTable
 *
 *  Created by Timothy Larkin on 6/6/09.
 *  Copyright 2009 Abstract Tools. All rights reserved.
 *
 */

#import "Utilities.h"
//#import "Constants.h"
//#import "Marc8ToUTF8.h"
NSString* charsetName(UInt16 charset)
{
    if (charset == GREEK_SYMBOLS) return @"GREEK_SYMBOLS";
    if (charset == SUBSCRIPTS) return @"SUBSCRIPTS";
    if (charset == SUPERSCRIPTS) return @"SUPERSCRIPTS";
    if (charset == ASCII_DEFAULT) return @"ASCII_DEFAULT";
    if (charset == BASIC_ARABIC) return @"BASIC_ARABIC";
    if (charset == EXTENDED_ARABIC) return @"EXTENDED_ARABIC";
    if (charset == BASIC_LATIN) return @"BASIC_LATIN";
    if (charset == EXTENDED_LATIN) return @"EXTENDED_LATIN";
    if (charset == CJK) return @"CJK";
    if (charset == BASIC_CYRILLIC) return @"BASIC_CYRILLIC";
    if (charset == EXTENDED_CYRILLIC) return @"EXTENDED_CYRILLIC";
    if (charset == BASIC_GREEK) return @"BASIC_GREEK";
    if (charset == BASIC_HEBREW) return @"BASIC_HEBREW";
	return nil;
}


NSString* charset_name(CodePtr code)
{
	return charsetName(code->charset);
}

void fill(UInt8 *buffer, NSString* hex)
{
	NSInteger n = [hex length];
	const char *source = [hex cStringUsingEncoding:NSASCIIStringEncoding];
	const char *p = source;
	UInt8 *bp = buffer;
	for (int i = 0; i < n; i+= 2) {
		UInt8 x = 0;
		for (int j = 0; j < 2; j++) {
			if (*p <= '9') {
				x = x * 16 + *p - '0';
			} else {
				x = x * 16 + (*p - 'A' + 10);
			}
			p++;
		}
		*bp++ = x;
	}
}

