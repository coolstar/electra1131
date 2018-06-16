.PHONY: all clean

all:
	xcodebuild -arch arm64

clean:
	rm -rf build/
	$(MAKE) clean -C basebinaries
