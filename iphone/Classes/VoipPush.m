//
//  VoipPush.m
//  TiSIP
//
//  Created by CRISTIAN MOLDOVAN on 04/11/2015.
//
//

#import "VoipPush.h"

@implementation VoipPush

+ (VoipPush *)sharedProxy {
    static dispatch_once_t onceToken;
    static VoipPush *proxy = nil;
    dispatch_once(&onceToken, ^{ proxy = [[VoipPush alloc] init]; });
    
    return proxy;
}

- (id)init {
    self = [super init];
    
    return self;
}

- (void) register{
    PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushRegistry.delegate = self;
    pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type{
    if([credentials.token length] == 0) {
        NSLog(@"voip token NULL");
        NSDictionary *info = nil;
        info = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSString stringWithFormat:@"emptytoken"],@"status", nil];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center postNotificationName:@"REGISTER.FAILED"
                              object:self
                            userInfo:info];
//        NSString *eventName = @"PUSH.REGISTER.FAILED";
//        NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
//                                     [NSString stringWithFormat:@"emptytoken"],@"status", nil];
//        [self fireEvent:eventName withObject:eventObject];
        return;
    }
    NSString* token = [[[NSString stringWithFormat:@"%@",credentials.token]
                           stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"VoipProxy token: %@", token);
    NSDictionary *info = nil;
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            token,@"token", nil];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:@"REGISTER.SUCCESS"
                          object:self
                        userInfo:info];
    
//    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 [NSString stringWithString:pushToken],@"token", nil];
//    [self fireEvent:eventName withObject:eventObject];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    NSLog(@"didReceiveIncomingPushWithPayload");
    NSDictionary *info = nil;
    info = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSDictionary dictionaryWithDictionary:payload.dictionaryPayload],@"data", nil];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:@"PUSH.RECEIVED"
                          object:self
                        userInfo:info];
//    NSDictionary *eventObject = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 [NSDictionary dictionaryWithDictionary:payload.dictionaryPayload],@"data",
//                                 [NSString stringWithString:payload.type], nil];
//    [self fireEvent:eventName withObject:eventObject];
    
    NSLog(@"IncomingPushWithPayload");
}



@end
