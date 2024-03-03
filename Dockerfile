# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian
# instead of Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20221004-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.14.2-erlang-25.1.2-debian-bullseye-20221004-slim
#
ARG ELIXIR_VERSION=1.16.1
ARG OTP_VERSION=26.2
ARG DEBIAN_VERSION=buster-20231009-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# ------------------------------------------------------------------------------
# BUILDER IMAGE
# ------------------------------------------------------------------------------
FROM ${BUILDER_IMAGE} as builder

# Install build dependencies.
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Prepare build dir.
WORKDIR /app

# Install hex + rebar.
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV.
ENV MIX_ENV="prod"

# Install mix dependencies.
COPY mix.exs ./
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

COPY lib lib

COPY hotdog  ./

# Compile the release.
RUN mix compile

RUN mix release

# ------------------------------------------------------------------------------
# RUNNER IMAGE
# ------------------------------------------------------------------------------
# Start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities.
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales wget \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale.
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV.
ENV MIX_ENV="prod"

# Only copy the final release from the build stage.
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/hotdoggy ./

USER nobody

CMD ["/app/bin/hotdoggy", "start"]
