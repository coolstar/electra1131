.PHONY: all mp vfs clean

all:
	$(MAKE) mp

mp:
	xcodebuild -arch arm64
	strip ./build/Release-iphoneos/electra1131.app/electra1131
vfs:
	xcodebuild -arch arm64 CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -sdk iphoneos
	strip ./build/Release-iphoneos/electra1131.app/electra1131
clean:
	rm -rf build/
	$(MAKE) clean -C basebinaries

