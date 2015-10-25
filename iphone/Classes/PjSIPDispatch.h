//
//  PjSIPDispatch.h
//  pjsiptest
//
//  Created by CRISTIAN MOLDOVAN on 19/10/2015.
//  Copyright © 2015 CRISTIAN MOLDOVAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PJSIP.h"

@interface PjSIPDispatch : NSObject

+ (void)configureCallbacksForAgent:(pjsua_config *)uaConfig;

@end
