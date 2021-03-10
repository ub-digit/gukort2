FROM       ruby:2.5.3

# The location of the forskarskap app in the image
ENV        APP_HOME=/usr/src/app/
WORKDIR    $APP_HOME

# Copy the Gemfile and Gemfile.lock and install gems
COPY       ./Gemfile* ./
RUN        bundle install

# Install locale and some other stuff
RUN        DEBIAN_FRONTEND=noninteractive \
           apt-get update \
        && apt-get install -y --no-install-recommends \
           vim mc tree less  \
           postgresql-client \
           locales \
        && rm -rf /var/lib/apt/lists/* \
        && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
        && locale-gen \
        && cp /usr/share/zoneinfo/Europe/Stockholm /etc/localtime

# Prepare the environment
ENV        LANG=en_US.UTF-8
ENV        LANGUAGE=en_US:en

# Copy the full context
COPY       . ./

# Add a script to be executed every time the container starts
COPY       entrypoint.sh /
RUN        chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Start the main process
CMD        ["bundle", "exec", "rails", "server",  "-b", "0.0.0.0"]
