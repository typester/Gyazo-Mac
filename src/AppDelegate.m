#import "AppDelegate.h"

#import "ASIFormDataRequest.h"

@implementation AppDelegate

@synthesize window = window_;
@synthesize urlField = urlField_, userField = userField_, passField = passField_;

@synthesize imagePath = imagePath_;
@synthesize req = req_;

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
    if ([d stringForKey:@"upload-url"]) [self.urlField setStringValue:[d stringForKey:@"upload-url"]];
    if ([d stringForKey:@"username"])   [self.userField setStringValue:[d stringForKey:@"username"]];
    if ([d stringForKey:@"password"])   [self.passField setStringValue:[d stringForKey:@"password"]];

    if (([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSAlternateKeyMask) {
        [self.window orderFront:self];
        return;
    }

    NSString* uploadURL = [d stringForKey:@"upload-url"];
    if (nil == uploadURL) {
        [self.window orderFront:self];
        return;
    }

    // start capture
    NSString* tmpDir = NSTemporaryDirectory();

    NSURL* tmpDirURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                              inDomain:NSUserDomainMask
                                                     appropriateForURL:nil
                                                                create:NO
                                                                 error:nil];
    tmpDir = [tmpDirURL path];

    NSString* tmpFile = [tmpDir stringByAppendingPathComponent:@"capture.png"];

    [[NSFileManager defaultManager] removeItemAtPath:tmpFile error:nil];

    [NSTask launchedTaskWithLaunchPath:@"/usr/sbin/screencapture" arguments:[NSArray arrayWithObjects:@"-i", tmpFile, nil]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(finishedTask:)
                                                 name:NSTaskDidTerminateNotification
                                               object:nil];

    self.imagePath = tmpFile;
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];

    [d setObject:[self.urlField stringValue] forKey:@"upload-url"];
    [d setObject:[self.userField stringValue] forKey:@"username"];
    [d setObject:[self.passField stringValue] forKey:@"password"];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.imagePath = nil;
    self.req = nil;
    [super dealloc];
}

#pragma mark NSNotification

-(void)finishedTask:(NSNotification*)n {
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.imagePath]) {
        NSLog(@"capture image not found");
        return;
    }

    NSUserDefaults* d = [NSUserDefaults standardUserDefaults];

    ASIFormDataRequest* req = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[d stringForKey:@"upload-url"]]];
    if ([[d stringForKey:@"username"] length]) {
        [req setUsername:[d stringForKey:@"username"]];
        [req setPassword:[d stringForKey:@"password"]];
    }
    [req setFile:self.imagePath withFileName:@"gyazo.com"
         andContentType:@"image/png" forKey:@"imagedata"];
    [req setDelegate:self];
    [req startAsynchronous];

    self.req = req;
}

#pragma mark ASIHTTPRequestDelegate

-(void)requestFinished:(ASIHTTPRequest*)request {
    NSURL* u = [NSURL URLWithString:[request responseString]];
    [[NSWorkspace sharedWorkspace] openURL:u];
    self.req = nil;

    [[NSFileManager defaultManager] removeItemAtPath:self.imagePath error:nil];
}

-(void)requestFailed:(ASIHTTPRequest*)request {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, [request error]);
    NSAlert* alert = [NSAlert alertWithError:[request error]];
    [alert runModal];
    self.req = nil;

    [[NSFileManager defaultManager] removeItemAtPath:self.imagePath error:nil];
}

@end
