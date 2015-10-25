//
//  PjSIPNotifications.h
//  pjsiptest
//
//  Created by CRISTIAN MOLDOVAN on 19/10/2015.
//  Copyright © 2015 CRISTIAN MOLDOVAN. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Defines notification names
#define PJConstDefine(name_) extern NSString *const name_;

PJConstDefine(PJSIPRegistrationStateDidChangeNotification);
PJConstDefine(PJSIPRegistrationDidStartNotification);
PJConstDefine(PJSIPCallStateDidChangeNotification);
PJConstDefine(PJSIPIncomingCallNotification);
PJConstDefine(PJSIPCallMediaStateDidChangeNotification);
PJConstDefine(PJSIPVolumeDidChangeNotification);
PJConstDefine(PJSIPMWINotification);
PJConstDefine(PJSIPPagerNotification);
PJConstDefine(PJSIPPagerUpdateNotification);

PJConstDefine(PJVolumeDidChangeNotification);

PJConstDefine(PJSIPAccountIdKey);
PJConstDefine(PJSIPRenewKey);
PJConstDefine(PJSIPCallIdKey);
PJConstDefine(PJSIPDataKey);
PJConstDefine(PJSIPMwiInfoMimeTypeKey);
PJConstDefine(PJSIPMwiInfoContentKey);
PJConstDefine(PJSIPPagerFromKey);
PJConstDefine(PJSIPPagerToKey);
PJConstDefine(PJSIPPagerContactKey);
PJConstDefine(PJSIPPagerMimeTypeKey);
PJConstDefine(PJSIPPagerBodyKey);
PJConstDefine(PJSIPPagerStatusCodeKey);
PJConstDefine(PJSIPPagerStatusToKey);
PJConstDefine(PJSIPPagerStatusReasonKey);

PJConstDefine(PJVolumeKey);
PJConstDefine(PJMicVolumeKey);


// helper macros
#define PJNotifGetInt(notif_, key_) ([[[notif_ userInfo] objectForKey:key_] intValue])
#define PJNotifGetBool(notif_, key_) ([[[notif_ userInfo] objectForKey:key_] boolValue])
#define PJNotifGetString(info_, key_) ((NSString *)[[notif_ userInfo] objectForKey:key_])