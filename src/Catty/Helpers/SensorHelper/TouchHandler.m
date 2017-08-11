/**
 *  Copyright (C) 2010-2017 The Catrobat Team
 *  (http://developer.catrobat.org/credits)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  An additional term exception under section 7 of the GNU Affero
 *  General Public License, version 3, is available at
 *  (http://developer.catrobat.org/license_additional_term)
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see http://www.gnu.org/licenses/.
 */

#import "TouchHandler.h"

@interface TouchHandler()

@property (nonatomic) UILongPressGestureRecognizer* touchRecognizer;
@property (nonatomic) NSMutableArray* rawTouchLog;

@end


@implementation TouchHandler

static TouchHandler* shared = nil;

+ (instancetype)shared
{
    @synchronized(self) {
        if (shared == nil) {
            shared = [[[self class] alloc] init];
        }
    }
    return shared;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.touchRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapsFrom:)];
        self.touchRecognizer.minimumPressDuration = 0;
        self.touchRecognizer.cancelsTouchesInView = false;
        [[UIApplication sharedApplication].keyWindow addGestureRecognizer: self.touchRecognizer];
        self.touchRecognizer.delegate = self;
        self.touchRecognizer.enabled = false;
        [self resetData];
    }
    
    return self;
}

- (void)resetData
{
    self.lastFingerPosition = CGPointMake(0, 0);
    self.screenIsTouched = false;
    self.firstScreenTouch = false;
    self.rawTouchLog = [NSMutableArray new];
}

- (void)startTrackingTouchesForScene:(CBScene*)scene
{
    self.scene = scene;
    self.touchRecognizer.enabled = true;
    [self resetData];
}

- (void)startTrackingTouches
{
    self.touchRecognizer.enabled = true;
    [self resetData];
}

- (void)resumeTrackingTouches
{
    self.touchRecognizer.enabled = true;
}

- (void)stopTrackingTouches
{
    self.touchRecognizer.enabled = false;
}

- (void) handleTapsFrom:(UILongPressGestureRecognizer*)gestureRecognizer
{
    
    UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
    CGPoint position = [gestureRecognizer locationInView: appWindow];
    
    self.lastFingerPosition = position;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.screenIsTouched = true;
        self.firstScreenTouch = self.rawTouchLog.count == 0;
        [self.rawTouchLog addObject: [NSValue valueWithCGPoint:position]];
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        self.screenIsTouched = false;
        self.firstScreenTouch = false;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    //Without this, other required gestures (like the left slide out control strip) are blocked.
    return YES;
}

- (CGPoint)getPositionInSceneForTouchNumber:(unsigned long)touchNumber
{
    CGPoint position = CGPointMake(0, 0);
    if (self.rawTouchLog.count != 0 && touchNumber <= self.rawTouchLog.count)
    {
        if (touchNumber > 0)    //Position of touch logged at index touchNumber - 1
        {
            position = [[self.rawTouchLog objectAtIndex:touchNumber-1] CGPointValue];
        }
        else if (touchNumber == 0)  //Act as sensor
        {
            position = self.lastFingerPosition;
        }
        //Setting origin to center of screen
        if(self.scene != nil)
        {
            position = [CBSceneHelper convertRawSceneCoordinateToScene:position sceneSize: self.scene.size];
        }
        else
        {
            UIWindow *appWindow = [UIApplication sharedApplication].keyWindow;
            position = [CBSceneHelper convertPointToScene:position sceneSize: appWindow.bounds.size];
        }
    }
    return position;
}

- (unsigned long)numberOfTouches
{
    return self.rawTouchLog.count;
}

@end
