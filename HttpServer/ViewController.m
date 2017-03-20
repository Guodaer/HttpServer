//
//  ViewController.m
//  HttpServer
//
//  Created by X-Designer on 17/3/17.
//  Copyright © 2017年 Guoda. All rights reserved.
//

#import "ViewController.h"
#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "MyHttpConnection.h"


#include <arpa/inet.h>
#include <netdb.h>
#include <net/if.h>
#include <ifaddrs.h>
#import <dlfcn.h>
//#import "wwanconnect.h//frome apple 你可能没有哦
#import <SystemConfiguration/SystemConfiguration.h>


static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface ViewController ()
{
   	HTTPServer *httpServer;
}

@end

@implementation ViewController
- (NSString *) localWiFiIPAddress
{
    BOOL success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    success = getifaddrs(&addrs) == 0;
    if (success) {
        cursor = addrs;
        while (cursor != NULL) {
            // the second test keeps from picking up the loopback address
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                if ([name isEqualToString:@"en0"])  // Wi-Fi adapter
                    return [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return nil;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%@",[self localWiFiIPAddress]);
    // Do any additional setup after loading the view, typically from a nib.
    // Configure our logging framework.
    // To keep things simple and fast, we're just going to log to the Xcode console.
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // Initalize our http server
    httpServer = [[HTTPServer alloc] init];
    
    // Tell the server to broadcast its presence via Bonjour.
    // This allows browsers such as Safari to automatically discover our service.
    [httpServer setType:@"_http._tcp."];
    
    // Normally there's no need to run our server on any specific port.
    // Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
    // However, for easy testing you may want force a certain port so you can just hit the refresh button.
    //	[httpServer setPort:12345];
    
    // Serve files from the standard Sites folder
    NSString *docRoot = [[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"web"] stringByDeletingLastPathComponent];
    DDLogInfo(@"Setting document root: %@", docRoot);
    
    [httpServer setDocumentRoot:docRoot];
    
    [httpServer setConnectionClass:[MyHttpConnection class]];
    
    NSError *error = nil;
    if(![httpServer start:&error])
    {
        DDLogError(@"Error starting HTTP Server: %@", error);
    }

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
