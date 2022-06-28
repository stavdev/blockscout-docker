FROM elixir:latest

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
#MARK: Replace on locale blockscout
# RUN git clone https://github.com/blockscout/blockscout 
COPY . .

WORKDIR /blockscout

ENV SECRET_KEY_BASE="VTIB3uHDNbvrY0+60ZWgUoUBKDn9ppLR8MI4CpRz4/qLyEFs54ktJfaNT6Z221No" \
    MIX_ENV="prod" \
    ETHEREUM_JSONRPC_VARIANT="geth" \
    # ETHEREUM_JSONRPC_HTTP_URL="http://localhost:8545" \
    # ETHEREUM_JSONRPC_WS_URL="http://localhost:8546" \
    COIN="TMY" \
    DATABASE_URL="postgresql://blockscout:blockscout@postgres:5432/blockscout" \
    PORT=4000

RUN mix local.hex --force \
    && mix do deps.get, local.rebar --force, deps.compile, compile

# Install npm dependancies and compile frontend assets​
RUN cd apps/block_scout_web/assets && npm install && node_modules/webpack/bin/webpack.js --mode production

# Build static assets​
RUN mix phx.digest

# Generate self-signed certificates​
RUN cd apps/block_scout_web && mix phx.gen.cert blockscout blockscout.local

EXPOSE 4000

CMD [ "mix", "do", "ecto.create", "ecto.migrate", "phx.server"]