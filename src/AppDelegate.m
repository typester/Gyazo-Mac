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

    NSString *command = [NSString stringWithFormat:@"f=%@\n/usr/sbin/screencapture -i $f 2>/dev/null\n/usr/bin/sips -g dpiWidth -g dpiHeight -g pixelWidth -g pixelHeight $f | /usr/bin/awk -v imagefile=$f '$1==\"dpiWidth:\" {dpiWidth = $2}\n$1==\"dpiHeight:\" {dpiHeight = $2}\n$1==\"pixelWidth:\" {pixelWidth = $2}\n$1==\"pixelHeight:\" {pixelHeight = $2}\nEND {\n  if (dpiWidth != 72 || dpiHeight != 72) {\n    w = int(pixelWidth * 72 / dpiWidth)\n    h = int(pixelHeight * 72 / dpiHeight)\n    cmd = sprintf(\"/usr/bin/sips %%s -s dpiWidth 72 -s dpiHeight 72 -z %%d %%d >/dev/null 2>&1\", imagefile, h, w)\n    system(cmd)\n  }\n}'", tmpFile];
    [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", command, nil]];
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
        [[NSApplication sharedApplication] terminate:self];
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
    [[NSApplication sharedApplication] terminate:self];
}

-(void)requestFailed:(ASIHTTPRequest*)request {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, [request error]);
    NSAlert* alert = [NSAlert alertWithError:[request error]];
    [alert runModal];
    self.req = nil;

    [[NSFileManager defaultManager] removeItemAtPath:self.imagePath error:nil];
    [[NSApplication sharedApplication] terminate:self];
}

@end
