#import <SpringBoard/SBIconController.h>
#import <Foundation/Foundation.h>
#import "NSTask.h"
#import <objc/runtime.h>
#import <AudioToolbox/AudioServices.h>
#import <sys/utsname.h>
#ifndef SIMULATOR
#import <Cephei/HBPreferences.h>
#endif

#ifdef DEBUG
	#define DLog(fmt, ...) NSLog((fmt), ##__VA_ARGS__);
#else
	#define DLog(...)
#endif

#define IS_IOS13_AND_UP ([[UIDevice currentDevice].systemVersion floatValue] >= 13.0)

@interface SBSApplicationShortcutItem : NSObject <NSCopying>

@property (nonatomic,copy) NSString * type;
@property (nonatomic,copy) NSString * localizedTitle;
@property (nonatomic,copy) NSString * pathStr;
@property (nonatomic,copy) NSString * localizedSubtitle;
@property (nonatomic,copy) NSString * bundleIdentifierToLaunch;

@end

//iOS 11/12 only
@interface SBUIAppIconForceTouchControllerDataProvider : NSObject

-(NSString *)applicationBundleIdentifier;

@end 
//end iOS 11/12 only


//iOS 13 only
@interface SBIconView : UIView

-(id)applicationBundleIdentifier;
-(id)applicationBundleIdentifierForShortcuts;

@end
//end iOS 13 only


@interface UIApplication (Custom)

-(BOOL)_openURL:(id)arg1 ;

@end


@interface SBIcon : NSObject
- (id)badgeNumberOrString;
- (void)setBadge:(id)arg1;
@end

@interface SBLeafIcon : SBIcon
- (id)applicationBundleID;
@end

@interface SBFolderIcon : SBIcon
-(id)folder;
@end

@interface SBIconModel : NSObject
- (id)leafIcons;
@end
