//
//  Marc.m
//  Library
//
//  Created by Timothy Larkin on Thu Aug 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "Marc.h"
#include <yaz/yaz-iconv.h>
#include <yaz/marcdisp.h>
#import "ReferenceSource.h"
#import "Field.h"
#import "Subfield.h"
#import "AppController.h"
#import "Century.h"
#import "BrowserEntry.h"
#import "Creator.h"
#import "Subject.h"
#import "Coordinator.h"
//#import "Marc8 Conversion.h"
#import "Marc8 To UTF8.h"

struct yaz_iconv_struct {
    int my_errno;
    int init_flag;
    size_t (*init_handle)(yaz_iconv_t cd, unsigned char *inbuf,
                          size_t inbytesleft, size_t *no_read);
    unsigned long (*read_handle)(yaz_iconv_t cd, unsigned char *inbuf,
                                 size_t inbytesleft, size_t *no_read);
    size_t (*write_handle)(yaz_iconv_t cd, unsigned long x,
                           char **outbuf, size_t *outbytesleft);
#if HAVE_ICONV_H
    iconv_t iconv_cd;
#endif
};

const int leaderLength = 24;
const int directoryLength = 12;
const int dataBaseAddressOffset = 12;
const int dataBaseAddressSize = 5;
const int recordLengthOffset = 0;
const int recordLengthSize = 5;
const int tagSize = 3;
const int lengthSize = 4;
const int offsetSize = 5;

const char fieldSeparator = '\x1e';
const char recordSeparator = '\x1d';
NSString *subfieldSeparator = @"$";

char *safeCat(char *dst, char *append)
{
	unsigned long len1 = strlen(dst), len2 = strlen(append);
	dst = reallocf(dst, len1 + len2 + 1);
	strcat(dst, append);
	return dst;
}

int HexToDec1(const char c)
{
    if (c >= '0' && c <= '9')
        return c - '0';
    else
        return c - 'A' + 10;
}

int HexToDec2(const char *p)
{
    return HexToDec1(*p) * 16 + HexToDec1(*(p + 1));
}

int InsertUTF8(char *outbuf, const char *inbuf)
{
    int n = 0;
    while (*inbuf) {
        *outbuf++ = HexToDec2(inbuf);
        inbuf += 2;
        n += 1;
    }
    return n;
}


NSArray *tagsUsed;

// return a fixed format number from a usmarc record.
unsigned getNumber(const char *buf, unsigned length)
{
    unsigned number = 0;
    unsigned i;
    for (i = 0; i < length; i++) {
        number = number * 10 + *buf - '0';
        buf++;
    }
    return number;
}

/*

// return the subfields object of a usmarc tag
NSMutableArray* getSubfields(NSMutableDictionary* tag)
{
    return [tag objectForKey:@"subfields"];
}

*/
NSString* getSubfield(Field *tag, NSString* subfieldId)
{
    Subfield *subfield = [tag subfieldForTag:subfieldId];
    return [subfield diacriticalText];
}

NSString* flattenField(Field *field, NSString *separator)
{
    NSEnumerator *e = [field subfieldEnumerator];
    NSMutableArray *u = [NSMutableArray array];
    Subfield *s;
	Field *linkField = nil;
	Subfield *linkEntry = [field subfieldForTag:@"6"];
	if (linkEntry) {
		NSString *link = [[linkEntry text] substringToIndex:3];
		linkField = [[field marc] fieldByTag:[link intValue]];
	}
	BOOL removePunctuation = [separator length] > 0 && ![separator isEqualToString:@" "];
    while (s = [e nextObject]) {
		char tag = [[s tag] characterAtIndex:0];
		if (tag <= '9') {
			continue;
		}
		if (linkField) {
			Subfield *s1 = [linkField subfieldForTag:[s tag]];
			if (s1) {
				s = s1;
			}
		}
		NSString *dt = [s diacriticalText];
		if (removePunctuation) {
			dt = removeTrailingPunctuation(dt);
		}
		[u addObject:dt];
	}
    return [u componentsJoinedByString:separator];
}

NSMutableString* formatTopic(Field *field)
{
    NSMutableString *s = [NSMutableString string];
    NSEnumerator *e = [field subfieldEnumerator];
    NSMutableString *subdivisions = [NSMutableString string];
    Subfield *t;
    while (t = [e nextObject]) {
        if ([t matchesTag:@"a"] && [t text])
            [s appendString:decodeDiacritics([t text])];
        else {
            [subdivisions appendFormat:@" --%@", decodeDiacritics([t text])];
        }
    }
    if ([subdivisions length] > 0) [s appendString:subdivisions];
    return s;
}

NSMutableString* formatName(Field *field)
{
    NSMutableString *s;

    NSString *name = decodeDiacritics([[field subfieldForTag:@"a"] text]);
    if (!name) {
        return [NSMutableString stringWithString:@""];
    }
    NSString *date = [[field subfieldForTag:@"d"] text];
	NSString *title = [[field subfieldForTag:@"c"] text];
    NSString *fullerForm = [[field subfieldForTag:@"q"] diacriticalText];
    NSString *role = [[field subfieldForTag:@"e"] text];

	if (title) {
		NSArray *tmp = [name componentsSeparatedByString:@", "];
		if ([tmp count] > 1) {
			name = [NSString stringWithFormat:@"%@, %@ %@",
											   [tmp objectAtIndex:0],
											   removeTrailingPunctuation(title),
											   [[tmp subarrayWithRange:NSMakeRange(1, [tmp count] - 1)]
				componentsJoinedByString:@", "]];
		} else {
			name = [NSString stringWithFormat:@"%@ %@", title, name];
		}
	}
    s = [NSMutableString stringWithString:name];
    if (fullerForm)
        [s appendFormat:@" %@", fullerForm];
    if (date)
        [s appendFormat:@" %@", date];
    if (role)
        [s appendFormat:@" %@", role];
    
    NSEnumerator *e = [field subfieldEnumerator];
    Subfield *t;
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"acdqe"];
    while (t = [e nextObject]) {
        if ([[t tag] rangeOfCharacterFromSet:set].location == NSNotFound
			&& [[t tag] intValue] > 9) {
            [s appendFormat:@" --%@", [t diacriticalText]];
        }
    }
    return s;
}

