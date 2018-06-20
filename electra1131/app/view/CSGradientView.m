#import "CSGradientView.h"
#import <QuartzCore/QuartzCore.h>

@implementation CSGradientView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self){
        CAGradientLayer *layer = (CAGradientLayer *)self.layer;
        layer.startPoint = CGPointMake(0, 0);
        layer.endPoint = CGPointMake(1, 1);
        layer.colors = @[(id)[[UIColor colorWithRed:32.5f/255.0f green:41.2f/255.0f blue:46.3f/255.0f alpha:1.0f] CGColor], (id)[[UIColor colorWithRed:83.0f/255.0f green:105.0f/255.0f blue:118.0f/255.0f alpha:1.0f] CGColor]];
    }
    return self;
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
