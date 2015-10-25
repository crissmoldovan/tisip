//
//  PJUtil.m
//  pjsiptest
//
//  Created by CRISTIAN MOLDOVAN on 18/10/2015.
//  Copyright © 2015 CRISTIAN MOLDOVAN. All rights reserved.
//

#import "PJUtil.h"

@implementation PJUtil

+ (NSError *)errorWithSIPStatus:(pj_status_t)status {
    int errNumber = PJSIP_ERRNO_FROM_SIP_STATUS(status);
    
    pj_size_t bufferSize = sizeof(char) * 255;
    NSMutableData *data = [NSMutableData dataWithLength:bufferSize];
    char *buffer = [data mutableBytes];
    pj_strerror(status, buffer, bufferSize);
    
    NSString *errorStr = [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
    NSDictionary *info = nil;
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            errorStr, NSLocalizedDescriptionKey,
            [NSNumber numberWithInt:status], @"pj_status_t",
            [NSNumber numberWithInt:errNumber], @"PJSIP_ERRNO_FORM_SIP_STATUS", nil];
    
    NSError *err = nil;
    err = [NSError errorWithDomain:@"pjsip.org"
                              code:PJSIP_ERRNO_FROM_SIP_STATUS(status)
                          userInfo:info];
    
    return err;
}


+ (NSString *)stringWithPJString:(const pj_str_t *)pjString {
    NSString *result = [NSString alloc];
    result = [result initWithBytesNoCopy:pjString->ptr
                                  length:pjString->slen
                                encoding:NSASCIIStringEncoding
                            freeWhenDone:NO];
    
    return result;
}

+ (pj_str_t)PJStringWithString:(NSString *)string {
    const char *cStr = [string cStringUsingEncoding:NSUTF8StringEncoding]; // TODO: UTF8?
    
    pj_str_t result;
    pj_cstr(&result, cStr);
    return result;
}

+ (pj_str_t)PJAddressWithString:(NSString *)string {
    return [self PJStringWithString:[@"sip:" stringByAppendingString:string]];
}

@end