NSString* LCNumberFromUSMarc(const char* usmarc)
{
    NSString *leader = [[NSString alloc] initWithBytes:usmarc length:leaderLength encoding:NSMacOSRomanStringEncoding];
	[leader autorelease];

    // the record size & database offset
    unsigned size = [[leader substringWithRange:NSMakeRange(recordLengthOffset, recordLengthSize)] intValue];
    
    // parse the fields.  Trim off the record terminator and the last field terminator
	NSString *s = [[NSString alloc] initWithBytes:usmarc length:size - 2 encoding:NSMacOSRomanStringEncoding];
	[s autorelease];
    NSArray *fields = [[s substringFromIndex:leaderLength] componentsSeparatedByString:@"\x1e"];
    NSEnumerator *e = [fields objectEnumerator];
    
    NSString *tagList = [e nextObject];
    NSString *field;
    unsigned i = 0;
    
    for(field = [e nextObject]; field; field=[e nextObject], i+= directoryLength) {
        NSString *tag = [tagList substringWithRange:NSMakeRange(i, tagSize)];
        if ([tag intValue] != 10) continue;
        // this field contains 1 or more subfields, which become records for the subfield dictionary
        NSMutableArray *subfields = [NSMutableArray arrayWithArray:[field componentsSeparatedByString:@"\x1f"]];
        
        NSEnumerator *f = [subfields objectEnumerator];
        NSString *subKey, *sub;
        while (sub = [f nextObject]) {
            subKey = [sub substringToIndex:1];
            if ([subKey isEqualToString:@"a"])
              return [sub substringFromIndex:1];
        }
    }
    return nil; 
}


NSMutableDictionary* usmarcToDictionary(const char* usmarc, NSManagedObjectContext *context, BOOL isOxford)
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    
	NSString *leader = [[NSString alloc] initWithBytes:usmarc length:leaderLength encoding:NSMacOSRomanStringEncoding];
    [d setObject:leader forKey:@"leader"];
	[leader release];
    
    // the record size & database offset
    unsigned size = [[leader substringWithRange:NSMakeRange(recordLengthOffset, recordLengthSize)] intValue];
    
    // parse the fields.  Trim off the record terminator and the last field terminator
    if (usmarc[size - 1] == recordSeparator)
        size -= 2;
	NSString *s = [[NSString alloc] initWithBytes:usmarc length:size encoding:NSUTF8StringEncoding];
    if (!s) {
        s = [[NSString alloc] initWithBytes:usmarc length:size encoding:NSMacOSRomanStringEncoding];
    }
    [s autorelease];
    if (isOxford) {
        s = UTF8ToMarc8(s);
        [s retain];
    }
    NSArray *fields = [[s substringFromIndex:leaderLength] componentsSeparatedByString:@"\x1e"];
    NSEnumerator *e = [fields objectEnumerator];
    
    NSString *tagList = [e nextObject];
    NSString *field;
    unsigned i = 0;
    NSMutableArray *tagsDict = [NSMutableArray array];
    [d setObject:tagsDict forKey:@"tags"];
    
    for(field = [e nextObject]; field; field=[e nextObject], i+= directoryLength) {
		if (i + tagSize > [tagList length]) {
			NSLog(@"More fields than tags in %s", usmarc);
			break;
		}
        NSString *tag = [tagList substringWithRange:NSMakeRange(i, tagSize)];
		if ([tag intValue] >= 900) {
			continue;
		}
        Field *tagDict = [NSEntityDescription insertNewObjectForEntityForName:@"Field"
                                                          inManagedObjectContext:context];
        
        [tagDict setTag:tag];
        [tagsDict addObject:tagDict];


        // this field contains 1 or more subfields, which become records for the subfield dictionary
        NSMutableArray *subfields = [NSMutableArray arrayWithArray:[field componentsSeparatedByString:@"\x1f"]];
        
        NSEnumerator *f = [subfields objectEnumerator];
        NSString *sub;
        
        // If the tag is >= 10, then the first subfield
        // contains the indicators.
        if ([tag intValue] >= 10 && [tag intValue] < 900) {
            id next = [f nextObject];
			if (!([next isKindOfClass:[NSString class]] && [next length] == 2))
					 next = @"  ";
            [tagDict addIndicators];
            [tagDict setIndicatorStrings:next];
        }
        
        // traverse the subFields
        NSString *subKey;
//        index = [[tagDict valueForKey:@"subfields"] count];
        while (sub = [f nextObject]) {
            // separate the subkey and the subfield value
            if ([tag intValue] < 10 || [tag intValue] >= 900) {
                subKey = @"?";
            } else {
                subKey = [sub substringToIndex:1];
                sub = [sub substringFromIndex:1];
            }
            Subfield *subf = [NSEntityDescription insertNewObjectForEntityForName:@"Subfield"
                                          inManagedObjectContext:context];
            [subf setTag:subKey];
            [subf setText:sub];
            //[subf setIndex:[NSNumber numberWithShort:index++]];
            [tagDict addSubfieldsObject:subf];
        }
    //[tagDict description];
    }
    return d; 
}
    
@implementation Marc

@synthesize shortDewey, isUTF8;

extern NSMutableDictionary *codeDictionary;

+(void)initialize
{
    tagsUsed = [NSArray arrayWithObjects:@"010", @"050", @"100", @"110", @"111", @"130", 
        @"240", @"245", @"250", @"260", @"300",
        @"440", @"490", @"500", @"504", @"505", @"520", @"600", @"610", @"630", @"650", @"651", 
        @"700", @"710", @"730", @"740",
        @"800", @"810", @"830", @"082", @"856", @"900", nil];
    [tagsUsed retain];

    NSBundle *myBundle = [NSBundle mainBundle];
    if (!codeDictionary) {
        NSString *path = [myBundle pathForResource:@"codetables" ofType:@"dictionary"];
        codeDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        [codeDictionary retain];
    }
    
}

-(void)allEntities:(NSMutableArray*)entities
{
	[entities addObject:self];
	Field *field;
	for (field in [self valueForKey:@"fields"]) {
		[field allEntities:entities];
	}
}

-(void)initializeWithUsmarcDictionary:(NSDictionary*)d
{
    NSString *lead = [d objectForKey:@"leader"];
     if (!lead) {
        lead = @"00000cam  2200000uu 4500";
     }
    [self setLeader:lead];
    [self setValue:[NSSet setWithArray:[d objectForKey:@"tags"]] forKey:@"fields"];
    [self updateFromTags];
}

-(void)initializeWithDefaultValues
{
    [self setLeader:@"00000cam  2200000uu 4500"];
	return;
	
}


