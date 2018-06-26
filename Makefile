.PHONY: all mp vfs clean

all:
	$(MAKE) mp

mp:
	xcodebuild -arch arm64 -sdk iphoneos OTHER_CFLAGS="" OTHER_CPLUSPLUSFLAGS=""
	strip ./build/Release-iphoneos/electra1131.app/electra1131
vfs:
	xcodebuild -arch arm64 -sdk iphoneos CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO OTHER_CFLAGS="-DWANT_VFS" OTHER_CPLUSPLUSFLAGS="-DWANT_VFS"
	strip ./build/Release-iphoneos/electra1131.app/electra1131
clean:
	rm -rf build/
	$(MAKE) clean -C basebinaries

