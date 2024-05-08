//
//  Marc8 To UTF8.m
//  CodeTable
//
//  Created by Timothy Larkin on 6/6/09.
//  Copyright 2009 Abstract Tools. All rights reserved.
//

#import "Marc8ToUTF8.h"
//#import "CompileCodeTable.h"
typedef struct Code Code;

const UInt16  SINGLE_G0_A	= 0x28;
const UInt16  SINGLE_G0_B	= 0x2C;
const UInt16  MULTI_G0_A		= 0x24;
const UInt16  MULTI_G0_B		= 0x242C;

const UInt16  ESCAPE		= 0x1B;

const UInt16  SINGLE_G1_A	= 0x29;
const UInt16  SINGLE_G1_B	= 0x2D;
const UInt16  MULTI_G1_A		= 0x2429;
const UInt16  MULTI_G1_B		= 0x242D;

const UInt16  GREEK_SYMBOLS	= 0x67;
const UInt16  SUBSCRIPTS		= 0x62;
const UInt16  SUPERSCRIPTS	= 0x70;
const UInt16  ASCII_DEFAULT	= 0x73;

const UInt16  BASIC_ARABIC	= 0x33;
const UInt16  EXTENDED_ARABIC	= 0x34;
const UInt16  BASIC_LATIN	= 0x42;
const UInt16  EXTENDED_LATIN	= 0x45;
const UInt16  CJK		= 0x31;
const UInt16  BASIC_CYRILLIC	= 0x4E;
const UInt16  EXTENDED_CYRILLIC	= 0x51;
const UInt16  BASIC_GREEK	= 0x53;
const UInt16  BASIC_HEBREW	= 0x32;

UInt8 DEFAULT_G0 = 0x73,
	DEFAULT_G1 = 0x45;

UInt8 G0, G1;

void reset_charsets()
{
	G0 = DEFAULT_G0;
	G1 = DEFAULT_G1;
}

NSInteger process_escape(NSString *marc8, NSInteger left, NSInteger right)
{
	// this stuff is kind of scary ... for an explanation of what is
	// going on here check out the MARC-8 specs at LC.
	// http://lcweb.loc.gov/marc/specifications/speccharmarc8.html

	// first char needs to be an escape or else this isn't an escape sequence
	if ([marc8 characterAtIndex:left] != ESCAPE) {
		return left;
	}

	// if we don't have at least one character after the escape
	// then this can't be a character escape sequence
	if (left + 1 > right) {
		return left;
	}

	// pull off the first escape
	char esc_char_1 = [marc8 characterAtIndex:left + 1];
	
	// the first method of escaping to small character sets
	if ( esc_char_1 == GREEK_SYMBOLS
		|| esc_char_1 == SUBSCRIPTS
		|| esc_char_1 == SUPERSCRIPTS
		|| esc_char_1 == ASCII_DEFAULT)
	{
		G0 = esc_char_1;
		return left+2;
	}

	// the second more complicated method of escaping to bigger charsets
	if (left + 2 > right) {
		return left;
	}
	char esc_char_2 = [marc8 characterAtIndex:left + 2];
	UInt16 esc_chars = esc_char_1 * 256 + esc_char_2;

	if (esc_char_1 == SINGLE_G0_A
		|| esc_char_1 == SINGLE_G0_B)
	{
		G0 = esc_char_2;
		return left+3;
	}

	else if (esc_char_1 == SINGLE_G1_A
		|| esc_char_1 == SINGLE_G1_B)
	{
		G1 = esc_char_2;
		return left+3;
	}

	else if ( esc_char_1 == MULTI_G0_A ) {
		G0 = esc_char_2;
		return left+3;
	}

	else if (esc_chars == MULTI_G0_B
		&& (left+3 < right))
	{
		G0 = [marc8 characterAtIndex:left + 3];
		return left+4;
	}

	else if ((esc_chars == MULTI_G1_A || esc_chars == MULTI_G1_B)
			 && (left + 3 < right))
	{
		G1 = [marc8 characterAtIndex:left + 3];
		return left+4;
	}

	// we should never get here
	NSCAssert(NO, @"seem to have fallen through in process_escape()");
	return left;
}

NSMutableDictionary *codeDictionary;
NSArray *tagsUsed;

