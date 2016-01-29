//
//  PjSIPDispatch.m
//  pjsiptest
//
//  Created by CRISTIAN MOLDOVAN on 19/10/2015.
//  Copyright © 2015 CRISTIAN MOLDOVAN. All rights reserved.
//

#import "PjSIPDispatch.h"
#import "PjSIPNotifications.h"
#import "PJUtil.h"

void onRegistrationStarted(pjsua_acc_id accountId, pj_bool_t renew);
void onRegistrationState(pjsua_acc_id accountId);
void onIncomingCall(pjsua_acc_id accountId, pjsua_call_id callId, pjsip_rx_data *rdata);
void onCallMediaState(pjsua_call_id callId);
void onCallState(pjsua_call_id callId, pjsip_event *e);
void onMwiInfo(pjsua_acc_id accountId, pjsua_mwi_info *mwi_info);
void onPager(pjsua_call_id call_id, const pj_str_t *from, const pj_str_t *to, const pj_str_t *contact, const pj_str_t *mime_type, const pj_str_t *body, pjsip_rx_data *rdata, pjsua_acc_id acc_id);
void onPagerStatus(pjsua_call_id call_id, const pj_str_t *to, const pj_str_t *body, void *user_data, pjsip_status_code status, const pj_str_t *reason, pjsip_tx_data *tdata, pjsip_rx_data *rdata, pjsua_acc_id acc_id);


static dispatch_queue_t _queue = NULL;

@implementation PjSIPDispatch

+ (void)initialize {
    _queue = dispatch_queue_create("PjSIPDispatch", DISPATCH_QUEUE_SERIAL);
}

+ (void)configureCallbacksForAgent:(pjsua_config *)uaConfig {
    uaConfig->cb.on_reg_started = &onRegistrationStarted;
    uaConfig->cb.on_reg_state = &onRegistrationState;
    uaConfig->cb.on_incoming_call = &onIncomingCall;
    uaConfig->cb.on_call_media_state = &onCallMediaState;
    uaConfig->cb.on_call_state = &onCallState;
    uaConfig->cb.on_mwi_info = &onMwiInfo;
    uaConfig->cb.on_pager = &onPager;
    uaConfig->cb.on_pager_status2 = &onPagerStatus;
}

#pragma mark - Dispatch sink

// TODO: May need to implement some form of subscriber filtering
//   orthogonaly/globally if we're to scale. But right now a few
//   dictionary lookups on the receiver side probably wouldn't hurt much.

+ (void)dispatchRegistrationStarted:(pjsua_acc_id)accountId renew:(pj_bool_t)renew {
    
    NSDictionary *info = nil;
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:accountId], PJSIPAccountIdKey,
            [NSNumber numberWithBool:renew], PJSIPRenewKey, nil];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:PJSIPRegistrationDidStartNotification
                          object:self
                        userInfo:info];
}

+ (void)dispatchRegistrationState:(pjsua_acc_id)accountId {
    
    NSDictionary *info = nil;
    info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:accountId]
                                       forKey:PJSIPAccountIdKey];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:PJSIPRegistrationStateDidChangeNotification
                          object:self
                        userInfo:info];
}

+ (void)dispatchIncomingCall:(pjsua_acc_id)accountId
                      callId:(pjsua_call_id)callId
                        data:(pjsip_rx_data *)data {
    
    NSDictionary *info = nil;
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:accountId], PJSIPAccountIdKey,
            [NSNumber numberWithInt:callId], PJSIPCallIdKey,
            [NSValue valueWithPointer:data], PJSIPDataKey, nil];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:PJSIPIncomingCallNotification
                          object:self
                        userInfo:info];
}

+ (void)dispatchCallMediaState:(pjsua_call_id)callId {
    
    pjsua_call_info ci;
    
    pjsua_call_get_info(callId, &ci);
    
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
        // When media is active, connect call to sound device.
        pjsua_conf_connect(ci.conf_slot, 0);
        pjsua_conf_connect(0, ci.conf_slot);
    }

    
    NSDictionary *info = nil;
    info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:callId]
                                       forKey:PJSIPCallIdKey];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:PJSIPCallMediaStateDidChangeNotification
                          object:self
                        userInfo:info];
}

+ (void)dispatchCallState:(pjsua_call_id)callId
                    event:(pjsip_event *)e {
    
    NSDictionary *info = nil;
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:callId], PJSIPCallIdKey,
            [NSValue valueWithPointer:e], PJSIPDataKey, nil];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:PJSIPCallStateDidChangeNotification
                          object:self
                        userInfo:info];
}

+ (void)dispatchPagerInfo:(pjsua_call_id)callId
                     from: (pj_str_t *)from
                       to: (pj_str_t *)to
                  contact: (pj_str_t *)contact
                 mimeType: (pj_str_t *)mime_type
                     body: (pj_str_t *)body
                accountId: (pjsua_acc_id)accountId{

    NSDictionary *info = nil;
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:accountId], PJSIPAccountIdKey,
            [NSString stringWithString:[PJUtil stringWithPJString:from]], PJSIPPagerFromKey,
            [NSString stringWithString:[PJUtil stringWithPJString:to]], PJSIPPagerToKey,
            [NSString stringWithString:[PJUtil stringWithPJString:contact]], PJSIPPagerContactKey,
            [NSString stringWithString:[PJUtil stringWithPJString:mime_type]], PJSIPPagerMimeTypeKey,
            [NSString stringWithString:[PJUtil stringWithPJString:body]], PJSIPPagerBodyKey, nil];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:PJSIPPagerNotification
                          object:self
                        userInfo:info];
    
}

