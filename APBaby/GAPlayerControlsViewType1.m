//
//  Created by Tom Susel on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GAPlayerControlsViewType1.h"
#import <MediaPlayer/MediaPlayer.h>
#import "APCustomPlayerResourceHelper.h"
#import "UILabel+APBabyCustomization.h"

@interface GAPlayerControlsViewType1 ()

@property (nonatomic,strong) NSMutableDictionary *currentPlayingItemDict;
@property (nonatomic,strong) APPlayerController *playerController;

- (void)hideParentControlls;
- (void)playerDidStop:(NSNotification*)aNotification;

@end


@implementation GAPlayerControlsViewType1

//_volume view uses for airplay mode
@synthesize volumeView = _volumeView;

#pragma mark -
#pragma mark NSObject

- (id)init {
    id mainView;
    self = [super init];
    if (self) {
        // Initialization code.
        mainView = [[NSBundle bundleForClass:self.class] loadNibNamed:NSStringFromClass(self.class) owner:self options:nil].firstObject;
    }
    return mainView;
}

- (void)awakeFromNib{
	[super awakeFromNib];
	_sequenceButtonView.delegate = self;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(playerDidStop:)
												 name:APApplicasterPlayerDidStopNotification
											   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFavoriteButton)
                                                 name:APLocalFavoritesDidRemoveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFavoriteButton)
                                                 name:APLocalFavoritesDidAddNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadButton)
                                                 name:APHqmeDidRemoveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDownloadButton)
                                                 name:APHqmeDidAddNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDownloadFinished)
                                                 name:APVodItemHqmeCompletedNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidStart:)
                                                 name:APApplicasterPlayerDidStartNotification
                                               object:nil];


	
	[self show:NO];
    [self.stopButton setImage:[APCustomPlayerResourceHelper
                               imageNamed:@"baby_player_stop_btn"]                     forState:UIControlStateNormal];
    [self.pauseButton setImage:[APCustomPlayerResourceHelper
                                imageNamed:@"baby_player_pause_btn"]                      forState:UIControlStateNormal];
    [self.playButton setImage:[APCustomPlayerResourceHelper
                               imageNamed:@"baby_player_play_btn"]
                     forState:UIControlStateNormal];

    self.volumeView.showsVolumeSlider = NO;
    [self.volumeView setRouteButtonImage:[APCustomPlayerResourceHelper
                                          imageNamed:@"baby_player_airplay_btn_off"]
                                forState:UIControlStateNormal];
    [self.volumeView setRouteButtonImage:[APCustomPlayerResourceHelper
                                          imageNamed:@"baby_player_airplay_btn_on"]
                                forState:UIControlStateSelected];
    
    for (id subView in self.volumeView.subviews) {
        if ([subView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subView;
            [button addTarget:self action:@selector(airButtonDidPushed) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    [self.playerForwardButton setImage:[APCustomPlayerResourceHelper
                               imageNamed:@"baby_player_forward_btn"]
                     forState:UIControlStateNormal];
    [self.playerBackwardButton setImage:[APCustomPlayerResourceHelper
                               imageNamed:@"baby_player_backward_btn"]
                     forState:UIControlStateNormal];
    [self.playerForwardButton setImage:[APCustomPlayerResourceHelper
                                        imageNamed:@"baby_player_forward_btn_disabled"]
                              forState:UIControlStateDisabled];
    [self.playerBackwardButton setImage:[APCustomPlayerResourceHelper
                                         imageNamed:@"baby_player_backward_btn_disabled"]
                               forState:UIControlStateDisabled];

    [self updateInstructionsView];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	_sequenceButtonView.delegate = nil;
    _playerController = nil;
}

#pragma mark - current played vod item
- (APVodItem *)currentVodItem {
    APVodItem *vodItem = nil;
    id<ZPPlayable> playable = self.playerController.currentItem;
    if ([playable isKindOfClass:[APVodItem class]]) {
        vodItem = (APVodItem *)playable;
    }
    return vodItem;
}

#pragma mark -
#pragma mark UIView

-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	UIView *hitView = [super hitTest:point withEvent:event];
	if (hitView == self){
		//Hide the parent controlls if visible
		if (_parentControls.alpha > 0.0){
			[self hideParentControlls];	
		}
		
		// This makes the background view touchable
		hitView = nil;
	}
	
	return hitView;
}

#pragma mark - APPlayerControls

- (void)hide:(BOOL)animated {
	
}

- (void)show:(BOOL)animated {
    
}

- (BOOL)isVisible {
	return NO;
}

- (void)setBuffering:(BOOL)buffering {
    
}

#pragma mark - APPlayerControls Protocol

- (void)videoContentDidStartPlayingWithItem:(NSDictionary *)playingItemInfo{
    BOOL isLive = [[playingItemInfo objectForKey:kAPPlayerControlsPlayingItemIsLive] boolValue];
    if (isLive) {
        [self.favoriteButton setHidden:YES];
        [self.downloadButton setHidden:YES];
    } else {
        self.currentPlayingItemDict = [[NSMutableDictionary alloc] initWithDictionary:playingItemInfo];
        [self updateFavoriteImage];
        [self updateDownloadImage];
    }
    
    if (self.playerController.playableItems.count <= 1){
        [self.playerBackwardButton setHidden:YES];
        [self.playerForwardButton setHidden:YES];
    }
    else{
        [self.playerBackwardButton setHidden:NO];
        [self.playerForwardButton setHidden:NO];

        if (self.playerController.currentItemIndex == 0){
            [self.playerBackwardButton setEnabled:NO];
            [self.playerForwardButton setEnabled:YES];
        }
        else if (self.playerController.currentItemIndex == (self.playerController.playableItems.count - 1)){
            [self.playerForwardButton setEnabled:NO];
            [self.playerBackwardButton setEnabled:YES];
        }
        else{
            [self.playerBackwardButton setEnabled:YES];
            [self.playerForwardButton setEnabled:YES];
        }
    }
   
   
}


#pragma mark - action buttons

- (IBAction)favoriteButtonTapped:(id)sender {
    if (self.currentPlayingItemDict) {
        if ([self isLocalFavorite]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:APPlayerControllerRemoveFromFavorites object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:APPlayerControllerAddToFavorites object:nil];
        }
    }
}

- (IBAction)downloadButtonTapped:(id)sender {
    switch ([self.currentVodItem itemHqmeState]) {
            case ZPHqmeItemStateNotExists:
            //add to download
            [self.currentVodItem markForHqmeProcess];
            break;
            case ZPHqmeItemStateCompleted:
            [self.currentVodItem deleteFromCache];
            break;
            case ZPHqmeItemStateInProgress:
            [self.currentVodItem cancelHqmeProcess];
            break;
    }
}

#pragma mark - private helper methods
- (void)updateInstructionsView {
    self.instructionsView.hidden = YES;
    self.instuctionsImageView.image = [APCustomPlayerResourceHelper imageNamed:@"player_insructions_background_image"];
    [self.instructionsLabel setLabelStyleForKey:@"ParentLockPlayerControlsViewInstructionLabel"];
    self.instructionsLabel.text = [@"Press and hold for 2 seconds" withKey:@"ParentLockPlayerInstructions"];

}
- (void)updateFavoriteButton {
    if (self.currentPlayingItemDict) {
        //mark the vod as favorite only if it is not already been marked, we are doing that by checking the vod's old isFavorite state
        NSNumber *shouldMarkedAsLocalFavorite = [NSNumber numberWithBool:(![self isLocalFavorite])];
        //update the vod's isfavorite state to it's new state
        [self.currentPlayingItemDict setObject:shouldMarkedAsLocalFavorite forKey:kAPPlayerControllerPlayingItemIsFavorite];
        //update the favorite button's image according to the new state
        [self updateFavoriteImage];
    }
}
- (BOOL)isCurrentPlayedItemNotDownloaded {
    return [self.currentVodItem itemHqmeState] == ZPHqmeItemStateNotExists;
}

- (BOOL)isCurrentPlayedItemDeletable {
    return [self.currentVodItem notDeleteable] == NO;
}

- (void)updateDownloadButton {
    if (self.currentPlayingItemDict) {
        //check if it is already been clicked
        NSNumber *shouldMarkForDownload = @([self isCurrentPlayedItemNotDownloaded]);
        [self.currentPlayingItemDict setObject:shouldMarkForDownload forKey:kAPPlayerControllerPlayingItemHqmeInProgress];
        [self.currentPlayingItemDict setObject:[NSNumber numberWithBool:NO] forKey:kAPPlayerControllerPlayingItemHqmeInProgress];
        [self updateDownloadImage];
    }
}

- (void)updateFavoriteImage {
    NSString *favoriteImageName = [self isLocalFavorite]? @"baby_player_favorite_btn_active": @"baby_player_favorite_btn_not_active";
    [self.favoriteButton setImage:[APCustomPlayerResourceHelper
                                   imageNamed:favoriteImageName]
                         forState:UIControlStateNormal];
}

- (void)updateDownloadImage {

    BOOL shouldEnableButton = ([self isCurrentPlayedItemNotDownloaded] || [self isCurrentPlayedItemDeletable]);
    self.downloadButton.userInteractionEnabled = shouldEnableButton;
    NSString *downloadImageName = ([self isCurrentPlayedItemNotDownloaded])? @"baby_player_download_btn": @"baby_player_download_btn_active";
    if (shouldEnableButton == NO) {
        downloadImageName = @"baby_player_download_btn_disabled";
    }
    [self.downloadButton setImage:[APCustomPlayerResourceHelper
                                   imageNamed:downloadImageName] forState:UIControlStateNormal];

}


- (void)handleDownloadFinished {
    [self.currentPlayingItemDict setObject:[NSNumber numberWithBool:YES] forKey:kAPPlayerControllerPlayingItemHqmeCompleted];
    [self.currentPlayingItemDict setObject:[NSNumber numberWithBool:NO]  forKey:kAPPlayerControllerPlayingItemHqmeInProgress];
    [self updateDownloadImage];
}

- (BOOL)isLocalFavorite {
    return [[self.currentPlayingItemDict objectForKey:kAPPlayerControllerPlayingItemIsFavorite] boolValue];
}

#pragma mark -
#pragma mark BTVOfflineOverlayView - private

- (void)hideParentControlls{

  
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(parentContrllsDidFade:finished:context:)];
	[UIView setAnimationDuration:0.3];
	
	_parentControls.alpha = 0.0;

	[UIView commitAnimations];
    
}

