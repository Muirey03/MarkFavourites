#import "interfaces.h"

inline UIImage* heartImage(BOOL on)
{
    NSString* name;
    if (on)
        name = @"PUFavoriteOn";
    else
        name = @"PUFavoriteOff";
    NSBundle* bundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/PhotosUI.framework"];
    return [UIImage imageNamed:name inBundle:bundle];
}

static UIBarButtonItem* favButton;

%hook UIToolbar
-(void)setItems:(NSArray*)items animated:(BOOL)arg2
{
    BOOL hasShare = NO;
    BOOL hasAdd = NO;
    BOOL hasTrash = NO;
    for (UIBarButtonItem* item in items)
    {
        if (sel_isEqual(item.action, @selector(_shareButtonPressed:)))
        {
            hasShare = YES;
            continue;
        }
        if (sel_isEqual(item.action, @selector(_addButtonPressed:)))
        {
            hasAdd = YES;
            continue;
        }
        if (sel_isEqual(item.action, @selector(_removeButtonPressed:)))
        {
            hasTrash = YES;
            continue;
        }
    }

    if (hasShare && hasAdd && hasTrash)
    {
        /* Add favourite button: */
        //remove old spaces:
        NSMutableArray<UIBarButtonItem*>* newItems = [items mutableCopy];
        for (int i = 0; i < newItems.count; i++)
        {
            if (newItems[i].systemItem == UIBarButtonSystemItemFlexibleSpace)
            {
                [newItems removeObjectAtIndex:i];
                i--;
            }
        }

        //add button:
        UINavigationController* navCont = [self _viewControllerForAncestor];
        PUPhotosGridViewController* target;
        for (id vc in navCont.childViewControllers)
        {
            if ([vc isKindOfClass:%c(PUPhotosGridViewController)])
            {
                target = vc;
                break;
            }
        }
        favButton = [[UIBarButtonItem alloc] initWithImage:heartImage(NO) style:UIBarButtonItemStylePlain target:nil action:@selector(_favouriteButtonPressed:)];
        favButton.enabled = NO;
        [newItems insertObject:favButton atIndex:2];

        //add new spaces:
        for (int i = 0; i < 3; i++)
        {
            UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            NSUInteger index = 2 * i + 1;
            [newItems insertObject:space atIndex:index];
        }

        items = [newItems copy];
    }
    %orig;
}
%end

%hook PUPhotosGridViewController
%new
-(void)_favouriteButtonPressed:(id)arg1
{
    NSMutableArray<PHAsset*>* assets = [self selectedAssets];
    __block BOOL newValue = NO;
    for (PHAsset* asset in assets)
    {
        if (!asset.favorite)
        {
            newValue = YES;
            break;
        }
    }
    [[%c(PHPhotoLibrary) sharedPhotoLibrary] performChanges:^{
        for (PHAsset* asset in assets)
        {
            PHAssetChangeRequest* request = [%c(PHAssetChangeRequest) changeRequestForAsset:asset];
            request.favorite = newValue;
        }
    } completionHandler:nil];
    [self setEditing:NO animated:YES];
}

-(void)setSelected:(BOOL)arg1 itemsAtIndexes:(id)arg2 inSection:(unsigned long long)arg3 animated:(BOOL)arg4
{
    %orig;
    if (!favButton.target)
        favButton.target = self;
    if ([self selectedAssets].count)
    {
        favButton.enabled = YES;
        BOOL on = YES;
        for (PHAsset* asset in [self selectedAssets])
        {
            if (!asset.favorite)
            {
                on = NO;
                break;
            }
        }
        favButton.image = heartImage(on);
    }
    else
    {
        favButton.enabled = NO;
        favButton.image = heartImage(NO);
    }
}
%end
