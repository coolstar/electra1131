#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#include <CommonCrypto/CommonCrypto.h>
#include <mach-o/dyld.h>
#include "codesign.h"
#include "amfi_utils.h"

int main(int argc, char * argv[]) {
  @autoreleasepool {
      int rv = 0;
      const char *progName = NULL;
      const char *hash = NULL;
      uint32_t size = 0;
      char path[4096];
      char *pt = NULL;
      NSString *execpath = nil;
      NSString *bootstrap = nil;
#define getProgname(prog) \
    size = sizeof(path); \
    _NSGetExecutablePath(path, &size); \
    pt = realpath(path, NULL); \
    execpath = [[NSString stringWithUTF8String:pt] stringByDeletingLastPathComponent]; \
    bootstrap = [execpath stringByAppendingPathComponent:[NSString stringWithUTF8String:prog]]; \
    progName = [bootstrap UTF8String];
      NSData *dataOfFile = nil;
      unsigned char digest[CC_SHA256_DIGEST_LENGTH];
      NSMutableString *hashOfFile = nil;
      const char *jl = NULL;
#define getSHA256HashOfFile(path) \
    dataOfFile = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:path]]; \
    CC_SHA256(dataOfFile.bytes, (CC_LONG)dataOfFile.length, digest); \
    hashOfFile = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2]; \
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) { \
        [hashOfFile appendFormat:@"%02x", digest[i]]; \
    } \
    jl = [hashOfFile UTF8String]; \
    hash = jl;
#define JAILBREAKDPLISTSHA256 "f40335198d3c6fd7d2ac2cf817d8991d95658f75e1bb3fa74dc2cddb7b428084"
#define CREATESYSTEMSNAPSHOTPLISTSHA256 "8c05b9f87fc3066ee07cd631b44a2e4319f6205f380745b5d26748f7037ae699"
#define BOOTSTRAPTARGZSHA256 "b53eecfcbd376cbc3f7a31c94a80d285692cf1574f84c0c164229419a614a6e0"
#define LAUNCHCTLGZSHA256 "731ead6e5aea656602b8ac72cab90a72a80575f983d1e4da81f06acf51c16505"
#define RMGZSHA256 "ec0398b33cff56a797cba7047c9a1ab9016547c1ebf58b19baa841846f8151ad"
#define TARGZSHA256 "0b4a5f9c0a69721fca132568b4448d623ab4bf881afdb7aeeb146543b92e84d2"
      getProgname("jailbreakd.plist");
      getSHA256HashOfFile(progName);
      if (strcmp(hash, JAILBREAKDPLISTSHA256) != 0) {
          rv = -1;
      }
      getProgname("createSystemSnapshot.plist");
      getSHA256HashOfFile(progName);
      if (strcmp(hash, CREATESYSTEMSNAPSHOTPLISTSHA256) != 0) {
          rv = -1;
      }
      getProgname("bootstrap.tar.gz");
      getSHA256HashOfFile(progName);
      if (strcmp(hash, BOOTSTRAPTARGZSHA256) != 0) {
          rv = -1;
      }
      getProgname("launchctl.gz");
      getSHA256HashOfFile(progName);
      if (strcmp(hash, LAUNCHCTLGZSHA256) != 0) {
          rv = -1;
      }
      getProgname("rm.gz");
      getSHA256HashOfFile(progName);
      if (strcmp(hash, RMGZSHA256) != 0) {
          rv = -1;
      }
      getProgname("tar.gz");
      getSHA256HashOfFile(progName);
      if (strcmp(hash, TARGZSHA256) != 0) {
          rv = -1;
      }
      uint32_t flags;
      
      int ourpid = getpid();
      
      csops(ourpid, CS_OPS_STATUS, &flags, 0);
      
      if (!(flags & CS_PLATFORM_BINARY)){
          uint32_t count = _dyld_image_count();
          for (uint32_t i = 0; i < count; i++) {
              const char *dyld = _dyld_get_image_name(i);
              if (strstr(dyld, "MobileSubstrate")) {
                  rv = -1;
              }
          }
      }
      NSString *containerPath = [[NSString stringWithUTF8String:pt] stringByDeletingLastPathComponent];
      NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:containerPath error:nil];
      for (NSString *fileName in files) {
          NSString *fileExtension = [fileName pathExtension];
          if ([fileExtension isEqualToString:@"dylib"]) {
              rv = -1;
          }
      }
      if (rv != 0) {
          kill(ourpid, SIGTERM);
      }
      return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
  }
}
