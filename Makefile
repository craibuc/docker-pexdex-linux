PEXDEX_NAME=pexdex-linux
PEXDEX_VERSION=2.0.3
OPENJDK_TAG=11

SITE_ID=CHAH
STUDY=pedscreen
EMAIL=craig.buchanan@choa.org
PIN=123456
PUBLIC_KEY=AAAAA
PROFILE_PATH=/mnt/c/Users/$(USER)
APP_DATA=$(PROFILE_PATH)/AppData/Roaming
XML_PATH=/output/choa/CHAH_2020-03-01_to_2020-03-31.xml
PID_PATH=/output/choa/PID_CHAH_2020-03-01_to_2020-03-31.txt

# prints the makefile's variables
env:
	@echo "SITE_ID: $(SITE_ID)"
	@echo "STUDY: $(STUDY)"
	@echo "PROFILE_PATH: $(PROFILE_PATH)"
	@echo "APP_DATA: $(APP_DATA)"
	@echo "XML_PATH: $(XML_PATH)"
	@echo "PID_PATH: $(PID_PATH)"

# removes the install/ directory, which contains PEXDEX and its dependencies (copied from its original location)
clean:
	@echo "Removing installation directory..."

	@if [ -d "./install" ]; then \
		chmod -R 777 ./install && \
		rm -rf ./install; \
	fi

# copies PEXDEX and its dependencies to the project's directory to make it accessible to Docker
prepare: clean
	@echo "Copying pexdexCLI and dependencies..."

	# create installation directory
	mkdir -p ./install/PEXDEX && chmod -R 777 ./install

	# copy PexDex and its artifacts
	# cp -rf '/mnt/c/Program Files/PEXDEX' ./install/PEXDEX
	cp -rf '/mnt/c/Program Files/PEXDEX/CLI' ./install/PEXDEX/CLI
	cp -rf '/mnt/c/Program Files/PEXDEX/IPC' ./install/PEXDEX/IPC
	cp -rf '/mnt/c/Program Files/PEXDEX/pedscreen_schema' ./install/PEXDEX/pedscreen_schema
	cp -rf '/mnt/c/Program Files/PEXDEX/registry_schema' ./install/PEXDEX/registry_schema

	cp '/mnt/c/Program Files/PEXDEX/'*.dll ./install/PEXDEX
	cp -f '/mnt/c/Program Files/PEXDEX/'log4net.* ./install/PEXDEX
	cp -f '/mnt/c/Program Files/PEXDEX/'Newtonsoft.* ./install/PEXDEX

	# copy the deid script from the user's AppData directory
	mkdir -p ./install/PEXDEX/deid && cp -rf "$(APP_DATA)/pexdex/perl" ./install/PEXDEX/deid

# build the image
build:
	@echo "Building image '${PEXDEX_NAME}:${OPENJDK_TAG}_${PEXDEX_VERSION}'..."

	docker build \
		--build-arg OPENJDK_TAG=$(OPENJDK_TAG) \
		--tag ${PEXDEX_NAME}:${OPENJDK_TAG}_${PEXDEX_VERSION} \
		--tag ${PEXDEX_NAME}:latest \
		.

# create a terminal session in the container
tty:
	docker run -it --rm --env-file=.env -v "$(PROFILE_PATH)/output:/app/output" -v "$(APP_DATA)/pexdex:/app/user" --entrypoint /bin/bash ${PEXDEX_NAME}:latest

# run the contain, which will generate the help text if everything is working
run:
	docker run --rm --env-file=.env -v "$(PROFILE_PATH)/output:/app/output" -v "$(APP_DATA)/pexdex:/app/user" ${PEXDEX_NAME}:latest

# register the site/email combination
register:
	docker run --rm ${PEXDEX_NAME}:latest --register --siteid $(SITE_ID) --study $(STUDY) --email $(EMAIL)

# confirm the registration
confirm:
	docker run --rm ${PEXDEX_NAME}:latest --confirmregister --siteid $(SITE_ID) --study $(STUDY) --pin $(PIN) --publickey $(PUBLIC_KEY)

# validate the XML file
validate:
	docker run --rm -v "$(PROFILE_PATH)/output:/app/output" ${PEXDEX_NAME}:latest --validate --siteid $(SITE_ID) --study $(STUDY) --submissiontype 1 --file "$(APP_DATA)$(XML_PATH)" --pidtxt "$(APP_DATA)$(PID_PATH)"

# de-identify the XML file
deidentify:
	docker run --rm --env-file=.env -v "$(PROFILE_PATH)/output:/app/output" -v "$(APP_DATA)/pexdex:/app/user" ${PEXDEX_NAME}:latest --deidentify --siteid $SITE_ID --study $(STUDY) --submissiontype 1 --file $XML_PATH --pidtxt $PID_PATH

# submit the XML file
submit:
	docker run --rm --env-file=.env -v "$(PROFILE_PATH)/output:/app/output" ${PEXDEX_NAME}:latest --submit --siteid $SITE_ID --study $(STUDY) --submissiontype 1 --file $XML_PATH --pidtxt $PID_PATH
