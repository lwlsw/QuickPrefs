#import "Tweak.h"

#ifndef SIMULATOR
HBPreferences *preferences;
#endif

BOOL enabled;
NSString *item1;
NSString *item2;
NSString *item3;
NSString *item4;
NSString *item5;
NSString *item6;
NSString *item7;
NSString *item8;
BOOL quickPrefsItemsAboveStockItems;
BOOL removeStockItems;
static int deviceModel;

NSMutableArray<NSString*> *itemsList;


static UIViewController* topMostController() {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

// static void showAlert(NSString *myMessage) {
    // UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert" message:myMessage preferredStyle:UIAlertControllerStyleAlert];
    // [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    // [topMostController() presentViewController:alertController animated:YES completion:nil];
// }


int deviceModelNum() {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [[NSString stringWithCString:systemInfo.machine
                                               encoding:NSUTF8StringEncoding] lowercaseString];
    NSArray *deviceArray = [deviceModel componentsSeparatedByString:@","];
	NSString *deviceNum = [[deviceArray firstObject] stringByReplacingOccurrencesOfString:@"iphone" withString:@""];
    
    return [deviceNum intValue];
}

static void safeMode() {
    NSTask *t = [NSTask new];
    [t setLaunchPath:@"/usr/bin/killall"];
    [t setArguments:@[@"-SEGV", @"SpringBoard"]];
    [t launch];
}

static void Respring() {
    NSTask *t = [NSTask new];
    [t setLaunchPath:@"/usr/bin/killall"];
    [t setArguments:@[@"backboardd"]];
    [t launch];
}

static void UIcache() {
    NSTask *t = [NSTask new];
    [t setLaunchPath:@"/usr/bin/uicache"];
    [t launch];
}

static void clearbadge(){
	for (SBLeafIcon *icon in [[[objc_getClass("SBIconController") sharedInstance] model] leafIcons])
	{
		if ([icon isKindOfClass:NSClassFromString(@"SBFolderIcon")])
			continue;

		id badgeNumberOrString = [icon badgeNumberOrString];

		if (!badgeNumberOrString)
			continue;

		[icon setBadge:nil];
		//[icon setBadge:badgeNumberOrString];
	}
	//6s振动方式
 	if(deviceModel == 8){
		//AudioServicesPlaySystemSound(1519);
		AudioServicesPlaySystemSound(1520);
		//AudioServicesPlaySystemSound(1521);
	}else if(deviceModel > 8){	//7以上振动方式
		if(@available(iOS 13.0, *)){
			//7+的震动方式
			UINotificationFeedbackGenerator *feedback = [[UINotificationFeedbackGenerator alloc] init];
			[feedback prepare];
			//success振动方式
			//[feedback notificationOccurred:UINotificationFeedbackTypeSuccess];
			//error振动方式
			[feedback notificationOccurred:UINotificationFeedbackTypeError];
		}
	}

}

static void powerMenu() {
	//菜单形式展示
	UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"请您选择" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    /*
     typedef NS_ENUM(NSInteger, UIAlertActionStyle) {
     UIAlertActionStyleDefault = 0,
     UIAlertActionStyleCancel,         取消按钮
     UIAlertActionStyleDestructive     破坏性按钮，比如：“删除”，字体颜色是红色的
     } NS_ENUM_AVAILABLE_IOS(8_0);
     
     */
    // 创建action，这里action1只是方便编写，以后再编程的过程中还是以命名规范为主
    UIAlertAction *respring = [UIAlertAction actionWithTitle:@"注销" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"注销");
		Respring();
    }];
    UIAlertAction *safemode = [UIAlertAction actionWithTitle:@"安全模式" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"安全模式");
		safeMode();
    }];
    UIAlertAction *uicache = [UIAlertAction actionWithTitle:@"清理图标缓存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"uicache");
		UIcache();
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    
    //把action添加到actionSheet里
    [actionSheet addAction:uicache];
    [actionSheet addAction:safemode];
    [actionSheet addAction:respring];
    [actionSheet addAction:cancel];
    
    //相当于之前的[actionSheet show];
    [topMostController() presentViewController:actionSheet animated:YES completion:nil];
}


static NSString* getPrefsUrlStringFromPathString(NSString* pathString) {
    NSArray *urlPathItems = [pathString componentsSeparatedByString:@"/"];

    NSString *urlString = [NSString stringWithFormat:@"prefs:root=%@", urlPathItems[0]];

    if (urlPathItems.count > 1) {
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&path=%@", urlPathItems[1]]];

        if (urlPathItems.count > 2) {
            urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"/%@", urlPathItems[2]]];
        }
    }

    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];

    return urlString;
}

