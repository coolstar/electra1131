#import "ViewController.h"
#include "codesign.h"
#include "electra.h"
#include "multi_path_sploit.h"
#include "vfs_sploit.h"
#include "electra_objc.h"
#include "kmem.h"
#include "offsets.h"
#include <sys/sysctl.h>
#include "file_utils.h"
#include "electra_objc.h"

@interface ViewController ()
@end

static ViewController *currentViewController;

@implementation ViewController

#define localize(key) NSLocalizedString(key, @"")
#define postProgress(prg) [[NSNotificationCenter defaultCenter] postNotificationName: @"JB" object:nil userInfo:@{@"JBProgress": prg}]

#define ELECTRA_URL "https://coolstar.org/electra/"
#define ELECTRA_TEAM_TWITTER_HANDLE "Electra_Team"
#define K_ENABLE_TWEAKS "enableTweaks"

+ (instancetype)currentViewController {
    return currentViewController;
}

// thx DoubleH3lix

double uptime(){
    struct timeval boottime;
    size_t len = sizeof(boottime);
    int mib[2] = { CTL_KERN, KERN_BOOTTIME };
    if( sysctl(mib, 2, &boottime, &len, NULL, 0) < 0 )
    {
        return -1.0;
    }
    time_t bsec = boottime.tv_sec, csec = time(NULL);
    
    return difftime(csec, bsec);
}

-(void)updateProgressFromNotification:(id)sender{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *prog=[sender userInfo][@"JBProgress"];
        NSLog(@"Progress: %@",prog);
        [_jailbreak setEnabled:NO];
        [_jailbreak setAlpha:0.5];
        [_enableTweaks setEnabled:NO];
        [_setNonce setEnabled:NO];
        [_jailbreak setTitle:prog forState:UIControlStateNormal];
    });
}

- (void)checkVersion {
    NSString *rawgitHistory = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"githistory" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    __block NSArray *gitHistory = [rawgitHistory componentsSeparatedByString:@"\n"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://coolstar.org/electra/gitlatest-1131.txt"]];
        // User isn't on a network, or the request failed
        if (data == nil) return;
        
        NSString *gitCommit = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (![gitHistory containsObject:gitCommit]){
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Update Available!" message:[NSString stringWithFormat:localize(@"An update for Electra is available! Please visit %@ on a computer to download the latest IPA!"), @ELECTRA_URL] preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:localize(@"OK") style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            });
        }
    });
}

- (void)shareElectra {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:localize(@"I am using the Electra Jailbreak Toolkit for iOS 11.2 - 11.3.1 by the @%@ to jailbreak my %@ on iOS %@! You can get it now at %@"), @ELECTRA_TEAM_TWITTER_HANDLE, [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], @ELECTRA_URL]] applicationActivities:nil];
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAirDrop, UIActivityTypeOpenInIBooks, UIActivityTypeMarkupAsPDF];
    if ([activityViewController respondsToSelector:@selector(popoverPresentationController)] ) {
        activityViewController.popoverPresentationController.sourceView = _jailbreak;
    }
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgressFromNotification:) name:@"JB" object:nil];
    
#if ELECTRADEBUG
#else  /* !ELECTRADEBUG */
    [self checkVersion];
