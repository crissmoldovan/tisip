/**
 * TiSIP
 *
 * Created by Your Name
 * Copyright (c) 2015 Your Company. All rights reserved.
 */

#import "ComCrissmoldovanTisipModule.h"
#import "TiApp.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "PjSIPDispatch.h"
#import "PjSIPNotifications.h"
#import "PJSIP.h"
#import "PJUtil.h"
//#import "VoipPush.h"

@implementation ComCrissmoldovanTisipModule

PjSIPProxy *pjproxy;

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"c281baa1-f5cf-45e9-af64-1cc716319d76";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"com.crissmoldovan.tisip";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
    
    pjproxy = [PjSIPProxy sharedProxy];
    
    // call state event handler
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(callStateDidChange:)
                   name:PJSIPCallStateDidChangeNotification
                 object:[PjSIPDispatch class]];
    
    // incoming call event handler
    [center addObserver:self
               selector:@selector(didReceiveIncomingCall:)
                   name:PJSIPIncomingCallNotification
                 object:[PjSIPDispatch class]];
    
    // registration start event handler
    [center addObserver:self
               selector:@selector(registrationDidStart:)
                   name:PJSIPRegistrationDidStartNotification
                 object:[PjSIPDispatch class]];
    
    // registration state change event handler
    [center addObserver:self
               selector:@selector(registrationStateDidChange:)
                   name:PJSIPRegistrationStateDidChangeNotification
                 object:[PjSIPDispatch class]];
    
    // mwi event handler
    [center addObserver:self
               selector:@selector(didReceiveMWI:)
                   name:PJSIPMWINotification
                 object:[PjSIPDispatch class]];
    
    // message received
    [center addObserver:self
               selector:@selector(didReceiveMessage:)
                   name:PJSIPPagerNotification
                 object:[PjSIPDispatch class]];
    
    // message status received
    [center addObserver:self
               selector:@selector(didReceiveMessageStatusUpdate:)
                   name:PJSIPPagerUpdateNotification
                 object:[PjSIPDispatch class]];
    
	NSLog(@"[INFO] %@ loaded",[self moduleId]);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably

    //[pjproxy stop];
    
	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup

-(void)dealloc
{
	// release any resources that have been retained by the module
	//[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}
#pragma Private Methods

// handle call state change
- (void)callStateDidChange:(NSNotification *)notif {
    pjsua_call_id callId = PJNotifGetInt(notif, PJSIPCallIdKey);
    pjsua_acc_id accountId = PJNotifGetInt(notif, PJSIPAccountIdKey);
    
    pjsua_call_info callInfo;
    pjsua_call_get_info(callId, &callInfo);
    
    NSString *callStatus;
    switch (callInfo.state) {
        case PJSIP_INV_STATE_NULL: {
            callStatus = @"READY";
        } break;
            
        case PJSIP_INV_STATE_CALLING:
        case PJSIP_INV_STATE_INCOMING: {
            callStatus = @"CALLING";
        } break;
            
        case PJSIP_INV_STATE_EARLY:
        case PJSIP_INV_STATE_CONNECTING: {
            //[self startRingback];
            callStatus = @"CONNECTING";
            
//            BOOL success;
//            AVAudioSession *session = [AVAudioSession sharedInstance];
//            NSError *error = nil;
//            
//            success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
//                               withOptions:AVAudioSessionCategoryOptionMixWithOthers
//                                     error:&error];
//            if (!success) NSLog(@"AVAudioSession error setCategory: %@", [error localizedDescription]);
            
//            success = [session setActive:YES error:&error];
//            if (!success) NSLog(@"AVAudioSession error setActive: %@", [error localizedDescription]);
        } break;
            
        case PJSIP_INV_STATE_CONFIRMED: {
            //[self stopRingback];
            callStatus = @"CONNECTED";
        } break;
            
        case PJSIP_INV_STATE_DISCONNECTED: {
            //[self stopRingback];
            callStatus = @"DISCONNECTED";
            BOOL success;
//            AVAudioSession *session = [AVAudioSession sharedInstance];
//            NSError *error = nil;
//            
//            success = [session setCategory:AVAudioSessionCategorySoloAmbient
//                                withOptions:AVAudioSessionCategoryOptionMixWithOthers
//                                error:&error];
//            if (!success) NSLog(@"AVAudioSession error setCategory: %@", [error localizedDescription]);
            
//            success = [session setActive:NO error:&error];
//            if (!success) NSLog(@"AVAudioSession error setActive: %@", [error localizedDescription]);
        } break;
    }
    
    NSLog(@"CALL STATE NOTIF: callid: %u status: %@ for account: %u", callId, callStatus, accountId);
    NSString *eventName = [NSString stringWithFormat:@"CALL.%@", callStatus];
    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:accountId],@"accountId",
                                 [NSNumber numberWithInt:callId],@"callId", nil];
    [self fireEvent:eventName withObject:eventObject];
    //    __block id self_ = self;
    //    dispatch_async(dispatch_get_main_queue(), ^{ [self_ setStatus:callStatus]; });
}

