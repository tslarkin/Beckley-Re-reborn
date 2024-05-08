/*
 *  Utilities.h
 *  CodeTable
 *
 *  Created by Timothy Larkin on 6/6/09.
 *  Copyright 2009 Abstract Tools. All rights reserved.
 *
 */

//#import "CompileCodeTable.h"
#import "Foundation/Foundation.h"
#import "Constants.h"
typedef struct Code *CodePtr;

NSString* charset_name(CodePtr code);
void fill(UInt8 *buffer, NSString* hex);