- (void)addLoansObject:(Loan *)value 
{    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"loans" 
				withSetMutation:NSKeyValueUnionSetMutation 
				   usingObjects:changedObjects];
    [[self primitiveValueForKey: @"loans"] addObject: value];
    [self didChangeValueForKey:@"loans" 
			   withSetMutation:NSKeyValueUnionSetMutation 
				  usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeLoansObject:(Loan *)value 
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"loans" 
				withSetMutation:NSKeyValueMinusSetMutation 
				   usingObjects:changedObjects];
    [[self primitiveValueForKey: @"loans"] removeObject: value];
    [self didChangeValueForKey:@"loans" 
			   withSetMutation:NSKeyValueMinusSetMutation 
				  usingObjects:changedObjects];
    [changedObjects release];
}



//=========================================================== 
//  dictionary 
//=========================================================== 
- (NSDictionary *)dictionary
{
    return dictionary; 
}
- (void)setDictionary:(NSDictionary *)aDictionary
{
    if (dictionary != aDictionary) {
        [aDictionary retain];
        [dictionary release];
        dictionary = aDictionary;
    }
}

- (NSString *)leader 
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"leader"];
    tmpValue = [self primitiveValueForKey: @"leader"];
    [self didAccessValueForKey: @"leader"];
    
    return tmpValue;
}

- (void)setLeader:(NSString *)value 
{
    [self willChangeValueForKey: @"leader"];
    [self setPrimitiveValue: value forKey: @"leader"];
    [self didChangeValueForKey: @"leader"];
}

- (BOOL)validateLeader: (id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

- (NSString *)title 
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"title"];
    tmpValue = [self primitiveValueForKey: @"title"];
    [self didAccessValueForKey: @"title"];
    
    return tmpValue;
}

- (void)setTitle:(NSString *)value 
{
    [self willChangeValueForKey: @"title"];
    [self setPrimitiveValue: value forKey: @"title"];
    [self didChangeValueForKey: @"title"];
}

- (BOOL)validateTitle: (id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

- (NSString *)LCNumber 
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"LCNumber"];
    tmpValue = [self primitiveValueForKey: @"LCNumber"];
    [self didAccessValueForKey: @"LCNumber"];
    
    return tmpValue;
}

- (void)setLCNumber:(NSString *)value 
{
    [self willChangeValueForKey: @"LCNumber"];
    [self setPrimitiveValue: value forKey: @"LCNumber"];
    [self didChangeValueForKey: @"LCNumber"];
}

- (BOOL)validateLCNumber: (id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

- (NSString *)sortTitle 
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"sortTitle"];
    tmpValue = [self primitiveValueForKey: @"sortTitle"];
    [self didAccessValueForKey: @"sortTitle"];
    
    return tmpValue;
}

- (void)setSortTitle:(NSString *)value 
{
    [self willChangeValueForKey: @"sortTitle"];
    [self setPrimitiveValue: value forKey: @"sortTitle"];
    [self didChangeValueForKey: @"sortTitle"];
}

- (BOOL)validateSortTitle: (id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

- (NSString *)author 
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"author"];
    tmpValue = [self primitiveValueForKey: @"author"];
    [self didAccessValueForKey: @"author"];
    
    return tmpValue;
}

- (void)setAuthor:(NSString *)value 
{
    [self willChangeValueForKey: @"author"];
    [self setPrimitiveValue: value forKey: @"author"];
    [self didChangeValueForKey: @"author"];
}

- (BOOL)validateAuthor: (id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

- (NSData *)rendered 
{
    NSData * tmpValue;
    [self willAccessValueForKey: @"rendered"];
    tmpValue = [self primitiveValueForKey: @"rendered"];
	if(tmpValue == nil) {
		NSAttributedString *ppd = [self prettyPrint];
		NSData *data = [NSArchiver archivedDataWithRootObject:ppd];
		[self setPrimitiveValue: data forKey: @"rendered"];
		tmpValue = data;
	}
    [self didAccessValueForKey: @"rendered"];
    
    return tmpValue;
}

- (void)setRendered:(NSData *)value 
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSUndoManager *undo = [moc undoManager];
	[moc processPendingChanges];
	[undo disableUndoRegistration];
    [self willChangeValueForKey: @"rendered"];
    [self setPrimitiveValue: value forKey: @"rendered"];
    [self didChangeValueForKey: @"rendered"];
	[moc processPendingChanges];
	[undo enableUndoRegistration];
}

- (BOOL)validateRendered: (id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

-(void)fixup82
{
    Field *f82 = [self fieldByTag:82];
    if (!f82) {
        return;
    }
    NSSet *subfields = [f82 valueForKey:@"subfields"];
    if ([subfields count] == 1) {
        [f82 addIndicators];
        [f82 setIndicator2:@"4"];
    }
}

- (NSString *)dcn 
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"dcn"];
    tmpValue = [self primitiveValueForKey: @"dcn"];
    [self didAccessValueForKey: @"dcn"];
    
    return tmpValue;
}

- (void)setDcn:(NSString *)value 
{
    [self willChangeValueForKey: @"dcn"];
    [self setPrimitiveValue: value forKey: @"dcn"];
    [self didChangeValueForKey: @"dcn"];
}

- (BOOL)validateDcn: (id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

- (NSString*)deweyCentury
{
	NSString *s = [self dcn];
	char c;
	// if this is really a Dewey number, then get the updated century.
	if (s 
		&& ([s length] > 2)
		&& (c = [s characterAtIndex:0]) 
		&& (c >= '0')
		&& (c <= '9')) {
		s = [NSString stringWithFormat:@"%c00", c];
	}
	return s;
}

- (void)addFieldsObject:(Field *)value 
{    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:@"fields" 
				withSetMutation:NSKeyValueUnionSetMutation 
				   usingObjects:changedObjects];
    
    [[self primitiveValueForKey: @"fields"] addObject: value];
    
    [self didChangeValueForKey:@"fields" 
			   withSetMutation:NSKeyValueUnionSetMutation 
				  usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)removeFieldsObject:(Field *)value 
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:@"fields" 
				withSetMutation:NSKeyValueMinusSetMutation 
				   usingObjects:changedObjects];
    
    [[self primitiveValueForKey: @"fields"] removeObject: value];
    
    [self didChangeValueForKey:@"fields" 
			   withSetMutation:NSKeyValueMinusSetMutation 
				  usingObjects:changedObjects];
    
    [changedObjects release];
}


