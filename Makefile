.PHONY: clean

WOWINTERFACE_ID=25774
ADDON:=MailRobot
FILES:=$(ADDON).lua $(ADDON).toc README.txt LICENSE.txt CHANGELOG.txt
VERSION=$(shell grep "Version:" $(ADDON).toc | cut -f3- -d' ')
COMPATIBLE:=1.13.5

.build/$(ADDON).zip: .build
	cd .build; zip -r $(ADDON).zip *; cd ..

.build: $(FILES)
	rm -rf .build
	mkdir -p .build/$(ADDON)
	for f in $(FILES); do \
		ln -s ../../$$f .build/$(ADDON)/$$f; \
	done

clean:
	@ rm -rf .build

deploy:
	curl -H "x-api-token: $(TOKEN)" \
	-F "id=$(WOWINTERFACE_ID)" \
	-F "version=$(VERSION)" \
	-F "compatible=$(COMPATIBLE)" \
	-F "updatefile=@.build/$(ADDON).zip" \
	https://api.wowinterface.com/addons/update
