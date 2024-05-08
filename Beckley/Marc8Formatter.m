//
//  Marc8Formatter.m
//  Beckley
//
//  Created by Timothy Larkin on 6/9/09.
//  Copyright 2009 Abstract Tools. All rights reserved.
//

#import "Marc8Formatter.h"
#import "Marc8ToUTF8.h"

@implementation Marc8Formatter

-(NSString*)stringForObjectValue:(id)thing
{
	NSAssert([thing isKindOfClass:[NSString class]],
			 @"Bad argument to Marc8Formatter.");
	NSString *tmp = decodeDiacritics(thing);
	return tmp;
}

- (BOOL)getObjectValue:(id *)anObject 
			 forString:(NSString *)string 
	  errorDescription:(NSString **)error
{
	NSString *tmp = encodeDiacritics(string);
	*anObject = tmp;
	return YES;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject 
								 withDefaultAttributes:(NSDictionary *)attributes
{
	NSAttributedString *tmp 
	= [[NSAttributedString alloc] initWithString:[self stringForObjectValue:anObject]
															   attributes:attributes];
	return tmp;
}
@end
