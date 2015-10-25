//
//  PJUtil.h
//  pjsiptest
//
//  Created by CRISTIAN MOLDOVAN on 18/10/2015.
//  Copyright © 2015 CRISTIAN MOLDOVAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PJSIP.h"

@interface PJUtil : NSObject

/// Creates an NSError from the given PJSIP status using PJSIP macros and functions.
+ (NSError *)errorWithSIPStatus:(pj_status_t)status;

/// Creates NSString from pj_str_t. Instance usable as long as pj_str_t lives.
+ (NSString *)stringWithPJString:(const pj_str_t *)pjString;

/// Creates pj_str_t from NSString. Instance lifetime depends on the NSString instance.
+ (pj_str_t)PJStringWithString:(NSString *)string;

/// Creates pj_str_t from NSString prefixed with "sip:". Instance lifetime depends on the NSString instance.
+ (pj_str_t)PJAddressWithString:(NSString *)string;

@end