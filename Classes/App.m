#import "App.h"

#import "NSURL+L0URLParsing.h"

#define kDefaultsPathKey @"path"
#define kDefaultPath @"/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl"

@implementation App

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
  NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
  [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  [NSUserDefaults.standardUserDefaults registerDefaults:@{kDefaultsPathKey:kDefaultPath}];
  // TODO Show preferences when not opened from protocol;
}

-(void)awakeFromNib
{
  [super awakeFromNib];
}

/**
 * Handles URLs with format subl://open/?url=file:///path/to/file&line=11&column=2
 * Both line and col are optional.
 */
-(void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
  NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
  
  if ([url.host isEqualToString:@"open"]) {
    NSDictionary *params = [url dictionaryByDecodingQueryString];
    NSString *fileURI = [params objectForKey:@"url"];
    
    if (fileURI) {
      NSString *fileName = [fileURI componentsSeparatedByString:@"://"][1];
      NSString *line = [params objectForKey:@"line"];
      NSString *column = [params objectForKey:@"column"];
      
      NSTask *task = [[NSTask alloc] init];
      [task setLaunchPath:self.sublimePath];
      NSString* filePath = [NSString stringWithFormat:@"%@:%ld:%ld", fileName, line ? [line integerValue] : 1, [column integerValue]];
      task.arguments = @[filePath];
      [task launch];
      NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
      NSString *appPath = [sharedWorkspace fullPathForApplication:@"Sublime Text 2"];
      NSFileManager *fileManager = [NSFileManager new];
      if (![fileManager isReadableFileAtPath:appPath]) {
        appPath = [sharedWorkspace fullPathForApplication:@"Sublime Text"];
      }
      NSString *identifier = [[NSBundle bundleWithPath:appPath] bundleIdentifier];
      NSArray *selectedApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:identifier];
      NSRunningApplication *runningApp = (NSRunningApplication*)[selectedApps objectAtIndex:0];
      [runningApp activateWithOptions:NSApplicationActivateAllWindows];
    }
  }
  
  if (!prefPanel.isVisible) {
    [NSApp terminate:self];
  }
}

-(IBAction)showPrefPanel:(id)sender
{
  [textField setStringValue:self.sublimePath];
  [prefPanel makeKeyAndOrderFront:nil];
}

-(IBAction)applyChange:(id)sender
{
  NSString *path = [textField stringValue];
  if (path) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:path forKey:kDefaultsPathKey];
  }
  
  [prefPanel orderOut:nil];
}

- (IBAction)restoreDefaultPath:(id)sender
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:kDefaultPath forKey:kDefaultsPathKey];
  textField.stringValue = kDefaultPath;
}

- (NSString *)sublimePath
{
  return [NSUserDefaults.standardUserDefaults stringForKey:kDefaultsPathKey];
}

@end