CodePtr getCode(NSString *key)
{
	if ([key isEqualToString:@"02BE"]) {
		// March 2005 code revision
		key = @"02BC";
	}
	
	id thing = [codeDictionary objectForKey:key];
	if (!thing) {
        return nil;
	}
	CodePtr code;
	if ([thing isKindOfClass:[NSArray class]]) {
		code = malloc(sizeof(Code));
		[[thing objectAtIndex:0] getBytes:code length:sizeof(Code)];
		code->name = (__bridge void *)([thing objectAtIndex:1]);
		[codeDictionary setValue:[NSValue valueWithPointer:code] forKey:key];
	} else {
		code = [thing pointerValue];
	}
	return code;
}


CodePtr lookup_by_marc8(UInt8 charset, NSString *chunk)
{
    if(charset == ASCII_DEFAULT) {
        charset = BASIC_LATIN;
    }
    return getCode([NSString stringWithFormat:@"%x:%@", charset, chunk]);
}

CodePtr lookup_by_utf8(NSString *s)
{
	UInt16 c = [s characterAtIndex:0];
    CodePtr code = getCode([NSString stringWithFormat:@"%04X", c]);
    if (G0 != 0 && code->charset != G0 && code->isCombining == true) {
        CodePtr code1 = getCode([NSString stringWithFormat:@"%04X+", c]);
        if (code1 != nil && code1->charset == G0) {
            code = code1;
        }
    }
    return code;
}

NSString *decodeDiacritics(NSString *s)
{
	return Marc8ToUTF8(s);
}

NSString *encodeDiacritics(NSString *s)
{
	if ([s canBeConvertedToEncoding:NSASCIIStringEncoding]) {
		return s;
	}
	return UTF8ToMarc8(s);
}

NSString *decodeHTMLEntities(NSString *string) {
    NSMutableString *text = [NSMutableString stringWithString:string];
    NSString *pattern = @"&#x((([0-9a-f]){2})+);";
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        NSRange hit = [match rangeAtIndex:1];
        NSString *s = [text substringWithRange:hit];
        NSScanner *scanner = [NSScanner scannerWithString:s];
        unsigned int value;
        [scanner scanHexInt:&value];
        NSString *c = [NSString stringWithFormat:@"%C", (unsigned short)value];
        [text replaceCharactersInRange:[match range] withString:c];
    }
    return text;
}

 void makeCodeDictionary() {
	tagsUsed = [NSArray arrayWithObjects:@"010", @"050", @"100", @"110", @"111", @"130",
				@"240", @"245", @"250", @"260", @"300",
				@"440", @"490", @"500", @"504", @"505", @"520", @"600", @"610", @"630", @"650", @"651",
				@"700", @"710", @"730", @"740",
				@"800", @"810", @"830", @"082", @"856", @"900", nil];
	
	NSBundle *myBundle = [NSBundle mainBundle];
	if (!codeDictionary) {
		NSString *path = [myBundle pathForResource:@"codetables" ofType:@"dictionary"];
		codeDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	}

}

int count = 0;

