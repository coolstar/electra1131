#import "ViewController.h"
#include "codesign.h"
#include "electra.h"
#include "sploit.h"
#include "electra_objc.h"

@interface ViewController ()

@end

static ViewController *currentViewController;

@implementation ViewController

void checkIntegrity(void);
void checkInjection(void);

#define K_ENABLE_TWEAKS "enableTweaks"

mach_port_t tfp0 = MACH_PORT_NULL;

+ (instancetype)currentViewController {
    return currentViewController;
}

- (void)checkVersion {
    NSString *rawgitHistory = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"githistory" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    __block NSArray *gitHistory = [rawgitHistory componentsSeparatedByString:@"\n"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://coolstar.org/electra/gitlatest.txt"]];
        // User isn't on a network, or the request failed
        if (data == nil) return;
        
        NSString *gitCommit = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (![gitHistory containsObject:gitCommit]){
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Update Available!" message:@"An update for Electra is available! Please visit https://coolstar.org/electra/ on a computer to download the latest IPA!" preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            });
        }
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self checkVersion];
    
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    
    BOOL enable3DTouch = YES;
    
    if (kCFCoreFoundationVersionNumber < 1445.32 || kCFCoreFoundationVersionNumber > 1452.23){
        [_jailbreak setEnabled:NO];
        [_enableTweaks setEnabled:NO];
        [_jailbreak setTitle:@"Version Error" forState:UIControlStateNormal];
        
        enable3DTouch = NO;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@K_ENABLE_TWEAKS] == nil) {
        [userDefaults setBool:YES forKey:@K_ENABLE_TWEAKS];
        [userDefaults synchronize];
    }
    BOOL enableTweaks = [userDefaults boolForKey:@K_ENABLE_TWEAKS];
    [_enableTweaks setOn:enableTweaks];
    
    uint32_t flags;
    csops(getpid(), CS_OPS_STATUS, &flags, 0);
    
    checkIntegrity();
    
    if ((flags & CS_PLATFORM_BINARY)){
        [_jailbreak setEnabled:NO];
        [_enableTweaks setEnabled:NO];
        [_jailbreak setTitle:@"Already Jailbroken" forState:UIControlStateNormal];
        enable3DTouch = NO;
    } else {
        checkInjection();
    }
    if (enable3DTouch){
        [notificationCenter addObserver:self selector:@selector(doit:) name:@"Jailbreak" object:nil];
    }
    
  // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)credits:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Credits" message:@"Thanks to CoolStar, Ian Beer, theninjaprawn, stek29, Siguza, xerub, PyschoTea and Pwn20wnd.\n\nElectra includes the following software:\n\nAPFS snapshot workaround by SparkZheng and bxl1989\nAPFS snapshot persistence patch by Pwn20wnd and ur0\namfid patch by theninjaprawn\njailbreakd & tweak injection by CoolStar\nunlocknvram & sandbox fixes by stek29" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (IBAction)doit:(id)sender {
    [_jailbreak setEnabled:NO];
    [_enableTweaks setEnabled:NO];
    
    currentViewController = self;
    
    [_jailbreak setTitle:@"Please Wait (1/3)" forState:UIControlStateNormal];
    
    BOOL shouldEnableTweaks = [_enableTweaks isOn];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        kern_return_t ret = multi_path_go();
        
        if (ret != KERN_SUCCESS) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_jailbreak setTitle:@"Error: exploit" forState:UIControlStateNormal];
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_jailbreak setTitle:@"Please Wait (2/3)" forState:UIControlStateNormal];
        });
        
        int jailbreakstatus = start_electra(tfp0, shouldEnableTweaks);
        
        if (jailbreakstatus == ERR_NOERR){
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setTitle:@"Jailbroken" forState:UIControlStateNormal];
                
                UIAlertController *openSSHRunning = [UIAlertController alertControllerWithTitle:@"OpenSSH Running" message:@"OpenSSH is now running! Enjoy." preferredStyle:UIAlertControllerStyleAlert];
                [openSSHRunning addAction:[UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [openSSHRunning dismissViewControllerAnimated:YES completion:nil];
                    exit(0);
                }]];
                [self presentViewController:openSSHRunning animated:YES completion:nil];
            });
        } else if (jailbreakstatus == ERR_TFP0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setTitle:@"Error: tfp0" forState:UIControlStateNormal];
            });
        } else if (jailbreakstatus == ERR_ALREADY_JAILBROKEN) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setTitle:@"Already Jailbroken" forState:UIControlStateNormal];
            });
        } else if (jailbreakstatus == ERR_AMFID_PATCH) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setTitle:@"Error: amfid patch" forState:UIControlStateNormal];
            });
        } else if (jailbreakstatus == ERR_SNAPSHOT) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setTitle:@"Error: snapshot failed" forState:UIControlStateNormal];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setTitle:@"Error Jailbreaking" forState:UIControlStateNormal];
            });
        }
        
        NSLog(@" ♫ KPP never bothered me anyway... ♫ ");
    });
}

