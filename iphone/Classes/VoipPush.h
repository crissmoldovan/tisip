//
//  VoipPush.h
//  TiSIP
//
//  Created by CRISTIAN MOLDOVAN on 04/11/2015.
//
//

#import <Foundation/Foundation.h>
#import <PushKit/PushKit.h>

@interface VoipPush : NSObject <PKPushRegistryDelegate>

+ (VoipPush *)sharedProxy;

- (void) register;

@end