static NSString* getReadableTitleFromPathString(NSString *pathString) {
    NSString *title = pathString;

    //handle strings containing path
    if ([title containsString:@"/"]) {
		if ([title containsString:@"://"]) {
			NSArray *urlPathItems = [title componentsSeparatedByString:@"://"];
			title = urlPathItems[0];
		}else{
			NSArray *urlPathItems = [title componentsSeparatedByString:@"/"];
			title = urlPathItems[urlPathItems.count - 1];
		}
    }
	

    //handle strings like BATTERY_USAGE
    if ([title containsString:@"_"]) {
        title = [title stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    }

    BOOL isAllUppercase = [title rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]].location == NSNotFound;
    if (isAllUppercase) {
        title = [title capitalizedString];
    }

    return title;
}

static NSArray<SBSApplicationShortcutItem*>* addItemsToStockItems(NSArray<SBSApplicationShortcutItem*>* stockItems) {
    NSMutableArray *stockAndCustomItems = removeStockItems ? @[].mutableCopy : [stockItems mutableCopy];
    if (!stockAndCustomItems) stockAndCustomItems = [NSMutableArray new];

    DLog(@"itemsList %@", itemsList);

    for (NSString *itemName in itemsList) {
        SBSApplicationShortcutItem *item = [[%c(SBSApplicationShortcutItem) alloc] init];
        item.localizedTitle = getReadableTitleFromPathString(itemName);
        item.pathStr = itemName;
        item.bundleIdentifierToLaunch = @"com.apple.Preferences";
        item.type = @"QuickPrefsItem";

        quickPrefsItemsAboveStockItems ? [stockAndCustomItems addObject:item] : [stockAndCustomItems insertObject:item atIndex:0];
    }
    return stockAndCustomItems;
}

static void activateQuickPrefsAction(SBSApplicationShortcutItem* item) {
    if ([item.pathStr.lowercaseString isEqualToString:@"respring"]) {
        Respring();
    } else if ([item.pathStr.lowercaseString isEqualToString:@"注销菜单"]) {
        powerMenu();
    } else if ([item.pathStr.lowercaseString isEqualToString:@"清理角标"]) {
        clearbadge();
    } else if ([item.pathStr.lowercaseString isEqualToString:@"safe mode"]) {
        safeMode();
    } else if ([item.pathStr.lowercaseString isEqualToString:@"uicache"]) {
        UIcache();
    } else if ([item.pathStr.lowercaseString containsString:@"://"]) {
		//打开url scheme
		NSRange range = [item.pathStr rangeOfString:@"://"];
        NSString *urlStr = [item.pathStr substringFromIndex:range.location+3];
		//showAlert(urlStr);
        //urlopen(urlStr);
        NSURL *url = [NSURL URLWithString:urlStr];
		[[UIApplication sharedApplication] _openURL:url];
    } else { //open pref pane
        NSString *urlString = getPrefsUrlStringFromPathString(item.pathStr);
        DLog(@"Should open %@", urlString);

        NSURL*url = [NSURL URLWithString:urlString];

        // if ([[UIApplication sharedApplication] canOpenURL:url]) { //unfortunately returns YES whatever the name is
            [[UIApplication sharedApplication] _openURL:url];
        // } else {
        //     showAlert(@"QuickPrefs cannot open this item. Please double check the name of the tweak and retry.");
        // }
    }
}


%group iOS11_12

%hook SBUIAppIconForceTouchControllerDataProvider

-(NSArray *)applicationShortcutItems {
    NSString *bundleId = [self applicationBundleIdentifier];
    if (![bundleId isEqualToString:@"com.apple.Preferences"]) return %orig;

    NSArray<SBSApplicationShortcutItem*> *stockAndCustomItems = addItemsToStockItems(%orig);
    return stockAndCustomItems;
}

%end //hook SBUIAppIconForceTouchControllerDataProvider


%hook SBUIAppIconForceTouchController

-(void)appIconForceTouchShortcutViewController:(id)arg1 activateApplicationShortcutItem:(SBSApplicationShortcutItem *)item {
    if ([[item type] isEqualToString:@"QuickPrefsItem"]) {
        activateQuickPrefsAction(item);
    }else{

		%orig;
	}
}

%end //hook SBUIAppIconForceTouchController


// %hook SBUIAction

// -(id)initWithTitle:(id)title subtitle:(id)arg2 image:(id)image badgeView:(id)arg4 handler:(/*^block*/id)arg5 {
//     title = getReadableTitleFromPathString(title);

//     return %orig;
// }

// %end //hook SBUIAction

%end //end group iOS11_12


%group iOS13_up

