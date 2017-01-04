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

- (NSDictionary *)getIPAddresses
{
    NSLog(@"LOOKING UP IP");
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                    NSLog(@"FOUND IP: %@ - %@", key, addresses[key]);
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

- (NSNumber *) start{
    NSLog(@"PJProxy starting");
    [self getIPAddresses];
    
//    BOOL success;
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    NSError *error = nil;
//    
//    success = [session setCategory:AVAudioSessionCategorySoloAmbient
//                       withOptions:AVAudioSessionCategoryOptionMixWithOthers
//                       error:&error];
//    
//    if (!success) NSLog(@"AVAudioSession error setCategory: %@", [error localizedDescription]);
//    else NSLog(@"AVAudioSession setCategory OK");
//    
//    success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
//    if (!success) NSLog(@"AVAudioSession error overrideOutputAudioPort: %@", [error localizedDescription]);
//    else NSLog(@"AVAudioSession overrideOutputAudioPort OK");
    
    pj_status_t status;
    status = pjsua_create();
    NSLog(@"PJProxy created");
    pjsua_config cfg;
    pjsua_config_default (&cfg);
    cfg.enable_unsolicited_mwi = PJ_FALSE;
    
    [PjSIPDispatch configureCallbacksForAgent:&cfg];
    NSLog(@"PJProxy callbacks set");
    
    // Init the logging config structure
    pjsua_logging_config log_cfg;
    pjsua_logging_config_default(&log_cfg);
    log_cfg.console_level = 6;
    NSLog(@"PJProxy logging set");
    
    // Init transport config structure
    pjsua_transport_config trasportTcpCfg;
    pjsua_transport_config_default(&trasportTcpCfg);
    
    // Add TCP transport.
    status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &trasportTcpCfg, &_transportIdTCP);
    if (status != PJ_SUCCESS) NSLog(@"Error TCP creating transport");
    NSLog(@"CREATED TCP TRANSPORT %d", _transportIdTCP);
    
//    // Init transport config structure
//    pjsua_transport_config trasportTcpv6Cfg;
//    pjsua_transport_config_default(&trasportTcpv6Cfg);
//    
//    // Add TCP transport.
//    status = pjsua_transport_create(PJSIP_TRANSPORT_TCP6, &trasportTcpv6Cfg, &_transportIdTCP6);
//    if (status != PJ_SUCCESS) NSLog(@"Error TCP6 creating transport");
//    NSLog(@"CREATED TCP6 TRANSPORT %d", _transportIdTCP6);
    
//    // Init transport config structure
    pjsua_transport_config trasportUdpCfg;
    pjsua_transport_config_default(&trasportUdpCfg);
    
    // Add UDP transport.
    status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &trasportUdpCfg, &_transportIdUDP);
    if (status != PJ_SUCCESS) NSLog(@"Error UDP creating transport");
    NSLog(@"CREATED UDP TRANSPORT %d", _transportIdUDP);
    
    pjsua_transport_info transportTCPInfo;
    pjsua_transport_get_info(_transportIdTCP, &transportTCPInfo);
    if (transportTCPInfo.local_addr.addr.sa_family == PJ_AF_INET) NSLog(@"TCP ipv4");
    if (transportTCPInfo.local_addr.addr.sa_family == PJ_AF_INET6) NSLog(@"TCP ipv6");
    
    pjsua_transport_info transportTCP6Info;
    pjsua_transport_get_info(_transportIdTCP6, &transportTCP6Info);
    if (transportTCPInfo.local_addr.addr.sa_family == PJ_AF_INET) NSLog(@"TCP6 ipv4");
    if (transportTCPInfo.local_addr.addr.sa_family == PJ_AF_INET6) NSLog(@"TCP6 ipv6");

    pjsua_transport_info transportUDPInfo;
    pjsua_transport_get_info(_transportIdUDP, &transportUDPInfo);
    if (transportTCPInfo.local_addr.addr.sa_family == PJ_AF_INET) NSLog(@"UDP ipv4");
    if (transportTCPInfo.local_addr.addr.sa_family == PJ_AF_INET6) NSLog(@"UDP ipv6");
    
    
    cfg.stun_srv_cnt = 6;
    
    cfg.stun_srv[0] = pj_str("stun.zoiper.com");
    cfg.stun_srv[1] = pj_str("stun.l.google.com:19302");
    cfg.stun_srv[2] = pj_str("stun1.l.google.com:19302");
    cfg.stun_srv[3] = pj_str("stun2.l.google.com:19302");
    cfg.stun_srv[4] = pj_str("stun3.l.google.com:19302");
    cfg.stun_srv[5] = pj_str("stun4.l.google.com:19302");
    
    // Init the pjsua
    status = pjsua_init(&cfg, &log_cfg, NULL);
    if (status != PJ_SUCCESS) {
        NSLog(@"PJSIP INIT FAILED");
        //        error_exit("Error in pjsua_init()", status);
    }
    
    status = pjsua_start();
    // return negative id if failed
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    NSLog(@"PJProxy started");
    // return account id if OK
    return [NSNumber numberWithInt:1];
}

