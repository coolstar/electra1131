#import <UIKit/UIKit.h>
#import "CSGradientView.h"

@interface ViewController : UIViewController {
    IBOutlet UIImageView *_logoView;
    IBOutlet UIStackView *_jailbreakButtonStackView;
    IBOutlet UIStackView *_creditsLabelStackView;
    IBOutlet UIView *_bottomPanelView;
    IBOutlet UIView *_tweaksContainerView;
}

@property (weak, nonatomic) IBOutlet UIButton *jailbreak;
@property (weak, nonatomic) IBOutlet UISwitch *enableTweaks;
+ (instancetype)currentViewController;
- (void)installingCydia;
- (void)cydiaDone;
- (void)displaySnapshotNotice;
- (void)displaySnapshotWarning;

@end

