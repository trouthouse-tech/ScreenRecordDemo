//
//  RecordComponent.m
//  ScreenRecord
//
//  Created by Matthew Ruiz on 3/30/21.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>

@interface RCT_EXTERN_MODULE(RecordComponent, RCTViewManager)
RCT_EXTERN_METHOD(
  showSaveView:(nonnull NSNumber *)node
  fileName:(NSString *)
)
@end