- (void)addSubjectsObject:(NSManagedObject *)value 
{    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"subjects" 
				withSetMutation:NSKeyValueUnionSetMutation 
				   usingObjects:changedObjects];
    [[self primitiveValueForKey: @"subjects"] addObject: value];
    [self didChangeValueForKey:@"subjects" 
			   withSetMutation:NSKeyValueUnionSetMutation 
				  usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeSubjectsObject:(NSManagedObject *)value 
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"subjects" 
				withSetMutation:NSKeyValueMinusSetMutation 
				   usingObjects:changedObjects];
    [[self primitiveValueForKey: @"subjects"] removeObject: value];
    [self didChangeValueForKey:@"subjects" 
			   withSetMutation:NSKeyValueMinusSetMutation 
				  usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeSubject:(Subject*)subject
{
	[subject removeMarcsObject:self];
	NSMutableSet *set = [subject mutableSetValueForKey:@"creators"];
	NSEnumerator *e = [set objectEnumerator];
	Creator *creator;
	while(creator = [e nextObject]) {
		if(![creator hasPathToObject:subject throughKey:@"subjects"]) {
			[set removeObject:creator];
		}
	}
		
	set = [subject mutableSetValueForKey:@"centuries"];
	e = [set objectEnumerator];
	Century *century;
	while(century = [e nextObject]) {
		if(![century hasPathToObject:subject throughKey:@"subjects"]) {
			[set removeObject:century];
		}
	}
	
}

- (void)addSubject:(Subject*)subject
{
	[subject addMarcsObject:self];
	[[subject mutableSetValueForKey:@"creators"]
		unionSet:[self valueForKey:@"creators"]];
	[subject addCenturiesObject:[self century]];
}

- (void)addCreatorsObject:(NSManagedObject *)value 
{    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"creators" 
				withSetMutation:NSKeyValueUnionSetMutation 
				   usingObjects:changedObjects];
    [[self primitiveValueForKey: @"creators"] addObject: value];
    [self didChangeValueForKey:@"creators" 
			   withSetMutation:NSKeyValueUnionSetMutation 
				  usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeCreatorsObject:(NSManagedObject *)value 
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"creators" 
				withSetMutation:NSKeyValueMinusSetMutation 
				   usingObjects:changedObjects];
    [[self primitiveValueForKey: @"creators"] removeObject: value];
    [self didChangeValueForKey:@"creators" 
			   withSetMutation:NSKeyValueMinusSetMutation 
				  usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeCreator:(Creator*)creator
{
	[creator removeMarcsObject:self];
	NSMutableSet *set = [creator mutableSetValueForKey:@"subjects"];
	NSEnumerator *e = [set objectEnumerator];
	Subject *subject;
	while(subject = [e nextObject]) {
		if(![creator hasPathToObject:subject throughKey:@"subjects"]) {
			[set removeObject:subject];
		}
	}
}

- (void)addCreator:(Creator*)creator
{
	[creator addMarcsObject:self];
	[[creator mutableSetValueForKey:@"subjects"]
		unionSet:[self valueForKey:@"subjects"]];
}

NSString *removeTrailingPunctuation(NSString *t)
{
    if (t == nil)
        return t;
    NSMutableString *s = [NSMutableString stringWithString:t];
    BOOL truncate = NO;
    NSRange foc = [s rangeOfString:@" [from old catalog]"];
    if (foc.location != NSNotFound)
        [s deleteCharactersInRange:foc];
    if ([s length] == 0)
        return @"";
    NSUInteger n = [s length] - 1;
    if ([s characterAtIndex:n] == '/' || [s characterAtIndex:n] == ':') {
        truncate = YES;
    }
    else
        if (([s characterAtIndex:n] == '.' && [s characterAtIndex:n - 2] != ' ')
            || [s characterAtIndex:n] == ';' 
            || [s characterAtIndex:n] == ',')
            truncate = YES;
    if (truncate)
        s = [NSMutableString stringWithString:[s substringToIndex:[s length] - 1]];
    //NSAssert(s != nil, @"removeTrailingPunctuation produces a null string");
    return [NSString stringWithString:s];
}

- (void)updateTitle
{
    Field *titleField = [self fieldByTag:245];
	NSString *oldTitle = [self title];
    NSString *title = [titleField subfieldTextForTag:@"a"];
    if (title == nil)
		return;
//        title = @"No Title";
    else 
        title = decodeDiacritics(removeTrailingPunctuation(title));
	if (![title isEqualToString:oldTitle]) {
		[self setTitle:title];
	}
    int nonFilingChars = [[[titleField indicator2] text] characterAtIndex:0] - '0';
    if (nonFilingChars > 0 && nonFilingChars < [title length]) {
        [self setSortTitle:[title substringFromIndex:nonFilingChars]];
    }
    else [self setSortTitle:[NSString stringWithString:title]];	
}

- (void)updateAuthor
{
	NSString *oldAuthor = [self author];
	NSString *author = [[self fieldByTag:100] subfieldTextForTag:@"a"];
    if (!author)
        author = [[self fieldByTag:110] subfieldTextForTag:@"a"];
    if (!author)
        author = [[self fieldByTag:111] subfieldTextForTag:@"a"];
    if (!author)
        author = [[self fieldByTag:130] subfieldTextForTag:@"a"];
    NSAssert(author == nil || [author isKindOfClass:[NSString class]], @"Not a string.");
	
    if ([author length] == 0) {
        NSString *e;
        NSArray *subAuthors = [self repeatedTags:700];
        if (!subAuthors)
            subAuthors = [self repeatedTags:710];
        if (!subAuthors)
            subAuthors = [self repeatedTags:711];
        if ([subAuthors count] == 0)
			author = nil;
//            author = @"Anonymous";
        else if ([subAuthors count] == 1) {
            author = [[subAuthors objectAtIndex:0] subfieldTextForTag:@"a"];
//            n = [author length] - 1;
            e = [[subAuthors objectAtIndex:0] subfieldTextForTag:@"e"];
            if (e) {
                author = [NSString stringWithFormat:@"%@ %@", author, e];
            }
            else {
                author = removeTrailingPunctuation(author);
            }
        } else {
            author = removeTrailingPunctuation([[subAuthors objectAtIndex:0] subfieldTextForTag:@"a"]);
            author = [NSString stringWithFormat:@"%@ et al.", author];
        }
    } else {
        author = removeTrailingPunctuation(author);
    }
	author = decodeDiacritics(author);
	if (![author isEqualToString:oldAuthor]) {
		[self setAuthor:author];	
	}
}

-(void)setTitleAndAuthor
{
	[self updateTitle];
    [self updateAuthor];
}

-(NSString*)extractDCN
{
    Field *t82 = [self fieldByTag:82];
    if (!t82) return @"";
    NSArray *dewey = [t82 subfieldsForTag:@"a"];
    Subfield *subf;
    NSString *dc = @"Unclassified";
    NSEnumerator *e = [dewey objectEnumerator];
    while (subf = [e nextObject]) {
        NSString *s = [subf text];
		if ([s isEqualToString:@"[Fic]"]) {
			dc = s;
			break;
		}
        char c;
        if ([s length] > 2 && (c = [s characterAtIndex:0]) && c >= '0' && c <= '9') {
            dc = s; 
            break;
        }
    }
    NSMutableString *dc1 = [NSMutableString stringWithString:dc];
    [dc1 replaceOccurrencesOfString:@"/" withString:@""
                            options:NSLiteralSearch
                              range:NSMakeRange(0, [dc1 length])];
    BOOL isNumber;
    float z;
    isNumber = [[NSScanner scannerWithString:dc1] scanFloat:&z];
    if (isNumber && z >= 294.3 && z < 294.4) {
        dc = [NSString stringWithString:dc1];
    }
    return dc;
}

- (void)updateLCCN
{
    Field *lc = [self fieldByTag:10];
    NSString *slcn = [lc subfieldTextForTag:@"a"];
    if (slcn == nil)
        slcn = @"";
    [self setLCNumber:slcn];	
}

- (void)updateDCN
{
    NSString *dcn = [self extractDCN];
    [self setDcn:dcn];	
	[self setShortDewey:nil];
}

-(void)updateFromTags
{
    [self setTitleAndAuthor];
    
	[self updateLCCN];
	[self updateDCN];
    [self setRendered:nil];
    
}


-(BOOL)flattenRepeatedTags:(unsigned)tag toString:(NSMutableString*)s 
            withTerminator:(NSString*)term
             withSeparator:(NSString*)separator
{
    NSArray *notes = [self repeatedTags:tag];
    NSMutableArray *tmpArray = [NSMutableArray array];
	if ([notes count] > 0) {
		for (Field *t in notes) {
			[tmpArray addObject:flattenField(t, separator)];
		}
		[s appendString:[tmpArray componentsJoinedByString:separator]];
		[s appendString:term];
        return YES;
	}
    else return NO;
}


-(NSMutableArray*)collectTags:(NSArray*)tags withSubfields:(NSCharacterSet*)subfieldList
{
    NSArray *fields;
    Subfield *subfield;
    NSString *tag;
    Field *field;
    NSMutableArray *subfieldText, *collection = [NSMutableArray array];
    NSEnumerator *et, *ef, *es;
    
    et = [tags objectEnumerator];
    while (tag = [et nextObject]) {
        fields = [self repeatedTags:[tag intValue]];
        ef = [fields objectEnumerator];
        while (field = [ef nextObject]) {
            es = [field sortedSubfieldEnumerator];
            subfieldText = [NSMutableArray array];
            while (subfield = [es nextObject]) {
                NSString *marc8 = [subfield marc8Text];
                if ([marc8 length] == 0) {
                    continue;
                }
                NSAssert(marc8 != nil, @"Subfield text is nil");
                if (!subfieldList 
					|| [[subfield tag] rangeOfCharacterFromSet:subfieldList].location != NSNotFound) {
                    [subfieldText addObject:removeTrailingPunctuation(marc8)];
                }
            }
            [collection addObject:[subfieldText componentsJoinedByString:@"/"]];
        }
    }
    return collection;
}


-(NSMutableAttributedString*)links
{
    NSArray *linkArray = [self repeatedTags:856];
    NSMutableAttributedString *s = [[[NSMutableAttributedString alloc] init] autorelease];
    NSAttributedString *y;
    if ([linkArray count] == 0)
        return s;
    else {
        Field *t;
        NSEnumerator *e = [linkArray objectEnumerator];
        NSString *z;
        while (t = [e nextObject]) {
            z = [t subfieldTextForTag:@"3"];
            if (z)
                [s appendAttributedString:[[[NSAttributedString alloc] initWithString:z] autorelease]];
            z = [t subfieldTextForTag:@"u"];
            if (z) {
                NSURL *url = [NSURL URLWithString:z];
				if (url) {
					y = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@\n", z]
														attributes:[NSDictionary dictionaryWithObject:url
																							   forKey:NSLinkAttributeName]];
					[s appendAttributedString:y];
					[y release];
				}
            }
        }
    }
    return s;
    
}

-(NSAttributedString*)prettyPrint
{
    return [self prettyPrintShowingUnusedTags:NO
                               withHeaderFont:[[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Lucida Grande" size:12]
                                                                                 toHaveTrait:NSBoldFontMask]
                                     bodyFont:[NSFont fontWithName:@"Lucida Grande" size:11]
                                    notesFont:[NSFont fontWithName:@"Lucida Grande" size:11]];
}

-(NSMutableArray*)calculateTabStops:(NSFont*)font
{
    NSMutableArray *tabs = [NSMutableArray array];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    NSTextTab *tab;
    float size;
    size = [@"000" sizeWithAttributes:attributes].width + 8;
    tab = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:size];
    [tabs addObject:tab];
    [tab release];
    size = [@"00" sizeWithAttributes:attributes].width + size + 8;
    tab = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:size];
    [tabs addObject:tab];
    [tab release];
    size = [@"$x" sizeWithAttributes:attributes].width + size + 8;
    tab = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:size];
    [tabs addObject:tab];
    [tab release];
    return tabs;
}

