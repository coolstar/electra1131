#import <UIKit/UIKit.h>

@interface ViewController : UIViewController {
    IBOutlet UIImageView *_logoView;
    IBOutlet UIStackView *_jailbreakButtonStackView;
    IBOutlet UIStackView *_creditsLabelStackView;
    IBOutlet UIView *_bottomPanelView;
    IBOutlet UIView *_tweaksContainerView;
}

@property (weak, nonatomic) IBOutlet UIButton *jailbreak;
@property (weak, nonatomic) IBOutlet UISwitch *enableTweaks;
@property (weak, nonatomic) IBOutlet UILabel *compatibilityLabel;
+ (instancetype)currentViewController;
- (void)removingLiberiOS;
- (void)installingCydia;
- (void)cydiaDone;
- (void)displaySnapshotNotice;
- (void)displaySnapshotWarning;

@end

