GO_EASY_ON_ME=1

ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MarkFavourites
MarkFavourites_FILES = Tweak.xm
MarkFavourites_FRAMEWORKS = UIKit
MarkFavourites_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileSlideShow"