// handle incoming call
- (void)didReceiveIncomingCall:(NSNotification *)notif {
    pjsua_acc_id accountId = PJNotifGetInt(notif, PJSIPAccountIdKey);
    pjsua_call_id callId = PJNotifGetInt(notif, PJSIPCallIdKey);
    
    pjsua_call_info ci;
    pjsua_call_get_info(callId, &ci);
    
    NSString *remote_contact = [PJUtil stringWithPJString:&ci.remote_contact];
    NSString *remote_info = [PJUtil stringWithPJString:&ci.remote_info];
    NSString *from = [PJUtil stringWithPJString:&ci.remote_info];
    NSString *remote_id = [PJUtil stringWithPJString:&ci.call_id];
    
    NSLog(@"INCOMING CALL NOTIF: callid: %u for account: %u from %@ rc: %@ ri: %@ rid: %@", callId, accountId, from, remote_contact, remote_info, remote_id);
    NSString *eventName = @"CALL.INCOMING";
    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:accountId],@"accountId",
                                 [NSNumber numberWithInt:callId],@"callId",
                                 from, @"from",
                                 remote_contact, @"remote_contact",
                                 remote_info, @"remote_info",
                                 remote_id, @"remote_id",nil];
    [self fireEvent:eventName withObject:eventObject];
}

// handle registration did start
- (void)registrationDidStart:(NSNotification *)notif {
    pjsua_acc_id accountId = PJNotifGetInt(notif, PJSIPAccountIdKey);
    pj_bool_t renew = PJNotifGetBool(notif, PJSIPRenewKey);
    
    NSString *accStatus;
    accStatus = renew ? @"CONNECTING" : @"DISCONNECTING";
    
    NSLog(@"REG STATE NOTIF: status: %@ for account %u", accStatus, accountId);
    
    NSString *eventName = [NSString stringWithFormat:@"REGISTRATION.%@", accStatus];
    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:accountId],@"accountId", nil];
    [self fireEvent:eventName withObject:eventObject];
}

// hanlde registration did change
- (void)registrationStateDidChange:(NSNotification *)notif {
    pjsua_acc_id accountId = PJNotifGetInt(notif, PJSIPAccountIdKey);
    
    NSString *accStatus;
    
    pjsua_acc_info info;
    pjsua_acc_get_info(accountId, &info);
    
    if (info.reg_last_err != PJ_SUCCESS) {
        accStatus = @"INVALID";
        
    } else {
        pjsip_status_code code = info.status;
        if (code == 0) {
            accStatus = @"OFFLINE";
        } else if (PJSIP_IS_STATUS_IN_CLASS(code, 100) || PJSIP_IS_STATUS_IN_CLASS(code, 300)) {
            accStatus = @"CONNECTING";
        } else if (PJSIP_IS_STATUS_IN_CLASS(code, 200)) {
            if (info.expires > 0){
                accStatus = @"CONNECTED";
            }else{
                accStatus = @"DISCONNECTED";
            }
            
        } else {
            accStatus = @"INVALID";
        }
    }
    
    NSLog(@"REG STATE NOTIF: status: %@ for account %u", accStatus, accountId);
    NSString *eventName = [NSString stringWithFormat:@"REGISTRATION.%@", accStatus];
    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:accountId],@"accountId", nil];
    [self fireEvent:eventName withObject:eventObject];
}

- (void)didReceiveMWI:(NSNotification *) notif {
    pjsua_acc_id accountId = PJNotifGetInt(notif, PJSIPAccountIdKey);
    NSString *body = [[notif userInfo] objectForKey:PJSIPMwiInfoContentKey];
    NSString *mimeType = [[notif userInfo] objectForKey:PJSIPMwiInfoMimeTypeKey];
    
    NSLog(@"MWI NOTIF: for account %u mime: %@ body: %@", accountId, mimeType, body);
    NSString *eventName = @"MWI";
    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:accountId],@"accountId",
                                 mimeType, @"mimeType",
                                 body, @"body", nil];
    [self fireEvent:eventName withObject:eventObject];
}