#endif /* !ELECTRADEBUG */
    
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    
    BOOL enable3DTouch = YES;
    
    switch (offsets_init()) {
        case ERR_NOERR: {
            break;
        }
        case ERR_VERSION: {
            [_jailbreak setEnabled:NO];
            [_jailbreak setAlpha:0.5];
            [_enableTweaks setEnabled:NO];
            [_jailbreak setTitle:localize(@"Version Error") forState:UIControlStateNormal];
            
            enable3DTouch = NO;
            break;
        }
            
        default: {
            [_jailbreak setEnabled:NO];
            [_jailbreak setAlpha:0.5];
            [_enableTweaks setEnabled:NO];
            [_jailbreak setTitle:localize(@"Error: offsets") forState:UIControlStateNormal];
            
            enable3DTouch = NO;
            break;
        }
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@K_ENABLE_TWEAKS] == nil) {
        [userDefaults setBool:YES forKey:@K_ENABLE_TWEAKS];
        [userDefaults synchronize];
    }
    BOOL enableTweaks = [userDefaults boolForKey:@K_ENABLE_TWEAKS];
    [_enableTweaks setOn:enableTweaks];
    
    if (file_exists("/.bootstrapped_electra")) {
        [_jailbreak setTitle:localize(@"Enable Jailbreak") forState:UIControlStateNormal];
    }
    
    uint32_t flags;
    csops(getpid(), CS_OPS_STATUS, &flags, 0);
    
    if ((flags & CS_PLATFORM_BINARY)) {
        [_enableTweaks setEnabled:NO];
        [_jailbreak setTitle:localize(@"Share Electra") forState:UIControlStateNormal];
        
        enable3DTouch = NO;
    }
    if (enable3DTouch) {
        [notificationCenter addObserver:self selector:@selector(doit:) name:@"Jailbreak" object:nil];
    }
    
    NSString *string = [NSString stringWithFormat:@"%@\niOS 11.2 — 11.3.1", localize(@"Compatible with")];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15 weight:UIFontWeightRegular] range:[string rangeOfString:localize(@"Compatible with")]];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:0.3f] range:[string rangeOfString:localize(@"Compatible with")]];
    
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16 weight:UIFontWeightBold] range:[string rangeOfString:@"iOS 11.2 "]];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f] range:[string rangeOfString:@"iOS 11.2 "]];
    
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16 weight:UIFontWeightMedium] range:[string rangeOfString:@"—"]];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f] range:[string rangeOfString:@"—"]];
    
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16 weight:UIFontWeightBold] range:[string rangeOfString:@" 11.3.1"]];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f] range:[string rangeOfString:@" 11.3.1"]];
    
    [_compatibilityLabel setAttributedText:attributedString];
    
  // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)credits:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:localize(@"Credits") message:localize(@"Thanks to Ian Beer, theninjaprawn, stek29, Siguza, xerub, PsychoTea and Pwn20wnd.\n\nElectra includes the following software:\n\nAPFS snapshot mitigation bypass by CoolStar and Pwn20wnd\nliboffsetfinder64 & libimg4tool by tihmstar\nlibplist by libimobiledevice\namfid patch by theninjaprawn\njailbreakd & tweak injection by CoolStar\nunlocknvram & sandbox fixes by stek29") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:localize(@"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)doit:(id)sender {
    uint32_t flags;
    csops(getpid(), CS_OPS_STATUS, &flags, 0);
    if ((flags & CS_PLATFORM_BINARY)) {
        [self shareElectra];
        return;
    }
    
    [sender setEnabled:NO];
    [_enableTweaks setEnabled:NO];
    
    currentViewController = self;
    
    postProgress(localize(@"Please Wait (1/3)"));
    
    BOOL shouldEnableTweaks = [_enableTweaks isOn];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        
        int ut = 0;
        while ((ut = 50 - uptime()) > 0) {
            NSString *msg = [NSString stringWithFormat:localize(@"Waiting: %d seconds"), ut];
            postProgress(msg);
            sleep(1);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            postProgress(localize(@"Please Wait (1/3)"));
        });
        
#if WANT_VFS
        int exploitstatus = vfs_sploit();
#else /* !WANT_VFS */
        int exploitstatus = multi_path_go();
#endif /* !WANT_VFS */
        
        switch (exploitstatus) {
            case ERR_NOERR: {
                postProgress(localize(@"Please Wait (2/3)"));
                break;
            }
            case ERR_EXPLOIT: {
                postProgress(localize(@"Error: exploit"));
                return;
            }
            case ERR_UNSUPPORTED: {
                postProgress(localize(@"Error: unsupported"));
                return;
            }
            default:
                postProgress(localize(@"Error Exploiting"));
                return;
        }
        
        int jailbreakstatus = start_electra(tfp0, shouldEnableTweaks);
        
        switch (jailbreakstatus) {
            case ERR_NOERR: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    postProgress(localize(@"Jailbroken"));
                    
                    UIAlertController *openSSHRunning = [UIAlertController alertControllerWithTitle:localize(@"OpenSSH Running") message:localize(@"OpenSSH is now running! Enjoy.") preferredStyle:UIAlertControllerStyleAlert];
                    [openSSHRunning addAction:[UIAlertAction actionWithTitle:localize(@"Exit") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        [openSSHRunning dismissViewControllerAnimated:YES completion:nil];
                        exit(0);
                    }]];
                    [self presentViewController:openSSHRunning animated:YES completion:nil];
                });
                break;
            }
            case ERR_TFP0: {
                postProgress(localize(@"Error: tfp0"));
                break;
            }
            case ERR_ALREADY_JAILBROKEN: {
                postProgress(localize(@"Already Jailbroken"));
                break;
            }
            case ERR_AMFID_PATCH: {
                postProgress(localize(@"Error: amfid patch"));
                break;
            }
            case ERR_ROOTFS_REMOUNT: {
                postProgress(localize(@"Error: rootfs remount"));
                break;
            }
            case ERR_SNAPSHOT: {
                postProgress(localize(@"Error: snapshot failed"));
                break;
            }
            case ERR_CONFLICT: {
                postProgress(localize(@"Error: conflict"));
                break;
            }
            default: {
                postProgress(localize(@"Error Jailbreaking"));
                break;
            }
        }
        
        NSLog(@" ♫ KPP never bothered me anyway... ♫ ");
    });
}