- (NSNumber *) stop{
    NSLog(@"PJProxy stoping");
    if (_transportIdUDP != PJSUA_INVALID_ID) {
        pjsua_transport_close(_transportIdUDP, PJ_TRUE);
        _transportIdUDP = PJSUA_INVALID_ID;
    }
    if (_transportIdTCP != PJSUA_INVALID_ID) {
        pjsua_transport_close(_transportIdTCP, PJ_TRUE);
        _transportIdTCP = PJSUA_INVALID_ID;
    }
    if (_transportIdTCP6 != PJSUA_INVALID_ID) {
        pjsua_transport_close(_transportIdTCP6, PJ_TRUE);
        _transportIdTCP6 = PJSUA_INVALID_ID;
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
    NSLog(@"REFRESH START %@", accountId);
    status = pjsua_acc_set_registration([accountId intValue], PJ_TRUE);
    NSLog(@"REFRESH END");
    NSLog(@"REFRESH STATUS %@", [PJUtil errorWithSIPStatus:status]);
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
    cfg.reg_timeout = 10;
    
    pjsip_cred_info credentials;
    
    credentials.realm = [PJUtil PJStringWithString: realm];
    credentials.username = [PJUtil PJStringWithString: username];
    credentials.data = [PJUtil PJStringWithString: password];
    credentials.scheme = pj_str("digest");
    credentials.data_type = 0;
    
    cfg.cred_info[0] = credentials;
    
    NSString *regUri = [NSString stringWithFormat:@"sip:%@;transport=tcp", sipDomain];
    
    cfg.reg_uri = [PJUtil PJStringWithString: regUri];
    cfg.transport_id = _transportIdTCP;
    /* Enable IPv6 in media transport */
    //cfg.ipv6_media_use = PJSUA_IPV6_ENABLED;
    
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
//    [[AVAudioSession sharedInstance]
//     setCategory:AVAudioSessionCategoryPlayAndRecord
//     error:NULL];
    
    pj_status_t status;
    pj_str_t calledUri = [PJUtil PJStringWithString:[NSString stringWithFormat:@"%@;transport=tcp", uri]];
    
    status = pjsua_call_make_call([accountId intValue], &calledUri, 0, NULL, NULL, NULL);
    // return negative id if failed
    
    NSLog(@"CALL STATUS %@", [PJUtil errorWithSIPStatus:status]);
    
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    // return account id if OK
    return [NSNumber numberWithInt: 1];
}

- (NSNumber *) hangUpCall:(NSNumber *)callId{
    pj_status_t status;
    [self muteCall:callId];
    
    status = pjsua_call_hangup([callId intValue], 0, NULL, NULL);
    // return negative id if failed
    if (status != PJ_SUCCESS) return [NSNumber numberWithInt:-1];
    
    // return account id if OK
    return [NSNumber numberWithInt: 1];

}

- (NSNumber *) answerCall:(NSNumber *)callId{
//    [[AVAudioSession sharedInstance]
//     setCategory:AVAudioSessionCategoryPlayAndRecord
//     error:NULL];
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

//- (BOOL)setLoud:(BOOL)loud {
//
//    if (loud) {
//        NSLog(@"SETTING SPEAKERS");
//        @try {
//            BOOL success;
//            AVAudioSession *session = [AVAudioSession sharedInstance];
//            NSError *error = nil;
//            
//            success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
//            if (success) {
//                NSLog(@"AVAudioSession overrideOutputAudioPort to speaker OK");
//                return YES;
//            }else{
//                return NO;
//                NSLog(@"AVAudioSession error overrideOutputAudioPort to speaker: %@", [error localizedDescription]);
//            }
//        }
//        @catch (NSException *exception) {
//            return NO;
//        }
//    } else {
//        NSLog(@"SETTING EARPIECE");
//        @try {
//            BOOL success;
//            AVAudioSession *session = [AVAudioSession sharedInstance];
//            NSError *error = nil;
//            
//            success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
//            if (success) {
//                NSLog(@"AVAudioSession overrideOutputAudioPort to none OK");
//                return YES;
//            }else{
//                return NO;
//                NSLog(@"AVAudioSession error overrideOutputAudioPort to none: %@", [error localizedDescription]);
//            }
//        }
//        @catch (NSException *exception) {
//            NSLog(@"---NOT OK: %@", [exception description]);
//            return NO;
//        }
//    }
//}

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
