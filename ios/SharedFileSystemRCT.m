#import <React/RCTBridgeModule.h>
#import <React/RCTUIManager.h>

@interface RCT_EXTERN_MODULE(SharedFileSystemRCT, NSObject)
RCT_EXTERN_METHOD(
   getAllFiles: (RCTPromiseResolveBlock)resolve
   rejecter:(RCTPromiseRejectBlock)reject
)
RCT_EXTERN_METHOD(clearAllFilesFromTempDirectory)
@end
