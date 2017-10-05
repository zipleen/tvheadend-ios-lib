//
//  TVHService.h
//  TvhClient
//
//  Created by Luis Fernandes on 09/11/13.
//  Copyright (c) 2013 Luis Fernandes. 
//


#import "TVHPlayStreamDelegate.h"

@class TVHServer;
@class TVHChannel;

@interface TVHService : NSObject <TVHPlayStreamDelegate>
@property (strong, nonatomic) NSString *id;
//@property NSInteger channel;
@property NSInteger pmt;
@property NSInteger pcr;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *typestr;
@property NSInteger typenum;

@property (strong, nonatomic) NSString *provider;
@property (strong, nonatomic) NSString *mux;
@property (strong, nonatomic) NSString *satconf;
@property (strong, nonatomic) NSString *channelname;
@property (strong, nonatomic) NSString *dvb_charset;
@property NSInteger dvb_eit_enable;
@property NSInteger prefcapid;

// shared
@property (strong, nonatomic) NSString *network;
@property NSInteger sid;
@property (strong, nonatomic) NSString *svcname;
@property NSInteger enabled;
@property (nonatomic, strong) NSArray *channel;

// 4.0
@property (strong, nonatomic) NSString *uuid;
@property (strong, nonatomic) NSString *multiplex;
@property NSInteger lcn;
@property (strong, nonatomic) NSString *cridauth;
@property NSInteger dvb_servicetype;
@property NSInteger encrypted;

- (id)initWithTvhServer:(TVHServer*)tvhServer;
- (void)updateValuesFromDictionary:(NSDictionary*)values;
- (void)updateValuesFromService:(TVHService*)service;
- (NSComparisonResult)compareByName:(TVHService *)otherObject;
- (TVHChannel*)mappedChannel;
@end
