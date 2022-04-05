ARG OPENJDK_TAG=11

#
# temporary image
#

FROM ubuntu:latest AS stage
WORKDIR /app

# use the modified version
COPY ./pexdex-cli.properties .

# PEXDEX application
COPY ./install/PEXDEX/CLI ./CLI
COPY ./install/PEXDEX/IPC ./IPC
COPY ./install/PEXDEX/*.dll ./
COPY ./install/PEXDEX/log4net.* ./
COPY ./install/PEXDEX/Newtonsoft.* ./
COPY ./install/PEXDEX/pedscreen_schema ./pedscreen_schema
COPY ./install/PEXDEX/registry_schema ./registry_schema

# create logs directory to prevent `Unable to write to validator log` error
RUN mkdir ./logs

# java runtime
# COPY ./install/PEXDEX/runtime ./java

# perl runtime
COPY ./install/PEXDEX/strawberry/perl ./perl

# deid
COPY ./install/PEXDEX/deid /app/deid

#
# final image
#

FROM openjdk:${OPENJDK_TAG}
WORKDIR /app

COPY --from=stage ./app .

#
# add java and perl runtimes to the PATH environment variable
#

ENV PATH "/app/perl/bin:$PATH"

#
# testing
#

# CMD ["java","--version"]

#
# pexdex
#

# will always be run; displays help text
ENTRYPOINT ["java", "-Dproperties.dir=/app", "-jar", "./CLI/pexdexCLI.jar", "--spring.profiles.active=error"]

# will be overriden if parameters are passed to docker run; displays help text
# CMD ["java", "-Dproperties.dir=/app", "-jar", ".\\CLI\\pexdexCLI.jar", "--spring.profiles.active=error"]
