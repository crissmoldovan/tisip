//
//  PjSIPProxy.m
//  pjsiptest
//
//  Created by CRISTIAN MOLDOVAN on 18/10/2015.
//  Copyright © 2015 CRISTIAN MOLDOVAN. All rights reserved.
//

#import "PjSIPProxy.h"

@implementation PjSIPProxy

+ (PjSIPProxy *)sharedProxy {
    static dispatch_once_t onceToken;
    static PjSIPProxy *proxy = nil;
    dispatch_once(&onceToken, ^{ proxy = [[PjSIPProxy alloc] init]; });
    
    return proxy;
}

- (id)init {
    self = [super init];
    _accountIds = [[NSMutableArray alloc] init];
    
    [self start];
    return self;
}

- (NSNumber *) start{
    NSLog(@"PJProxy starting");
    
    BOOL success;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    
//    success = [session setMode:AVAudioSessionModeVoiceChat error:&error];
//    if (!success) NSLog(@"AVAudioSession error setMode: %@", [error localizedDescription]);
//    else NSLog(@"AVAudioSession setMode OK");
//
//    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
//                       withOptions:AVAudioSessionCategoryOptionMixWithOthers
//                             error:&error];
    if (!success) NSLog(@"AVAudioSession error setCategory: %@", [error localizedDescription]);
    else NSLog(@"AVAudioSession setCategory OK");
    
    success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    if (!success) NSLog(@"AVAudioSession error overrideOutputAudioPort: %@", [error localizedDescription]);
    else NSLog(@"AVAudioSession overrideOutputAudioPort OK");
    
    pj_status_t status;
    status = pjsua_create();
    
    pjsua_config cfg;
    pjsua_config_default (&cfg);
    cfg.enable_unsolicited_mwi = PJ_FALSE;
    
    cfg.stun_srv_cnt = 6;
    
    cfg.stun_srv[0] = pj_str("stun.zoiper.com");
    cfg.stun_srv[1] = pj_str("stun.l.google.com:19302");
    cfg.stun_srv[2] = pj_str("stun1.l.google.com:19302");
    cfg.stun_srv[3] = pj_str("stun2.l.google.com:19302");
    cfg.stun_srv[4] = pj_str("stun3.l.google.com:19302");
    cfg.stun_srv[5] = pj_str("stun4.l.google.com:19302");
    
    [PjSIPDispatch configureCallbacksForAgent:&cfg];
    
    // Init the logging config structure
    pjsua_logging_config log_cfg;
    pjsua_logging_config_default(&log_cfg);
    log_cfg.console_level = 4;
    
    // Init the pjsua
    status = pjsua_init(&cfg, &log_cfg, NULL);
    if (status != PJ_SUCCESS) {
        NSLog(@"PJSIP INIT FAILED");
        //        error_exit("Error in pjsua_init()", status);
    }
    
    // Init transport config structure
    pjsua_transport_config trasportTcpCfg;
    pjsua_transport_config_default(&trasportTcpCfg);
    
    // Add TCP transport.
    status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &trasportTcpCfg, &_transportId);
    if (status != PJ_SUCCESS) NSLog(@"Error TCP creating transport");
    NSLog(@"CREATED TCP TRANSPORT %d", _transportId);
    
//    // Init transport config structure
//    pjsua_transport_config trasportUdpCfg;
//    pjsua_transport_config_default(&trasportUdpCfg);
//    
//    // Add UDP transport.
//    status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &trasportUdpCfg, NULL);
//    if (status != PJ_SUCCESS) NSLog(@"Error UDP creating transport");
    
    status = pjsua_start();
    // return negative id if failed
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    // return account id if OK
    return [NSNumber numberWithInt:1];
}

- (NSNumber *) stop{
    NSLog(@"PJProxy stoping");
        if (_transportId != PJSUA_INVALID_ID) {
            pjsua_transport_close(_transportId, PJ_TRUE);
            _transportId = PJSUA_INVALID_ID;
        }
    
    pjsua_destroy();
    
    // remove all registered account ids
    [_accountIds removeAllObjects];
    
    return [NSNumber numberWithInt:1];
}

- (void)dealloc {
    
}

-(NSNumber *) refresh:(NSNumber *)accountId {
    pj_status_t status;
    
    status = pjsua_acc_set_registration([accountId intValue], PJ_TRUE);
    
    // return negative id if failed
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    // return account id if OK
    return [NSNumber numberWithInt:1];
}


-(NSNumber *) register:(NSString *)sipAccount withSipDomain:(NSString *)sipDomain usingRealm:(NSString *)realm usingUsername:(NSString *)username usingPassword:(NSString *)password {
    
    pjsua_acc_config cfg;
    
    pjsua_acc_config_default(&cfg);
    cfg.mwi_enabled = PJ_FALSE;
    
    NSString *sipId = [NSString stringWithFormat:@"sip:%@@%@", sipAccount, sipDomain];
    cfg.id = [PJUtil PJStringWithString: sipId];
    cfg.cred_count = 1;
    
    pjsip_cred_info credentials;
    
    credentials.realm = [PJUtil PJStringWithString: realm];
    credentials.username = [PJUtil PJStringWithString: username];
    credentials.data = [PJUtil PJStringWithString: password];
    credentials.scheme = pj_str("digest");
    credentials.data_type = 0;
    
    cfg.cred_info[0] = credentials;
    
    NSString *regUri = [NSString stringWithFormat:@"sip:%@;transport=tcp", sipDomain];
    
    cfg.reg_uri = [PJUtil PJStringWithString: regUri];
    
    pj_status_t status;
    pjsua_acc_id acc_id;
    status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
    
    // return negative id if failed
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    // add the account to the local dictionary
    [_accountIds addObject:[NSNumber numberWithInt:acc_id]];
    
    // return account id if OK
    return [NSNumber numberWithInt: acc_id];
}