-(NSAttributedString*)prettyPrintShowingUnusedTags:(BOOL)showUnusedTags
                                           withHeaderFont:(NSFont*)headerFont
                                                 bodyFont:(NSFont*)bodyFont
                                                notesFont:(NSFont*)notesFont
{
//    if ([self rendered]) return [self rendered];
    
    NSMutableArray *tabStops = [self calculateTabStops:notesFont];

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style autorelease];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    [style setAlignment:NSTextAlignmentLeft];
    [style setHeadIndent:5.0];
    [style setParagraphSpacing:3.0];
    [style setLineSpacing:1];
    [style setFirstLineHeadIndent:5.0];
    NSMutableParagraphStyle *mainEntryStyle = [[style mutableCopy] autorelease];
    [mainEntryStyle setFirstLineHeadIndent:5.0];
    [mainEntryStyle setHeadIndent:20.0];
    NSMutableParagraphStyle *titleStyle = [[style mutableCopy] autorelease];
    [titleStyle setHeadIndent:20.0];
    [titleStyle setFirstLineHeadIndent:20.0];
    //[titleStyle setAlignment:NSJustifiedTextAlignment];
    NSMutableParagraphStyle *linkStyle = [[style mutableCopy] autorelease];
    [linkStyle setParagraphSpacing:0.0];
    [linkStyle setAlignment:NSTextAlignmentLeft];
    NSMutableParagraphStyle *unreportedTagsStyle = [[linkStyle mutableCopy] autorelease];
    [unreportedTagsStyle setFirstLineHeadIndent:5.0];
    [unreportedTagsStyle setTabStops:tabStops];
    [unreportedTagsStyle setHeadIndent:[[tabStops objectAtIndex:1] location] + 15];
    //[style setAlignment:NSJustifiedTextAlignment];

