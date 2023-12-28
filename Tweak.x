#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <rootless.h>
#import "YouTubeHeader/YTIElementRenderer.h"

#define LOC(x) [tweakBundle localizedStringForKey:x value:nil table:nil]

NSBundle *tweakBundle;

@class YTSettingsCell;

@interface YTSettingsSectionItem : NSObject
@property (nonatomic) BOOL hasSwitch;
@property (nonatomic) BOOL switchVisible;
@property (nonatomic) BOOL on;
@property (nonatomic, copy) BOOL (^switchBlock)(YTSettingsCell *, BOOL);
@property (nonatomic) int settingItemId;
- (instancetype)initWithTitle:(NSString *)title titleDescription:(NSString *)titleDescription;
@end

@interface _ASCollectionViewCell : UICollectionViewCell
- (id)node;
@end

@interface YTAsyncCollectionView : UICollectionView
@end

@interface YTCommentNode : NSObject
@end

extern NSBundle *YTNoCommunityPostsBundle();

NSBundle *YTNoCommunityPostsBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"YTNoCommunityPosts" ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:ROOT_PATH_NS(@"/Library/Application Support/YTNoCommunityPosts.bundle")];
    });
    return bundle;
}

%ctor {
    tweakBundle = YTNoCommunityPostsBundle();
}

%hook YTSettingsViewController
- (void)setSectionItems:(NSMutableArray <YTSettingsSectionItem *> *)sectionItems forCategory:(NSInteger)category title:(NSString *)title titleDescription:(NSString *)titleDescription headerHidden:(BOOL)headerHidden {

    if (category == 1) {
        YTSettingsSectionItem *commpost = [[%c(YTSettingsSectionItem) alloc] initWithTitle:LOC(@"HIDE_COMMUNITY_POSTS") titleDescription:LOC(@"HIDE_COMMUNITY_POSTS_DESC")];
        commpost.hasSwitch = YES;
        commpost.switchVisible = YES;
        commpost.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_comm_posts"];
        commpost.switchBlock = ^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"hide_comm_posts"];
            return YES;
        };
        [sectionItems addObject:commpost];
    }
    %orig(sectionItems, category, title, titleDescription, headerHidden);
}
%end

%hook YTIElementRenderer
- (NSData *)elementData {
    BOOL hideCommunityPosts = [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_comm_posts"];
    if (hideCommunityPosts && [[self description] containsString:@"post_base_wrapper.eml"]) {
        return nil;
    }
    return %orig;
}
%end

%hook YTIElementRendererCompatibilityOptions
- (BOOL)hasUseBackstageCellControllerOnIos {
    BOOL hideCommunityPosts = [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_comm_posts"];
    if (hideCommunityPosts) {
        return NO;
    }
    return %orig;
}
%end