- (IBAction)tappedOnSetNonce:(id)sender {
    __block NSString *generatorToSet = nil;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:localize(@"Set the system boot nonce on jailbreak") message:localize(@"Enter the generator for the nonce you want the system to generate on boot") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:localize(@"Cancel") style:UIAlertActionStyleDefault handler:nil]];
    UIAlertAction *set = [UIAlertAction actionWithTitle:localize(@"Set") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
         const char *generatorInput = [alertController.textFields.firstObject.text UTF8String];
         char compareString[22];
         uint64_t rawGeneratorValue;
         sscanf(generatorInput, "0x%16llx",&rawGeneratorValue);
         sprintf(compareString, "0x%016llx", rawGeneratorValue);
         if(strcmp(compareString, generatorInput) != 0) {
             UIAlertController *alertController = [UIAlertController alertControllerWithTitle:localize(@"Error") message:localize(@"Failed to validate generator") preferredStyle:UIAlertControllerStyleAlert];
             [alertController addAction:[UIAlertAction actionWithTitle:localize(@"OK") style:UIAlertActionStyleDefault handler:nil]];
             [self presentViewController:alertController animated:YES completion:nil];
             return;
         }
        generatorToSet = [NSString stringWithUTF8String:generatorInput];
        [userDefaults setObject:generatorToSet forKey:@K_GENERATOR];
        [userDefaults synchronize];
        uint32_t flags;
        csops(getpid(), CS_OPS_STATUS, &flags, 0);
        UIAlertController *alertController = nil;
        if ((flags & CS_PLATFORM_BINARY)) {
            alertController = [UIAlertController alertControllerWithTitle:localize(@"Notice") message:localize(@"The system boot nonce will be set the next time you enable your jailbreak") preferredStyle:UIAlertControllerStyleAlert];
        } else {
            alertController = [UIAlertController alertControllerWithTitle:localize(@"Notice") message:localize(@"The system boot nonce will be set once you enable the jailbreak") preferredStyle:UIAlertControllerStyleAlert];
        }
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
     }];
    [alertController addAction:set];
    [alertController setPreferredAction:set];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = [NSString stringWithFormat:@"%s", genToSet()];
    }];
    [self presentViewController:alertController animated:YES completion:nil];
}

NSString *getURLForUsername(NSString *user) {
    UIApplication *application = [UIApplication sharedApplication];
    if ([application canOpenURL:[NSURL URLWithString:@"tweetbot://"]]) {
        return [@"tweetbot:///user_profile/" stringByAppendingString:user];
    } else if ([application canOpenURL:[NSURL URLWithString:@"twitterrific://"]]) {
        return [@"twitterrific:///profile?screen_name=" stringByAppendingString:user];
    } else if ([application canOpenURL:[NSURL URLWithString:@"tweetings://"]]) {
        return [@"tweetings:///user?screen_name=" stringByAppendingString:user];
    } else if ([application canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
        return [@"twitter://user?screen_name=" stringByAppendingString:user];
    } else {
        return [@"https://mobile.twitter.com/" stringByAppendingString:user];
    }
    return nil;
}

- (IBAction)tappedOnHyperlink:(id)sender {
    UIApplication *application = [UIApplication sharedApplication];
    NSString *str = getURLForUsername(@ELECTRA_TEAM_TWITTER_HANDLE);
    NSURL *URL = [NSURL URLWithString:str];
    [application openURL:URL options:@{} completionHandler:nil];
}

- (void)removingLiberiOS {
    postProgress(localize(@"Removing liberiOS"));
}

- (void)installingCydia {
    postProgress(localize(@"Installing Cydia"));
}

- (void)cydiaDone {
    postProgress(localize(@"Please Wait (2/3)"));
}

- (void)displaySnapshotNotice {
    dispatch_async(dispatch_get_main_queue(), ^{
        postProgress(localize(@"user prompt"));
        UIAlertController *apfsNoticeController = [UIAlertController alertControllerWithTitle:localize(@"APFS Snapshot Created") message:localize(@"An APFS Snapshot has been successfully created! You may be able to use SemiRestore to restore your phone to this snapshot in the future.") preferredStyle:UIAlertControllerStyleAlert];
        [apfsNoticeController addAction:[UIAlertAction actionWithTitle:localize(@"Continue Jailbreak") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            postProgress(localize(@"Please Wait (2/3)"));
            snapshotWarningRead();
        }]];
        [self presentViewController:apfsNoticeController animated:YES completion:nil];
    });
}

- (void)displaySnapshotWarning {
    dispatch_async(dispatch_get_main_queue(), ^{
        postProgress(localize(@"user prompt"));
        UIAlertController *apfsWarningController = [UIAlertController alertControllerWithTitle:localize(@"APFS Snapshot Not Found") message:localize(@"Warning: Your device was bootstrapped using a pre-release version of Electra and thus does not have an APFS Snapshot present. While Electra may work fine, you will not be able to use SemiRestore to restore to stock if you need to. Please clean your device and re-bootstrap with this version of Electra to create a snapshot.") preferredStyle:UIAlertControllerStyleAlert];
        [apfsWarningController addAction:[UIAlertAction actionWithTitle:@"Continue Jailbreak" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            postProgress(localize(@"Please Wait (2/3)"));
            snapshotWarningRead();
        }]];
        [self presentViewController:apfsWarningController animated:YES completion:nil];
    });
}

- (void)restarting {
    postProgress(localize(@"Restarting"));
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