NSString *_urlForUsername(NSString *user) {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"aphelion://"]]) {
        return [@"aphelion://profile/" stringByAppendingString:user];
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]]) {
        return [@"tweetbot:///user_profile/" stringByAppendingString:user];
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific://"]]) {
        return [@"twitterrific:///profile?screen_name=" stringByAppendingString:user];
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings://"]]) {
        return [@"tweetings:///user?screen_name=" stringByAppendingString:user];
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
        return [@"twitter://user?screen_name=" stringByAppendingString:user];
    } else {
        return [@"https://mobile.twitter.com/" stringByAppendingString:user];
    }
    return nil;
}

- (IBAction)tappedOnHyperlink:(id)sender {
    [sender setAlpha:0.7];
    UIApplication *application = [UIApplication sharedApplication];
    NSString *str = _urlForUsername(@"Electra_Team");
    NSURL *URL = [NSURL URLWithString:str];
    [application openURL:URL options:@{} completionHandler:nil];
    [sender setAlpha:1.0];
}

- (void)removingLiberiOS {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_jailbreak setTitle:@"Removing liberiOS" forState:UIControlStateNormal];
    });
}

- (void)installingCydia {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_jailbreak setTitle:@"Installing Cydia" forState:UIControlStateNormal];
    });
}

- (void)cydiaDone {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_jailbreak setTitle:@"Please Wait (2/3)" forState:UIControlStateNormal];
    });
}

- (void)displaySnapshotNotice {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_jailbreak setTitle:@"user prompt" forState:UIControlStateNormal];
        UIAlertController *apfsNoticeController = [UIAlertController alertControllerWithTitle:@"APFS Snapshot Created" message:@"An APFS Snapshot has been successfully created! You may be able to use SemiRestore to restore your phone to this snapshot in the future." preferredStyle:UIAlertControllerStyleAlert];
        [apfsNoticeController addAction:[UIAlertAction actionWithTitle:@"Continue Jailbreak" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [_jailbreak setTitle:@"Please Wait (2/3)" forState:UIControlStateNormal];
            snapshotWarningRead();
        }]];
        [self presentViewController:apfsNoticeController animated:YES completion:nil];
    });
}

- (void)displaySnapshotWarning {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_jailbreak setTitle:@"user prompt" forState:UIControlStateNormal];
        UIAlertController *apfsWarningController = [UIAlertController alertControllerWithTitle:@"APFS Snapshot Not Found" message:@"Warning: Your device was bootstrapped using a pre-release version of Electra and thus does not have an APFS Snapshot present. While Electra may work fine, you will not be able to use SemiRestore to restore to stock if you need to. Please clean your device and re-bootstrap with this version of Electra to create a snapshot." preferredStyle:UIAlertControllerStyleAlert];
        [apfsWarningController addAction:[UIAlertAction actionWithTitle:@"Continue Jailbreak" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [_jailbreak setTitle:@"Please Wait (2/3)" forState:UIControlStateNormal];
            snapshotWarningRead();
        }]];
        [self presentViewController:apfsWarningController animated:YES completion:nil];
    });
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (IBAction)enableTweaksChanged:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL enableTweaks = [_enableTweaks isOn];
    [userDefaults setBool:enableTweaks forKey:@K_ENABLE_TWEAKS];
    [userDefaults synchronize];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