- (void)parentContrllsDidFade:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	//Show the parents controls

	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDelegate:self];
	
	_sequenceButtonView.alpha = 1.0;
	
	[UIView commitAnimations];	
}

- (void)playerDidStart:(NSNotification*)aNotification{
    if ([aNotification.object isKindOfClass:[APPlayerController class]]){
        self.playerController = (APPlayerController *)aNotification.object;
    }
}

- (void)playerDidStop:(NSNotification*)aNotification{
	if (_parentControls.alpha > 0.0){
		[self hideParentControlls];
	}
	
    [_sequenceButtonView stopAutomaticSequence]; //press stop and return to the vod fast (before 7 sec) the button is still animating
}

#pragma mark -
#pragma mark BTVSequenceButtonViewDelegate

- (void)sequenceButtonViewDidManuallyStart:(GAControlerSequencedButtonView*)sequenceButtonView {
    //show instrunctions view
    [self updateInstructionsViewVisibility:YES];
}

- (void)sequenceButtonViewDidManuallyStop:(GAControlerSequencedButtonView*)sequenceButtonView {
    //hide instrunctions view
    [self updateInstructionsViewVisibility:NO];
}

- (void)sequenceButtonViewDidManuallyComplete:(GAControlerSequencedButtonView*)sequenceButtonView{
	[_sequenceButtonView startAutomaticSequence];
    
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:0.3];
	
	_parentControls.alpha = 1.0;

    //hide instructions view
    [self updateInstructionsViewVisibility:NO];

	[UIView commitAnimations];	
}

- (void)sequenceButtonViewDidAutoComplete:(GAControlerSequencedButtonView*)sequenceButtonView{
	[self hideParentControlls];
}

- (void)buttonTappedDuringAutoSequence:(GAControlerSequencedButtonView *)sequenceButtonView{
	[self hideParentControlls];
}

- (void)airButtonDidPushed {
    [_sequenceButtonView stopAutomaticSequence];
}

#pragma mark -
#pragma mark NSCoding


- (id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]){
    }
    
    return self;
}

#pragma mark -
#pragma mark Instructions view
- (void)updateInstructionsViewVisibility:(BOOL)shouldShow {
    if (!self.shouldShowInstructionMessage) {
        return;
    }
    self.instructionsView.alpha = (shouldShow) ? 1.0 : 0.0;
    self.instructionsView.hidden = !shouldShow;
}
@end

