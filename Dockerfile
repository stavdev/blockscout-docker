FROM elixir:latest

RUN echo $DATABASE_URL

# Update repositories
RUN apt-get update

#Requirements
RUN apt-get install wget curl automake libtool inotify-tools gcc libgmp-dev make g++ build-essential -y

# Node & npm
RUN apt-get install nodejs npm -y

# Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Postgres
RUN apt-get install postgresql postgresql-contrib -y

# Build blockscout
RUN git clone https://github.com/stavdev/blockscout.git

WORKDIR /blockscout

RUN echo "blockscout compile"

RUN mix local.hex --force \
    && mix do deps.get, local.rebar --force, deps.compile, compile

RUN echo "Install npm dependancies and compile frontend assets​"

# Install npm dependancies and compile frontend assets​
RUN cd apps/block_scout_web/assets && npm install && node_modules/webpack/bin/webpack.js --mode production

RUN echo "Build static assets​​"
# Build static assets​
RUN mix phx.digest

RUN echo "Generate self-signed certificates​​​"
# Generate self-signed certificates​
RUN cd apps/block_scout_web && mix phx.gen.cert blockscout blockscout.local

EXPOSE 4000



CMD [ "mix", "do", "ecto.create", "ecto.migrate", "phx.server"]