NSString *Marc8ToUTF8(NSString* marc8)
{
    reset_charsets();
	
	if (codeDictionary == nil) {
		makeCodeDictionary();
	}
	
	NSMutableString *utf8 = [NSMutableString string];
    NSInteger index = 0;
    NSInteger length = [marc8 length];
	NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	UInt8 charset = 0;
    NSMutableString *hexChunk;
	NSString *chunk;
	Code *code;
	NSMutableString *combining = [NSMutableString string];
	while (index < length)
	{
	// whitespace, line feeds and carriage returns just get added on unmolested
		if ([whiteSpace characterIsMember:[marc8 characterAtIndex:index]])
		{
			[utf8 appendString:@" "];
			index ++;
			continue;
		}
		
	// look for any escape sequences
		NSInteger new_index = process_escape(marc8, index, length);
		if (new_index > index)
		{
			index = new_index;
			continue;
		}
		
		
		BOOL found = NO;
        NSArray *charsets = @[@(G0), @(G1)];
		for(NSNumber *charsetNumber in charsets) {
			charset = [charsetNumber charValue];
			// cjk characters are a string of three chars
			int char_size = charset == CJK ? 3 : 1;
            // extract the next code point to examine
            chunk = [marc8 substringWithRange:NSMakeRange(index, char_size)];
            NSString *hexChunk2 = [NSString stringWithFormat:@"%02X", [chunk characterAtIndex:0]];
			
            hexChunk = [NSMutableString string];
            const char *cPtr;
            if ([chunk canBeConvertedToEncoding:NSMacOSRomanStringEncoding]) {
                cPtr = [chunk cStringUsingEncoding:NSMacOSRomanStringEncoding];
            } else {
                cPtr = [chunk cStringUsingEncoding:NSUTF8StringEncoding];
            }
            for (int i = 0; i < strlen(cPtr); i++) {
                unsigned char c = cPtr[i];
                [hexChunk appendString:[NSString stringWithFormat:@"%02X", c]];
            }
			
            /*
             This is a weird but necessary hack. It's difficult to get the right mapping from character
             to hex code which satisfies Marc8. The Mac encoding followed by a byte by byte copy to
             cPtr usually works to produced a hex code that matches the correct entry in the code
             dictionary. However, the Mac encoding sometimes produces a character with the eighth
             bit set. For instance, 'ã' produces 8something, which does not find a match. In fact,
             there don't seem to be any correct entries that have hex MSD == '8'. In these cases,
             use the UTF8 encoding.
                In other cases, the UTF8 encoding produces the wrong match. When chunk == 'Æ',
             Unicode produces hex 'C6'. Marc produces 'Inverted Exclamation Mark' from 'C6'
             in charset E. For the same character, cPtr == '\xae'. This produces the code for
             'ALIF / MODIFIER LETTER APOSTROPHE', which is the correct answer.
                In the way of consolation, the official utility, yaz-iconv, fails to correctly
             decode "Chos dbyiÁns rin po che&#x02be;i mdzod ces bya ba&#x02be;i &#x02be;grel pa."
            */
			// look up the character to see if it's in our mapping
			code = lookup_by_marc8(charset, hexChunk);
            if (!code) {
                code = lookup_by_marc8(charset, hexChunk2);
            }
			// try the next character set if no mapping was found
			if (!code) {
				continue;
			}
			found = YES;

			// gobble up all combining characters for appending later
			// this is necessary because combinging characters precede
			// the character they modifiy in MARC-8, whereas they follow
			// the character they modify in UTF-8.
			if (code->isCombining) {
				unichar tmp;
				fill((UInt8*)&tmp, [NSString stringWithFormat:@"%02X%02X",
									code->ucs[1], code->ucs[0]]);
				[combining appendString:[NSString stringWithFormat:@"%C", tmp]];
			}
			else {
				unichar tmp;
				fill((UInt8*)&tmp, [NSString stringWithFormat:@"%02X%02X",
									code->ucs[1], code->ucs[0]]);
				[utf8 appendString:[NSString stringWithFormat:@"%C%@",
									tmp, combining]];
				combining = [NSMutableString string];
			}

			index += char_size;
			break;
		}
		if (!found) {
//            NSLog(@"%d, Couldn't find code for %02X:%@ while decoding %@",
//				  count, charset, hexChunk, marc8);
			return marc8;
		}
		count += 1;
	}

	// return the utf8
	reset_charsets();
    return decodeHTMLEntities([utf8 precomposedStringWithCanonicalMapping]);
}

NSString*chop(NSMutableString* s) {
	NSInteger n = [s length];
	if (n == 0) {
		return @"";
	} else {
		NSString *tmp = [s substringFromIndex:n - 1];
		[s deleteCharactersInRange:NSMakeRange(n - 1, 1)];
		return tmp;
	}
}

CodePage default_charset_group(CodePtr code)
//		Returns G0 or G1 indicating where the character is typicalling used
//		in the MARC-8 environment.
{
	UInt16 charset = code->charset;
	
	if (charset == ASCII_DEFAULT
		|| charset == GREEK_SYMBOLS
		|| charset == SUBSCRIPTS
		|| charset == SUPERSCRIPTS
		|| charset == BASIC_LATIN
		|| charset == BASIC_ARABIC
		|| charset == BASIC_CYRILLIC
		|| charset == BASIC_GREEK
		|| charset == BASIC_HEBREW
		|| charset == CJK)
		return G0;
	else
		return G1;
}

