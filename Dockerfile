# ===== START FIRST STAGE ======
FROM phusion/baseimage:0.11 as builder
LABEL maintainer "support@polkasource.com"
LABEL description="Large image for building the Substrate binary."

ARG PROFILE=release
ARG REPOSITORY=paritytech-polkadot
WORKDIR /rustbuilder
COPY . /rustbuilder

# PREPARE OPERATING SYSTEM & BUILDING ENVIRONMENT
RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y cmake pkg-config libssl-dev git clang libclang-dev 
	
# CHECKOUT GIT SUBMODULES
RUN git submodule update --init --recursive
	
# UPDATE RUST DEPENDENCIES
ENV RUSTUP_HOME "/rustbuilder/.rustup"
ENV CARGO_HOME "/rustbuilder/.cargo"
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH "$PATH:/rustbuilder/.cargo/bin"
#RUN rustup update nightly
#RUN rustup override set nightly-2019-07-09
RUN RUSTUP_TOOLCHAIN=stable cargo install --git https://github.com/alexcrichton/wasm-gc

# BUILD RUNTIME AND BINARY
RUN rustup target add wasm32-unknown-unknown --toolchain nightly
#RUN rustup target add wasm32-unknown-unknown --toolchain nightly-2019-07-09
#RUN cd /rustbuilder/$REPOSITORY/scripts && ./build.sh
RUN cd /rustbuilder/$REPOSITORY && RUSTUP_TOOLCHAIN=stable cargo build --$PROFILE
# ===== END FIRST STAGE ======

# ===== START SECOND STAGE ======
FROM phusion/baseimage:0.11
LABEL maintainer "support@polkasource.com"
LABEL description="Small image with the Substrate binary."
ARG PROFILE=release
ARG REPOSITORY=paritytech-polkadot
COPY --from=builder /rustbuilder/$REPOSITORY/target/$PROFILE/polkadot /usr/local/bin

# REMOVE & CLEANUP
RUN mv /usr/share/ca* /tmp && \
	rm -rf /usr/share/*  && \
	mv /tmp/ca-certificates /usr/share/ && \
	rm -rf /usr/lib/python* && \
	mkdir -p /root/.local/share/polkadot && \
	ln -s /root/.local/share/polkadot /data
RUN	rm -rf /usr/bin /usr/sbin

# FINAL PREPARATIONS
EXPOSE 30333 9933 9944
VOLUME ["/data"]
#CMD ["/usr/local/bin/polkadot"]
WORKDIR /usr/local/bin
ENTRYPOINT ["polkadot"]
CMD []
# ===== END SECOND STAGE ======
