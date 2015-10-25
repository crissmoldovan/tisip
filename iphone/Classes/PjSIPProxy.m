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
    pj_status_t status;
    status = pjsua_create();
    
    pjsua_config cfg;
    pjsua_config_default (&cfg);
    
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
    log_cfg.console_level = 1;
    
    // Init the pjsua
    status = pjsua_init(&cfg, &log_cfg, NULL);
    if (status != PJ_SUCCESS) {
        NSLog(@"PJSIP INIT FAILED");
        //        error_exit("Error in pjsua_init()", status);
    }
    
    // Init transport config structure
    pjsua_transport_config trasportCfg;
    pjsua_transport_config_default(&trasportCfg);
    
    // Add TCP transport.
    status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &trasportCfg, &_transportId);
    if (status != PJ_SUCCESS) NSLog(@"Error creating transport");
    
    status = pjsua_start();
    // return negative id if failed
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    // return account id if OK
    return [NSNumber numberWithInt:1];
}

- (NSNumber *) stop{
    NSLog(@"PJProxy stoping");
    //    if (_transportId != PJSUA_INVALID_ID) {
    //        pjsua_transport_close(_transportId, PJ_TRUE);
    //        _transportId = PJSUA_INVALID_ID;
    //    }
    
    pjsua_destroy();
    
    // remove all registered account ids
    [_accountIds removeAllObjects];
    
    return [NSNumber numberWithInt:1];
}

- (void)dealloc {
    
}



-(NSNumber *) register:(NSString *)sipAccount withSipDomain:(NSString *)sipDomain usingRealm:(NSString *)realm usingUsername:(NSString *)username usingPassword:(NSString *)password {
    
    pjsua_acc_config cfg;
    
    pjsua_acc_config_default(&cfg);
    
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
    
    NSString *regUri = [NSString stringWithFormat:@"sip:%@", sipDomain];
    
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
    pj_str_t calledUri = [PJUtil PJStringWithString:uri];
    
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

- (NSNumber *) sendText:(NSNumber *)accountId toUri:(NSString *)uri withContent:(NSString *)content{
    pj_status_t status;
    pj_str_t toUri = [PJUtil PJStringWithString:uri];
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



@end
