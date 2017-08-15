//
//  TVHStatusSubscriptionsStoreTests.m
//  tvheadend-ios-lib
//
//  Created by Luis Fernandes on 14/08/2017.
//  Copyright © 2017 zipleen. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TVHTestHelper.h"
#import "TVHServiceStoreA15.h"

@interface TVHServiceStoreTests : XCTestCase

@end

@interface TVHServiceStoreA15 (MyPrivateMethodsUsedForTesting)
@property (nonatomic, strong) NSArray *services;
- (void)fetchedServiceData:(NSData *)responseData;
@end


@implementation TVHServiceStoreTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLoadingBigServicesJson {
    NSData *data = [TVHTestHelper loadFixture:@"Log.services.mine"];
    
    
    
    //[self measureBlock:^{
        TVHServiceStoreA15 *services = [[TVHServiceStoreA15 alloc] init];
        XCTAssertNotNil(services, @"creating tvepg store object");
        
        [services fetchedServiceData:data];
        XCTAssertTrue( ([services.services count] == 29448), @"Failed parsing json data");
    //}];
    
}


@end
