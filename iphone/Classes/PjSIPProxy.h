//
//  PjSIPProxy.h
//  pjsiptest
//
//  Created by CRISTIAN MOLDOVAN on 18/10/2015.
//  Copyright © 2015 CRISTIAN MOLDOVAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "PjSIPDispatch.h"
#import "PjSIP.h"
#import "Util.h"

@interface PjSIPProxy : NSObject

@property pjsua_transport_id transportId;
@property NSMutableArray *accountIds;

+ (PjSIPProxy *)sharedProxy;

// registers an account within the pjsip module
- (NSNumber *) register:(NSString *)account
withSipDomain:(NSString *) domain
usingRealm:(NSString *) realm
usingUsername:(NSString *) username
usingPassword:(NSString *) password;

// unregisters an account
- (NSNumber *) unregister:(NSNumber *)accountId;

// upadte an account reg info
- (NSNumber *) refresh:(NSNumber *)accountId;

- (pjsua_acc_info) getAccountInfo:(NSNumber *)accountId;

- (NSNumber *) stop;
- (NSNumber *) start;

- (NSNumber *) placeCall:(NSNumber *)accountId toUri:(NSString *)uri;
- (NSNumber *) answerCall:(NSNumber *)callId;
- (NSNumber *) hangUpCall:(NSNumber *)callId;
- (NSNumber *) muteCall:(NSNumber *)callId;
- (NSNumber *) unmuteCall:(NSNumber *)callId;
- (NSNumber *) sendText:(NSNumber *)accountId toUri:(NSString *)uri withContent:(NSString *)content;
- (NSNumber *) getRegisteredAccountsCount;
- (BOOL)setLoud:(BOOL)loud;
- (void) sendDTMF:(NSNumber *)callId dtmf:(NSString *)digit;

@end