- (void)didReceiveMessage:(NSNotification *) notif {
    pjsua_acc_id accountId = PJNotifGetInt(notif, PJSIPAccountIdKey);
    
    NSString *from = [[notif userInfo] objectForKey:PJSIPPagerFromKey];
    NSString *to = [[notif userInfo] objectForKey:PJSIPPagerToKey];
    NSString *contact = [[notif userInfo] objectForKey:PJSIPPagerContactKey];
    NSString *mimeType = [[notif userInfo] objectForKey:PJSIPPagerMimeTypeKey];
    NSString *body = [[notif userInfo] objectForKey:PJSIPPagerBodyKey];
    
    NSLog(@"MESSAGE: for account %u from: %@ to: %@ contact: %@ mime: %@ body: %@", accountId, from, to, contact, mimeType, body);
    NSString *eventName = @"MESSAGE.INCOMING";
    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:accountId],@"accountId",
                                 mimeType, @"mimeType",
                                 body, @"content",
                                 from, @"from",
                                 to, @"to",
                                 contact, @"contact", nil];
    [self fireEvent:eventName withObject:eventObject];
}

- (void)didReceiveMessageStatusUpdate:(NSNotification *) notif{
    pjsua_acc_id accountId = PJNotifGetInt(notif, PJSIPAccountIdKey);
    NSString *to = [[notif userInfo] objectForKey:PJSIPPagerToKey];
    NSString *reason = [[notif userInfo] objectForKey:PJSIPPagerStatusReasonKey];
    NSNumber *status = [NSNumber numberWithInt:PJNotifGetInt(notif, PJSIPPagerStatusCodeKey)];
    
    NSLog(@"MESSAGE STATUS: for account %u to: %@ reason: %@ status: %@", accountId, to, reason, status);
    NSString *eventName = @"MESSAGE.STATUS";
    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:accountId],@"accountId",
                                 reason, @"reason",
                                 status, @"status",
                                 to, @"to", nil];
    [self fireEvent:eventName withObject:eventObject];
}
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type{
    if([credentials.token length] == 0) {
        NSLog(@"voip token NULL");
        NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSString stringWithFormat:@"emptytoken"],@"status", nil];
        [self fireEvent:@"PUSH.REGISTER.FAILED" withObject:eventObject];
        return;
    }
    
    NSString* token = [[[NSString stringWithFormat:@"%@",credentials.token]
                        stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"VoipProxy token: %@", token);
    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithString:token],@"token", nil];
    [self fireEvent:@"PUSH.REGISTER.SUCCESS" withObject:eventObject];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    NSLog(@"didReceiveIncomingPushWithPayload");
    
    NSDictionary *payloadData = [NSDictionary dictionaryWithDictionary:payload.dictionaryPayload];
    NSLog(@"received type: %@", [payloadData valueForKey:@"evt_type"])

    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                payloadData,@"data", nil];
   [self fireEvent:@"PUSH.RECEIVED" withObject:eventObject];
}

//- (void) didReceiveVoipRegisterSuccess:(NSNotification *) notif{
//    NSString *eventName = @"PUSH.REGISTER.SUCCESS";
//    NSString *token = [[notif userInfo] objectForKey:@"token"];
//    
//    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 [NSString stringWithString:token],@"token", nil];
//    [self fireEvent:eventName withObject:eventObject];
//}
//
//- (void) didReceiveVoipRegisterFailed:(NSNotification *) notif{
//    NSString *eventName = @"PUSH.REGISTER.FAILED";
//    NSString *status = [[notif userInfo] objectForKey:@"status"];
//    
//    NSLog(@" PUSH REG FAIL t: %@", status);
//    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 [NSString stringWithString:status],@"status", nil];
//    [self fireEvent:eventName withObject:eventObject];
//}
//
//- (void) didReceiveVoipPush:(NSNotification *) notif{
//    NSString *eventName = @"PUSH.RECEIVED";
//    NSDictionary *payload = [[notif userInfo] objectForKey:@"data"];
//    
//    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 [NSDictionary dictionaryWithDictionary:payload],@"data", nil];
//    [self fireEvent:eventName withObject:eventObject];
//}


#pragma Public APIs