%hook SBSApplicationShortcutItem
%property (nonatomic,copy) NSString * pathStr;
%end

%hook SBIconView

-(NSArray *)applicationShortcutItems {
    NSString *bundleId;
    if ([self respondsToSelector:@selector(applicationBundleIdentifier)]) {
        bundleId = [self applicationBundleIdentifier]; //iOS 13.1.3 (limneos)
    } else if ([self respondsToSelector:@selector(applicationBundleIdentifierForShortcuts)]) {
        bundleId = [self applicationBundleIdentifierForShortcuts]; //iOS 13.2.2 (my test iPhone)
    }
    if (![bundleId isEqualToString:@"com.apple.Preferences"]) return %orig;

    NSArray<SBSApplicationShortcutItem*> *stockAndCustomItems = addItemsToStockItems(%orig);
    return stockAndCustomItems;
}

+(void)activateShortcut:(SBSApplicationShortcutItem*)item withBundleIdentifier:(id)arg2 forIconView:(id)arg3 {
    DLog(@"activateShortcut %@ | %@ | %@", item, arg2, arg3);
    if ([[item type] isEqualToString:@"QuickPrefsItem"]) {
        activateQuickPrefsAction(item);
    }else{
		%orig;
	}
}

%end //hook SBIconView


// %hook _UIContextMenuActionView

// -(id)initWithTitle:(id)title subtitle:(id)arg2 image:(id)arg3 {
//     title = getReadableTitleFromPathString(title);

//     return %orig;
// }

// %end //hook SBUIAction

%end //end group iOS13_up


static BOOL tweakShouldLoad() {
    // https://www.reddit.com/r/jailbreak/comments/4yz5v5/questionremote_messages_not_enabling/d6rlh88/
    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    NSUInteger count = args.count;
    if (count != 0) {
        NSString *executablePath = args[0];
        if (executablePath) {
            NSString *processName = [executablePath lastPathComponent];
            DLog(@"Processname : %@", processName);
            return [processName isEqualToString:@"SpringBoard"];
        }
    }

    return NO;
}

static void addItemToItemsListIfNotNil(NSString *itemName) {
    NSString *trimmedItemName = [itemName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([trimmedItemName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0) {
        [itemsList addObject:trimmedItemName];
    }
}

static void reloadItemsList() {
    DLog(@"reloadItemsList");
    itemsList = @[].mutableCopy;
    if (enabled) {
        addItemToItemsListIfNotNil(item1);
        addItemToItemsListIfNotNil(item2);
        addItemToItemsListIfNotNil(item3);
        addItemToItemsListIfNotNil(item4);
        addItemToItemsListIfNotNil(item5);
        addItemToItemsListIfNotNil(item6);
        addItemToItemsListIfNotNil(item7);
        addItemToItemsListIfNotNil(item8);

        if (quickPrefsItemsAboveStockItems) itemsList = [[itemsList reverseObjectEnumerator] allObjects].mutableCopy;
    }

    DLog(@"new itemsList %@", itemsList);
}

%ctor {
    if (!tweakShouldLoad()) {
        DLog(@"QuickPrefs shouldn't run in this process");
        return;
    }

#ifndef SIMULATOR
    preferences = [[HBPreferences alloc] initWithIdentifier:@"com.anthopak.quickprefs"];
    [preferences registerBool:&enabled default:YES forKey:@"enabled"];
    [preferences registerObject:&item1 default:nil forKey:@"item1"];
    [preferences registerObject:&item2 default:nil forKey:@"item2"];
    [preferences registerObject:&item3 default:nil forKey:@"item3"];
    [preferences registerObject:&item4 default:nil forKey:@"item4"];
    [preferences registerObject:&item5 default:nil forKey:@"item5"];
    [preferences registerObject:&item6 default:nil forKey:@"item6"];
    [preferences registerObject:&item7 default:nil forKey:@"item7"];
    [preferences registerObject:&item8 default:nil forKey:@"item8"];
    [preferences registerBool:&quickPrefsItemsAboveStockItems default:NO forKey:@"quickPrefsItemsAboveStockItems"];
    [preferences registerBool:&removeStockItems default:NO forKey:@"removeStockItems"];

    reloadItemsList();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadItemsList, (CFStringRef)@"com.anthopak.quickprefs/ReloadPrefs", NULL, (CFNotificationSuspensionBehavior)kNilOptions);
#else
    enabled = YES;
    item1 = @"Test";
    reloadItemsList();
#endif

	deviceModel = deviceModelNum();
    if (IS_IOS13_AND_UP) {
        %init(iOS13_up);
    } else {
        %init(iOS11_12);
    }
}
