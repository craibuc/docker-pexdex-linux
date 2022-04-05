PEXDEX_NAME=pexdex-linux
PEXDEX_VERSION=2.0.3
OPENJDK_TAG=11

EMAIL=craig.buchanan@choa.org
SITE_ID=CHAH
PIN=123456
PUBLIC_KEY=AAAAA
PROFILE_PATH=/mnt/c/Users/$(USER)
APP_DATA=$(PROFILE_PATH)/AppData/Roaming
XML_PATH=/output/choa/CHAH_2020-03-01_to_2020-03-31.xml
PID_PATH=/output/choa/PID_CHAH_2020-03-01_to_2020-03-31.txt

env:
	@echo "SITE_ID: $(SITE_ID)"
	@echo "PROFILE_PATH: $(PROFILE_PATH)"
	@echo "APP_DATA: $(APP_DATA)"
	@echo "XML_PATH: $(XML_PATH)"
	@echo "PID_PATH: $(PID_PATH)"

clean:
	@echo "Removing installation directory..."

	@if [ -d "./install" ]; then \
		chmod -R 777 ./install && \
		rm -rf ./install; \
	fi

prepare: clean
	@echo "Copying pexdexCLI and dependencies..."

	# create installation directory
	mkdir -p ./install

	# copy PexDex and its artifacts
	cp -rf "/mnt/c/Program Files/PEXDEX/" ./install/PEXDEX

	# copy the deid script
	cp -rf "/mnt/c/Users/$USER/AppData/Roaming/pexdex/perl" ./install/PEXDEX/deid

build:
	@echo "Building image '${PEXDEX_NAME}:${OPENJDK_TAG}_${PEXDEX_VERSION}'..."

	docker build \
		--build-arg OPENJDK_TAG=$(OPENJDK_TAG) \
		--tag ${PEXDEX_NAME}:${OPENJDK_TAG}_${PEXDEX_VERSION} \
		--tag ${PEXDEX_NAME}:latest \
		.

tty:
	docker run -it --rm --env-file=.env -v "$(PROFILE_PATH)/output:/app/output" -v "$(APP_DATA)/pexdex:/app/user" --entrypoint /bin/bash ${PEXDEX_NAME}:latest

run:
	docker run --rm --env-file=.env -v "$(PROFILE_PATH)/output:/app/output" -v "$(APP_DATA)/pexdex:/app/user" ${PEXDEX_NAME}:latest

# register:
# 	docker run --rm ${PEXDEX_NAME}:latest --register --siteid $(SITE_ID) --study pedscreen --email $(EMAIL)

# confirm:
# 	docker run --rm ${PEXDEX_NAME}:latest --confirmregister --siteid $(SITE_ID) --study pedscreen --pin $(PIN) --publickey $(PUBLIC_KEY)

validate:
	docker run --rm -v "$(PROFILE_PATH)/output:/app/output" ${PEXDEX_NAME}:latest --validate --submissiontype 1 --study pedscreen --siteid $(SITE_ID) --file "$(APP_DATA)$(XML_PATH)" --pidtxt "$(APP_DATA)$(PID_PATH)"

# deidentify:
# 	docker run --rm --env-file=.env ${PEXDEX_NAME}:latest --deidentify --submissiontype 1 --study pedscreen --siteid $SITE_ID --file $XML_PATH --pidtxt $PID_PATH

# submit:
# 	docker run --rm --env-file=.env ${PEXDEX_NAME}:latest --submit --submissiontype 1 --study pedscreen --siteid $SITE_ID --file $XML_PATH --pidtxt $PID_PATH