// unregisters an account if present
- (NSNumber *) unregister:(NSNumber *)accountId {
    pj_status_t status;
    
    status = pjsua_acc_del([accountId intValue]);
    
    // return negative id if failed
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    // return account id if OK
    [_accountIds removeObject:accountId];
    return [NSNumber numberWithInt:1];
}

- (pjsua_acc_info) getAccountInfo:(NSNumber *)accountId {
    pjsua_acc_info accountInfo;
    pjsua_acc_get_info([accountId intValue], &accountInfo);
    
    return accountInfo;
}

- (NSNumber *) placeCall:(NSNumber *)accountId toUri:(NSString *)uri {
    pj_status_t status;
    pj_str_t calledUri = [PJUtil PJStringWithString:[NSString stringWithFormat:@"%@;transport=tcp", uri]];
    
    status = pjsua_call_make_call([accountId intValue], &calledUri, 0, NULL, NULL, NULL);
    // return negative id if failed
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    // return account id if OK
    return [NSNumber numberWithInt: 1];
}

- (NSNumber *) hangUpCall:(NSNumber *)callId{
    pj_status_t status;
    status = pjsua_call_hangup([callId intValue], 0, NULL, NULL);
    // return negative id if failed
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    // return account id if OK
    return [NSNumber numberWithInt: 1];

}

- (NSNumber *) answerCall:(NSNumber *)callId{
    pj_status_t status;
    status = pjsua_call_answer([callId intValue], 200, NULL, NULL);
    // return negative id if failed
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    // return account id if OK
    return [NSNumber numberWithInt: 1];
}

- (NSNumber *) muteCall:(NSNumber *)callId{
    pj_status_t status;
    
    pjsua_call_info ci;
    pjsua_conf_port_id conf_port_id;

    pjsua_call_get_info([callId intValue], &ci);
    conf_port_id = ci.conf_slot;
    
    pjsua_conf_disconnect(0, conf_port_id);
    
    // return account id if OK
    return [NSNumber numberWithInt: 1];
}

- (NSNumber *) unmuteCall:(NSNumber *)callId{
    pj_status_t status;
    
    pjsua_call_info ci;
    pjsua_conf_port_id conf_port_id;
    
    pjsua_call_get_info([callId intValue], &ci);
    conf_port_id = ci.conf_slot;
    
    pjsua_conf_connect(0,conf_port_id);
    
    // return account id if OK
    return [NSNumber numberWithInt: 1];
}

- (NSNumber *) sendText:(NSNumber *)accountId toUri:(NSString *)uri withContent:(NSString *)content{
    pj_status_t status;
    pj_str_t toUri = [PJUtil PJStringWithString:[NSString stringWithFormat:@"%@;transport=tcp", uri]];
    NSLog(@"SENDING SMS TO: %@", [PJUtil stringWithPJString:&toUri]);
    pj_str_t text = [PJUtil PJStringWithString:content];
    status = pjsua_im_send([accountId intValue], &toUri, NULL, &text, NULL, NULL);
    // return negative id if failed
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    // return account id if OK
    return [NSNumber numberWithInt: 1];
}

- (NSNumber *) getRegisteredAccountsCount{
    return [NSNumber numberWithInt:pjsua_acc_get_count()];
}

- (BOOL)setLoud:(BOOL)loud {

    if (loud) {
        NSLog(@"SETTING SPEAKERS");
        @try {
            BOOL success;
            AVAudioSession *session = [AVAudioSession sharedInstance];
            NSError *error = nil;
            
            success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
            if (success) {
                NSLog(@"AVAudioSession overrideOutputAudioPort to speaker OK");
                return YES;
            }else{
                return NO;
                NSLog(@"AVAudioSession error overrideOutputAudioPort to speaker: %@", [error localizedDescription]);
            }
        }
        @catch (NSException *exception) {
            return NO;
        }
    } else {
        NSLog(@"SETTING EARPIECE");
        @try {
            BOOL success;
            AVAudioSession *session = [AVAudioSession sharedInstance];
            NSError *error = nil;
            
            success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
            if (success) {
                NSLog(@"AVAudioSession overrideOutputAudioPort to none OK");
                return YES;
            }else{
                return NO;
                NSLog(@"AVAudioSession error overrideOutputAudioPort to none: %@", [error localizedDescription]);
            }
        }
        @catch (NSException *exception) {
            NSLog(@"---NOT OK: %@", [exception description]);
            return NO;
        }
    }
}

- (void) sendDTMF:(NSNumber *)callId dtmf:(NSString *)digit {
    pj_status_t status;
    pj_str_t digitStr = [PJUtil PJStringWithString:digit];
    
    status = pjsua_call_dial_dtmf([callId intValue], &digitStr);
    // return negative id if failed
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    // return account id if OK
    return [NSNumber numberWithInt: 1];
}


@end