//	char nbsps[3] = {'\302', '\240', 0};
//	NSString *nbsp = [NSString stringWithCString:nbsps encoding:NSUTF8StringEncoding];
	
    NSMutableString *z;
    NSMutableString *s = [NSMutableString string], *mz, *unreportedTags = nil;
    NSMutableAttributedString *links = [self links];
    NSMutableAttributedString *pretty, *p1;
    NSUInteger attributedLength;
	Field *t = [self fieldByTag:245];
	
	if ([[[t indicator1] text] intValue] == 1) {
		t = [self fieldByTag:100];
		if (!t)
			t = [self fieldByTag:110];
		 if (!t)
		 t = [self fieldByTag:111];
		 if (!t)
		 t = [self fieldByTag:700];
		if (!t)
			t = [self fieldByTag:710];
		if (t) {
			[s appendFormat:@"%@\n", formatName(t)];
		} 
	}

     else {
		 t = [self fieldByTag:130];
		 if (!t) {
			 t = [self fieldByTag:245];
		 }
        [s appendFormat:@"%@\n", removeTrailingPunctuation([[t subfieldForTag:@"a"] diacriticalText])];
    }

    attributedLength = [s length];
    pretty = [[[NSMutableAttributedString alloc] initWithString:s] autorelease];
    [pretty addAttribute:NSFontAttributeName 
                   value:headerFont 
                   range:NSMakeRange(0, [pretty length])];
    [pretty addAttribute:NSParagraphStyleAttributeName 
                   value:mainEntryStyle 
                   range:NSMakeRange(0, [pretty length])];
    
    // uniform title
    t = [self fieldByTag:240];
    s = [NSMutableString string];
    if (t)
        [s appendFormat:@"%@\n", flattenField(t, @" ")];
    
    // Title statement
    [s appendString:flattenField([self fieldByTag:245], @" ")];

    // Unrelated/Analytical titles
    mz = [NSMutableString string];
    if ([self flattenRepeatedTags:740 toString:mz withTerminator:@"" withSeparator:@", "]) {
        [s appendFormat:@" [%@]", mz];
    }

    // series statement
    mz = [NSMutableString string];
    [self flattenRepeatedTags:440 toString:mz withTerminator:@". " withSeparator:@" "];
    [self flattenRepeatedTags:490 toString:mz withTerminator:@". " withSeparator:@" "];
    [self flattenRepeatedTags:800 toString:mz withTerminator:@" " withSeparator:@" "];
    [self flattenRepeatedTags:810 toString:mz withTerminator:@" " withSeparator:@" --"];
    [self flattenRepeatedTags:830 toString:mz withTerminator:@" " withSeparator:@" "];
    if ([mz length] > 0) {
        [s appendFormat:@" %@", mz];
    }
    
    // edition statement
    t = [self fieldByTag:250];
    if (t)
        [s appendFormat:@" -- %@", [t subfieldTextForTag:@"a"]];
    
    // publication
    t = [self fieldByTag:260];
    if (t)
        [s appendFormat:@" -- %@", flattenField(t, @" ")];

    [s appendString:@"\n"];
    
        
    p1 = [[[NSMutableAttributedString alloc] initWithString:s] autorelease];
    [p1 addAttribute:NSFontAttributeName 
                   value:bodyFont 
                   range:NSMakeRange(0, [p1 length])];
    [p1 addAttribute:NSParagraphStyleAttributeName 
                   value:titleStyle 
                   range:NSMakeRange(0, [p1 length])];
    [pretty appendAttributedString:p1];
    attributedLength += [s length];
    s = [NSMutableString string];
        
    
    // physical description
    [self flattenRepeatedTags:300 toString:s withTerminator:@"\n" withSeparator:@" "];
    
    
    // Annotations
    [self flattenRepeatedTags:500 toString:s withTerminator:@". " withSeparator:@". "];
    [self flattenRepeatedTags:504 toString:s withTerminator:@". " withSeparator:@". "];
    [self flattenRepeatedTags:505 toString:s withTerminator:@". " withSeparator:@". "];
    if ([s length] > 0 && [s characterAtIndex:[s length] - 1] != '\n')
        [s appendString:@"\n"];
    
    NSMutableArray *notes = [NSMutableArray arrayWithArray:[self repeatedTags:520]];
    NSEnumerator *e;
    if ([notes count] > 0) {
        NSMutableString *ss;
        e = [notes objectEnumerator];
        while (t = [e nextObject]) {
            char type = [[[t indicator1] text] characterAtIndex:0];
            ss = [NSMutableString stringWithString:flattenField(t, @" ")];
            switch (type) {
                case ' ': 
                    [ss insertString:@"Summary: " atIndex:0];
                    break;
                case '1': 
                    [ss insertString:@"Review: " atIndex:0];
                    break;
                case '2': 
                    [ss insertString:@"Scope and content: " atIndex:0];
                    break;
                case '3': 
                    [ss insertString:@"Abstract: " atIndex:0];
                    break;
            }
            [s appendFormat:@"%@\n", ss];
        }        
    }
    p1 = [[[NSMutableAttributedString alloc] initWithString:s] autorelease];
    [p1 addAttribute:NSFontAttributeName 
                   value:notesFont 
                   range:NSMakeRange(0, [p1 length])];
    [p1 addAttribute:NSParagraphStyleAttributeName 
                   value:style 
                   range:NSMakeRange(0, [p1 length])];
    [pretty appendAttributedString:p1];
    attributedLength += [s length];
    s = [NSMutableString string];
    
    // subjects
    BOOL startPar = NO;
    NSMutableArray *ss = [NSMutableArray arrayWithArray:[self repeatedTags:600]];
    [ss addObjectsFromArray:[self repeatedTags:610]];
    [ss addObjectsFromArray:[self repeatedTags:630]];
    unsigned n = 1;
    if ([ss count] > 0) {
        startPar = YES;
        e = [ss objectEnumerator];
        [s appendFormat:@"%d. %@", n++, formatName([e nextObject])];
        while (t = [e nextObject])
            [s appendFormat:@"   %c. %@", n++, formatName(t)];
    }
    
    ss = [NSMutableArray arrayWithArray:[self repeatedTags:650]];
    [ss addObjectsFromArray:[self repeatedTags:651]];
    if ([ss count] > 0) {
        e = [ss objectEnumerator];
        if (!startPar)
            [s appendFormat:@"%d. %@", n++, formatTopic([e nextObject])];
        startPar = YES;
        while (t = [e nextObject])
            [s appendFormat:@"   %d. %@", n++, formatTopic(t)];
    }
    
    // other authors
    if (startPar)
        [s appendString:@"\n"];
    startPar = NO;
    notes = [NSMutableArray arrayWithArray:[self repeatedTags:700]];
    [notes addObjectsFromArray:[self repeatedTags:710]];
    [notes addObjectsFromArray:[self repeatedTags:730]];
    n = 0;
    NSString *numerals[] = {@"I", @"II", @"III", @"IV", @"V", @"VI", @"VII", @"VIII", @"IX", @"X", @"??"};
    if ([notes count] > 0) {
        e = [notes objectEnumerator];
        if (!startPar)
            [s appendFormat:@"%@. %@", numerals[n++], formatName([e nextObject])];
        startPar = YES;
        while (t = [e nextObject]) {
            if (n > 10) n = 10;
            [s appendFormat:@"  %@. %@", numerals[n++], formatName(t)];
        }
    }
    
    if (startPar)
        [s appendString:@"\n"];
    
    // Dewey & other numbers
    ss = [NSMutableArray array];
	if([self dcn])
		[ss addObject:[self dcn]];
    
    t = [self fieldByTag:50];   // lc catalog number
    if (t) {
        [ss addObject:[NSString stringWithFormat:@"%@", flattenField(t, [NSString stringWithFormat:@" "])]];
    } else {
        [ss addObject:@"---"];
    }
    
    t = [self fieldByTag:10];   // lc control number
    if (t) {
        mz = [NSMutableString stringWithString:[flattenField(t, @" ") 
                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        if (([mz length] == 0) 
            || ([mz characterAtIndex:0] == 'L')
            || (((NSRange)[mz rangeOfString:@"."]).location != NSNotFound)
            || ([mz length] == 6)) 
        {
            [[self managedObjectContext] deleteObject:t];
            [ss addObject:@"---"];
        } else {
            [ss addObject:[NSString stringWithFormat:@"%@", mz]];
        }
    } else {
        [ss addObject:@"---"];
    }
    
    t = [self fieldByTag:20];   // ISBN catalog number
    if (t) {
        NSString *tmp = [t subfieldTextForTag:@"a"];
        if (tmp) {
            mz = [NSMutableString stringWithString:tmp];
            [mz replaceOccurrencesOfString:@"(alk. paper)"
                                withString:@""
                                   options:NSBackwardsSearch
                                     range:NSMakeRange(0, [mz length])];
            [ss addObject:[NSString stringWithFormat:@"%@", mz]];
        }
    } else {
        [ss addObject:@"---"];
    }
    
    [s appendFormat:@"%@", [ss componentsJoinedByString:@", "]];
    p1 = [[[NSMutableAttributedString alloc] initWithString:s] autorelease];
    [p1 addAttribute:NSFontAttributeName 
                   value:bodyFont 
                   range:NSMakeRange(0, [p1 length])];
    [p1 addAttribute:NSParagraphStyleAttributeName 
               value:style 
               range:NSMakeRange(0, [p1 length])];
    [pretty appendAttributedString:p1];
//    attributedLength += [s length];
    s = [NSMutableString string];
    
    
    t = [self fieldByTag:900];   // on loan
    if (t) {
        NSString *who = [t subfieldTextForTag:@"a"], *when = [t subfieldTextForTag:@"d"];
        if (who && when)
            [s appendFormat:@"\nOn loan to %@ (%@)", who, when];
    }
    

    // list of unreported tags.
    if (showUnusedTags) {
        e = [[self valueForKey:@"fields"] objectEnumerator];
        ss = [NSMutableArray array];
        while (t = [e nextObject])
            if (![tagsUsed containsObject:[t tag]] && [[t tag] intValue] > 99) 
                [ss addObject:t];
        if ([ss count] > 0) {
            unreportedTags = [NSMutableString string];
            NSEnumerator *e = [ss objectEnumerator], *es;
            while (t = [e nextObject]) {
                NSString *indicators = [t indicatorsWithHashForBlank];
                if (!indicators)
                    indicators = @"";
                z = [NSMutableString stringWithFormat:@"%@\t%@\t", [t tag], indicators];
                es = [[t valueForKey:@"subfields"] objectEnumerator];
                Subfield *sub;
                NSString *indent = @"";
                while (sub = [es nextObject]) {
                    [z appendString:[NSString stringWithFormat:@"%@$%@ %@\n", indent, [sub tag], [sub diacriticalText]]];
                    indent = @"\t\t";
                }
                [unreportedTags appendString:z];
            }
        }
    } 
    
    [s appendString:@"\n"];
    p1 = [[[NSMutableAttributedString alloc] initWithString:s] autorelease];
    [p1 addAttribute:NSFontAttributeName 
               value:notesFont 
               range:NSMakeRange(0, [p1 length])];
    [p1 addAttribute:NSParagraphStyleAttributeName 
               value:style 
               range:NSMakeRange(0, [p1 length])];
    [pretty appendAttributedString:p1];
    
    if ([links length] > 0) {
        [links addAttribute:NSFontAttributeName 
                   value:notesFont 
                   range:NSMakeRange(0, [links length])];
    
        [links addAttribute:NSParagraphStyleAttributeName 
                   value:linkStyle 
                   range:NSMakeRange(0, [links length])];
        [pretty appendAttributedString:links];
    }
    if (unreportedTags != nil) {
        p1 = [[[NSMutableAttributedString alloc] initWithString:unreportedTags] autorelease];
        [p1 addAttribute:NSFontAttributeName 
                   value:notesFont 
                   range:NSMakeRange(0, [p1 length])];
        [p1 addAttribute:NSParagraphStyleAttributeName 
                   value:unreportedTagsStyle 
                   range:NSMakeRange(0, [p1 length])];
        [pretty appendAttributedString:p1];
    }
    
    [pretty appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
	return pretty;
    
}

-(Field*)fieldByTag:(unsigned)target
{
    NSArray *tags = [self repeatedTags:target];
    if ([tags count] == 0)
        return nil;
    else {
        return [tags objectAtIndex:0];
    }
}

-(NSArray*)repeatedTags:(unsigned)target
{
    NSString *tag = [NSString stringWithFormat:@"%03d", target];
    NSEnumerator *e = [[self valueForKey:@"fields"] objectEnumerator];
    NSMutableArray *array = [NSMutableArray array];
    Field *f;
    while (f = [e nextObject])
        if ([f matchesTag:tag])
            [array addObject:f];
    return array;
}


//=========================================================== 
//  rawData 
//=========================================================== 
- (NSData *)rawData
{
    return rawData; 
}

- (void)setRawData:(NSData *)aRawData
{
    if (rawData != aRawData) {
        [aRawData retain];
        [rawData release];
        rawData = aRawData;
    }
}


//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
    [self setDictionary:nil];
    [self setRawData:nil];
	[self setShortDewey:nil];
    [super dealloc];
}



-(NSAttributedString*)lineFormat
{
//    NSData *marc = [self rawData];
//    NSString *line;
//    char *result;      /* for result buf */
//    int result_len;    /* for size of result */
//    yaz_marc_t mt = yaz_marc_create();
//    yaz_marc_xml(mt, YAZ_MARC_LINE);
//    yaz_marc_decode_buf(mt, [marc bytes], [marc length],
//                        &result, &result_len);
//    if (result != nil) {
//		char *buf = malloc((result_len + 1) * sizeof(char));
//		memcpy(buf, result, result_len);
//		buf[result_len] = 0;
//		line = [NSString stringWithCString:buf encoding:NSISOLatin1StringEncoding];
//		free(buf);
//        line = decodeDiacritics(line); //[NSString stringWithCString:result length:result_len]);
//		NSLog(@"%@", line);
//	}
//    else
//        line = @"";
//    yaz_marc_destroy(mt);  /* note that result is now freed... */
//    return line;
	NSFont *font = [NSFont fontWithName:@"Courier" size:11];
    NSMutableArray *tabStops = [self calculateTabStops:font];
	float leftIndent = [[tabStops lastObject] location];
	
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style autorelease];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    [style setAlignment:NSTextAlignmentLeft];
    [style setHeadIndent:leftIndent];
    [style setFirstLineHeadIndent:0];
    [style setParagraphSpacing:0.0];
    [style setLineSpacing:1];
	[style setTabStops:tabStops];

    NSArray *tags = [[[self valueForKey:@"fields"] allObjects] 
							sortedArrayUsingSelector:@selector(fieldCompare:)];
    NSEnumerator *e = [tags objectEnumerator];
    Field *value;
	/*
    NSMutableString *leader; 
    if (![self leader])
        leader = [NSMutableString stringWithFormat:@"%24s", " "];
    else leader = [NSMutableString stringWithString:[self leader]];
    */
    NSMutableString *f = [NSMutableString string];
    while (value = [e nextObject]) {
		if ([[value tag] intValue] < 10) {
			continue;
		}
		NSEnumerator *e1 = [value subfieldEnumerator];
		[f appendString:[value tag]];
		Subfield *subfield;
		NSString *key;
		if ([value valueForKey:@"indicators"]) 
			[f appendFormat:@"\t%@%@", [[value indicator1] text], [[value indicator2] text]];
		else {
			[f appendString:@"\t"];
		}
		BOOL firstLine = YES;
		while (subfield = [e1 nextObject]) {        
			key = [subfield tag];
			if ([key isEqualToString:@"?"]) 
				key = @"";
			else
				key = [NSString stringWithFormat:@"$%@", key];
			NSString *text = [subfield diacriticalText];
			if (!text)
				continue;
			if (firstLine) {
				[f appendFormat:@"\t%@\t%@\n", key, text];
				firstLine = NO;
			}
			else {
				[f appendFormat:@"\t\t%@\t%@\n", key, text];
			}
		}
    }
	NSMutableAttributedString *line;
	line = [[NSMutableAttributedString alloc] 
				initWithString:f
					attributes:[NSDictionary dictionaryWithObjectsAndKeys:style, 
														   NSParagraphStyleAttributeName,
															font, NSFontAttributeName, nil]];
	return line;
}