// Returns an escape sequence to move to the Code from another marc-8 character set.
NSString* get_escape(CodePage charset)
{

	if (charset == ASCII_DEFAULT
		|| charset == GREEK_SYMBOLS
		|| charset == SUBSCRIPTS
		|| charset == SUPERSCRIPTS) {
		return [NSString stringWithFormat:@"%c%c", ESCAPE, charset];
	}

	if (charset == ASCII_DEFAULT
		|| charset == BASIC_LATIN
		|| charset == BASIC_ARABIC
		|| charset == BASIC_CYRILLIC
		|| charset == BASIC_GREEK
		|| charset == BASIC_HEBREW) {
		return [NSString stringWithFormat:@"%c%c%c", ESCAPE, SINGLE_G0_A, charset];
	}

	if (charset == EXTENDED_ARABIC
		|| charset == EXTENDED_LATIN
		|| charset == EXTENDED_CYRILLIC) {
		return [NSString stringWithFormat:@"%c%c%c", ESCAPE, SINGLE_G1_A, charset];
	}

	if (charset == CJK) {
		return [NSString stringWithFormat:@"%c%c%c", ESCAPE, MULTI_G0_A, CJK];
	}
	
	NSCAssert(NO, @"Couldn't get escape sequence for character set.");
	
	return nil;
}

void appendMarc(NSMutableString *s, CodePtr code)
{
	for (int i = 0; i < 3; i++) {
		if (code->marc[i] != 0) {
			[s appendString:[NSString stringWithFormat:@"%c", code->marc[i]]];
		}
	}
}

NSString* UTF8ToMarc8(NSString* utf8)
{
	if (codeDictionary == nil) {
		makeCodeDictionary();
	}
	
    reset_charsets();
	// decompose combined characters
    utf8 = [utf8 decomposedStringWithCanonicalMapping];
	
    NSInteger len = [utf8 length];
    NSMutableString *marc8 = [NSMutableString string];
    for (int i=0; i<len; i++)
    {
        NSString *slice = [utf8 substringWithRange:NSMakeRange(i, 1)];
		
// spaces are copied from utf8 into marc8
        if ([slice isEqualToString:@" "])
        {
            [marc8 appendString:@" "];
            continue;
        }
		
// try to find the code point in our mapping table
        CodePtr code = lookup_by_utf8(slice);
		
        if (! code)
        {
			NSCAssert(code, @"No mapping found in utf8");
        }
		
	// if it's a combining character move it around
		if (code->isCombining)
		{
			NSString *prev = chop(marc8);
			appendMarc(marc8, code);
			[marc8 appendString:prev];
			continue;
		}

		// look to see if we need to escape to a new G0 charset
		UInt8 charset = code->charset;

		if (default_charset_group(code) == G0 && G0 != charset)
		{
			if (G0 == ASCII_DEFAULT && charset == BASIC_LATIN)
			{
				// don't bother escaping, they're functionally the same
			}
			else
			{
				NSString *escape = get_escape(charset);
				[marc8 appendString:escape];
				G0 = charset;
			}
		}

		// look to see if we need to escape to a new G1 charset
		else if (default_charset_group(code) == G1
				 && G1 != charset)
		{
			NSString *escape = get_escape(charset);
			[marc8 appendString:escape];
			G1 = charset;
		}

		appendMarc(marc8, code);
	}

	// escape back to default G0 if necessary
	if (G0 != DEFAULT_G0)
	{
		if (DEFAULT_G0 == ASCII_DEFAULT) {
			[marc8 appendString:[NSString stringWithFormat:@"%c%c",
								 ESCAPE, ASCII_DEFAULT]];
		}
		else if (DEFAULT_G0 == CJK) {
			[marc8 appendString:[NSString stringWithFormat:@"%c%c%c",
								 ESCAPE, MULTI_G0_A, CJK]];
		}
		else {
			[marc8 appendString:[NSString stringWithFormat:@"%c%c%c",
								 ESCAPE, SINGLE_G0_A, DEFAULT_G0]];
		}
	}

	// escape back to default G1 if necessary
	if (G1 != DEFAULT_G1)
	{
		if (DEFAULT_G1 == CJK) {
			[marc8 appendString:[NSString stringWithFormat:@"%c%C%c",
								 ESCAPE, MULTI_G1_A, DEFAULT_G1]];
		}
		else {
			[marc8 appendString:[NSString stringWithFormat:@"%c%c%c",
									ESCAPE, SINGLE_G1_A, DEFAULT_G1]];
		}
	}

	return marc8;
}

