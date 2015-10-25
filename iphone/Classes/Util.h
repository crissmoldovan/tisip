//
//  Util.h
//  pjsiptest
//
//  Created by CRISTIAN MOLDOVAN on 18/10/2015.
//  Copyright © 2015 CRISTIAN MOLDOVAN. All rights reserved.
//

#ifndef Util_h
#define Util_h

// additional util imports
#import "PJUtil.h"


// just in case we need to compile w/o assertions
#define PJAssert NSAssert


// PJSIP status check macros
#define PJLogSipError(status_)                                      \
NSLog(@"PJ: %@", [PJUtil errorWithSIPStatus:status_]);

#define PJLogIfFails(aStatement_) do {      \
pj_status_t status = (aStatement_);     \
if (status != PJ_SUCCESS)               \
PJLogSipError(status);              \
} while (0)

#define PJReturnValueIfFails(aStatement_, returnValue_) do {            \
pj_status_t status = (aStatement_);                                 \
if (status != PJ_SUCCESS) {                                         \
PJLogSipError(status);                                          \
return returnValue_;                                            \
}                                                                   \
} while(0)

#define PJReturnIfFails(aStatement_) PJReturnValueIfFails(aStatement_, )
#define PJReturnNoIfFails(aStatement_) PJReturnValueIfFails(aStatement_, NO)
#define PJReturnNilIfFails(aStatement_) PJReturnValueIfFails(aStatement_, nil)


#endif /* Util_h */