- (Century *)century 
{
    id tmpObject;
    
    [self willAccessValueForKey: @"century"];
    tmpObject = [self primitiveValueForKey: @"century"];
    [self didAccessValueForKey: @"century"];
    
    return tmpObject;
}

- (void)setCentury:(Century *)value 
{
    [self willChangeValueForKey: @"century"];
    [self setPrimitiveValue: value
                     forKey: @"century"];
    [self didChangeValueForKey: @"century"];
}


- (BOOL)validateCentury: (id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

-(NSString*)dewey
{
    return [self dcn];
}

-(void)setShortDewey:(NSString*)string
{
	[string retain];
	[shortDewey release];
	shortDewey = string;
}

-(NSString*)shortDewey
{
	if (!shortDewey) {
		NSString *s = [self dewey];
		NSString *tmp;
		NSRange range = [s rangeOfString:@"/"];
		if (range.location == NSNotFound) {
			tmp = s;
		} else {
			tmp = [s substringToIndex:range.location];
		}
		[self setShortDewey:tmp];
	}
	return shortDewey;
}

-(float)fShortDewey
{
    NSString *s=[self shortDewey];
    BOOL isNumber;
    float z;
    isNumber = [[NSScanner scannerWithString:s] scanFloat:&z];
    if (isNumber)
        return z;
    else
        return -1.0;
}

-(float)Dewey
{
    NSMutableString *s = [NSMutableString stringWithString:[self dewey]];
    [s replaceOccurrencesOfString:@"/" 
                       withString:@"" 
                          options:NSLiteralSearch
                            range:NSMakeRange(0, [s length])];
    BOOL isNumber;
    float z;
    isNumber = [[NSScanner scannerWithString:s] scanFloat:&z];
    if (isNumber)
        return z;
    else
        return -1.0;
}


@end
