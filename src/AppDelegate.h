#import <Cocoa/Cocoa.h>

#import "ASIHTTPRequest.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, ASIHTTPRequestDelegate>

@property (assign) IBOutlet NSWindow* window;
@property (assign) IBOutlet NSTextField* urlField;
@property (assign) IBOutlet NSTextField* userField;
@property (assign) IBOutlet NSTextField* passField;

@property (nonatomic, copy) NSString* imagePath;
@property (nonatomic, retain) ASIHTTPRequest* req;

@end