-(id)register:(id)args{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    NSString* account = [TiUtils stringValue:@"account" properties:args def:@""];
    NSString* sipDomain = [TiUtils stringValue:@"domain" properties:args def:@""];
    NSString* realm = [TiUtils stringValue:@"realm" properties:args def:@""];
    NSString* username = [TiUtils stringValue:@"username" properties:args def:@""];
    NSString* password = [TiUtils stringValue:@"password" properties:args def:@""];
    
    NSNumber* accountId = [pjproxy register:account
        withSipDomain:sipDomain
           usingRealm:realm
        usingUsername:username
        usingPassword:password
    ];
    
    NSLog(@"registered: %@", accountId);
    return accountId;
}

-(void)registerForVoipPush:(id)args{
//    [[VoipPush sharedProxy] register];
    
    PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushRegistry.delegate = self;
    pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

-(id)refresh:(id)args{
    ENSURE_SINGLE_ARG(args, NSNumber);
    
    return [pjproxy refresh:args];
}


-(id)unregister:(id)args{
    ENSURE_SINGLE_ARG(args, NSNumber);
    
    return [pjproxy unregister:args];
}

-(void)placeCall:(id)args{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    NSNumber* accountId = [NSNumber numberWithInt:[TiUtils intValue:@"accountId" properties:args]];
    NSString* uri = [TiUtils stringValue:@"uri" properties:args];
    
    NSLog(@"placing call: %@ from acc: %@", uri, accountId);
    
    [pjproxy placeCall:accountId toUri:uri];
}

-(void)answerCall:(id)args{
    ENSURE_SINGLE_ARG(args, NSNumber);
    
    NSLog(@"answering callid: %@", args);
    
    [pjproxy answerCall:args];
}

-(void)hangUpCall:(id)args{
    ENSURE_SINGLE_ARG(args, NSNumber);
    
    NSLog(@"hanging up callid: %@", args);
    
    [pjproxy hangUpCall:args];
}

-(void)muteCall:(id)args{
    ENSURE_SINGLE_ARG(args, NSNumber);
    
    NSLog(@"muting callid: %@", args);
    
    [pjproxy muteCall:args];
    
    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:args],@"callId", nil];
    
    [self fireEvent:@"MUTED.YES" withObject:eventObject];

}

-(void)unmuteCall:(id)args{
    ENSURE_SINGLE_ARG(args, NSNumber);
    
    NSLog(@"unmuting callid: %@", args);
    
    [pjproxy unmuteCall:args];
    
    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:args],@"callId", nil];
    
    [self fireEvent:@"MUTED.NO" withObject:eventObject];
}

-(void)sendText:(id)args{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    NSNumber* accountId = [NSNumber numberWithInt:[TiUtils intValue:@"accountId" properties:args]];
    NSString* uri = [TiUtils stringValue:@"uri" properties:args];
    NSString* content = [TiUtils stringValue:@"content" properties:args];
    
    [pjproxy sendText:accountId toUri:uri withContent:content];
}
-(void)enableSpeaker:(id)args{
    BOOL *status = [pjproxy setLoud:YES];
    
    if (status){
       [self fireEvent:@"SPEAKER.YES"];
    }else{
       [self fireEvent:@"SPEAKER.NO"];
    }
}
-(void)disableSpeaker:(id)args{
    BOOL *status = [pjproxy setLoud:NO];
    
    if (status){
        [self fireEvent:@"SPEAKER.NO"];
    }else{
        // speaker is still active
        [self fireEvent:@"SPEAKER.YES"];
    }
}
-(void)sentDTMF:(id)args{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    NSNumber* callId = [NSNumber numberWithInt:[TiUtils intValue:@"callId" properties:args]];
    NSString* digit = [TiUtils stringValue:@"digit" properties:args def:@""];
    
    [pjproxy sendDTMF:callId dtmf:digit];
}

-(void)resetAudio:(id)args{
    NSError *error;
    
//    [[AVAudioSession sharedInstance] setActive:NO error:&error];
//    NSLog(@"resetAudio error: %@", error);
//    
//    [[AVAudioSession sharedInstance] setActive:YES error:&error];
//    NSLog(@"resetAudio error: %@", error);

}

-(void)stopAudio:(id)args{
    NSError *error;
    
//    [[AVAudioSession sharedInstance] setActive:NO error:&error];
//    NSLog(@"resetAudio error: %@", error);
    
}

-(void)startAudio:(id)args{
    NSError *error;
    
//    [[AVAudioSession sharedInstance] setActive:YES error:&error];
//    NSLog(@"resetAudio error: %@", error);
    
}




@end
