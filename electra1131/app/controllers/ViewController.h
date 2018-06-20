#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *jailbreak;
@property (weak, nonatomic) IBOutlet UISwitch *enableTweaks;
+ (instancetype)currentViewController;
- (void)installingCydia;
- (void)cydiaDone;
- (void)displaySnapshotNotice;
- (void)displaySnapshotWarning;

@end