+ (void)dispatchPagerStatus:(pjsua_call_id)callId
                         to:(pj_str_t *)to
                     status:(pjsip_status_code)status
                     reason:(pj_str_t *)reason
                  accountId:(pjsua_acc_id) accountId{
    
    
    NSDictionary *info = nil;
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:accountId], PJSIPAccountIdKey,
            [NSNumber numberWithInt:(int) status], PJSIPPagerStatusCodeKey,
            [NSString stringWithString:[PJUtil stringWithPJString:to]], PJSIPPagerStatusToKey,
            [NSString stringWithString:[PJUtil stringWithPJString:reason]], PJSIPPagerStatusReasonKey, nil];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:PJSIPPagerUpdateNotification
                          object:self
                        userInfo:info];
}

+ (void)dispatchMwiInfo:(pjsua_acc_id)accountId
                  event:(pjsua_mwi_info *)mwi_info {
    
    pj_str_t body;
    pj_str_t mime_type;
    char mime_type_c[80];
    
    // Ignore empty messages
    if (!mwi_info->rdata->msg_info.msg->body) {
        body = pj_str("");
    }
    
    // Get the mime type
    if (mwi_info->rdata->msg_info.ctype) {
        const pjsip_ctype_hdr *ctype = mwi_info->rdata->msg_info.ctype;
        pj_ansi_snprintf(mime_type_c, sizeof(mime_type_c),
                         "%.*s/%.*s",
                         (int)ctype->media.type.slen,
                         ctype->media.type.ptr,
                         (int)ctype->media.subtype.slen,
                         ctype->media.subtype.ptr);
    }
    
    
    body.ptr = (char *) mwi_info->rdata->msg_info.msg->body->data;
    body.slen = mwi_info->rdata->msg_info.msg->body->len;
    
    // Ignore empty messages
    if (body.slen == 0){
        return;
    }
    
    mime_type = pj_str(mime_type_c);
    
    NSString *bodyContent;
    NSString *mimeType;
    
    bodyContent = [PJUtil stringWithPJString:&body];
    mimeType = [PJUtil stringWithPJString:&mime_type];
    
    NSDictionary *info = nil;
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:accountId], PJSIPAccountIdKey,
            [NSString stringWithString:bodyContent], PJSIPMwiInfoContentKey,
            [NSString stringWithString:mimeType], PJSIPMwiInfoMimeTypeKey,nil];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:PJSIPMWINotification
                          object:self
                        userInfo:info];
}

@end

#pragma mark - C event bridge

// Bridge C-land callbacks to ObjC-land.

static inline void dispatch(dispatch_block_t block) {
    // autorelease here since events wouldn't be triggered that often.
    // + GCD autorelease pool do not have drainage time guarantee (== possible mem headaches).
    // See the "Implementing tasks using blocks" section for more info
    // REF: http://developer.apple.com/library/ios/#documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationQueues/OperationQueues.html
    @autoreleasepool {
        
        // NOTE: Needs to use dispatch_sync() instead of dispatch_async() because we do not know
        //   the lifetime of the stuff being given to us by PJSIP (e.g. pjsip_rx_data*) so we
        //   must process it completely before the method ends.
        dispatch_sync(_queue, block);
    }
}


void onRegistrationStarted(pjsua_acc_id accountId, pj_bool_t renew) {
    dispatch(^{ [PjSIPDispatch dispatchRegistrationStarted:accountId renew:renew]; });
}

void onRegistrationState(pjsua_acc_id accountId) {
    dispatch(^{ [PjSIPDispatch dispatchRegistrationState:accountId]; });
}

void onIncomingCall(pjsua_acc_id accountId, pjsua_call_id callId, pjsip_rx_data *rdata) {
    pjsua_call_answer(callId,180, NULL, NULL);

    dispatch(^{ [PjSIPDispatch dispatchIncomingCall:accountId callId:callId data:rdata]; });
}

void onCallMediaState(pjsua_call_id callId) {
    dispatch(^{ [PjSIPDispatch dispatchCallMediaState:callId]; });
}

void onCallState(pjsua_call_id callId, pjsip_event *e) {
    dispatch(^{ [PjSIPDispatch dispatchCallState:callId event:e]; });
}

void onMwiInfo(pjsua_acc_id accountId, pjsua_mwi_info *mwi_info){
    dispatch(^{ [PjSIPDispatch dispatchMwiInfo:accountId event:mwi_info]; });
}

void onPager(pjsua_call_id call_id, const pj_str_t *from, const pj_str_t *to, const pj_str_t *contact, const pj_str_t *mime_type, const pj_str_t *body, pjsip_rx_data *rdata, pjsua_acc_id acc_id){
    dispatch(^{ [PjSIPDispatch dispatchPagerInfo:call_id from:from to:to contact:contact mimeType:mime_type body:body accountId:acc_id]; });
}

void onPagerStatus(pjsua_call_id call_id, const pj_str_t *to, const pj_str_t *body, void *user_data, pjsip_status_code status, const pj_str_t *reason, pjsip_tx_data *tdata, pjsip_rx_data *rdata, pjsua_acc_id acc_id){
    dispatch(^{[PjSIPDispatch dispatchPagerStatus:call_id to:to status:status reason:reason accountId: acc_id];});
}
