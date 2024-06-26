#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y unzip

# Add local zenbuilder user, either use LOCAL_USER_ID:LOCAL_GRP_ID
# if set via environment or fallback to 9001:9001
USER_ID="${LOCAL_USER_ID:-9001}"
GRP_ID="${LOCAL_GRP_ID:-9001}"
if [ "$USER_ID" != "0" ]; then
    export USERNAME=zenbuilder
    getent group "$GRP_ID" &> /dev/null || groupadd -g "$GRP_ID" "$USERNAME"
    id -u "$USERNAME" &> /dev/null || useradd --shell /bin/bash -u "$USER_ID" -g "$GRP_ID" -o -c "" -m "$USERNAME"
    CURRENT_UID="$(id -u "$USERNAME")"
    CURRENT_GID="$(id -g "$USERNAME")"
    export HOME=/home/"$USERNAME"
    if [ "$USER_ID" != "$CURRENT_UID" ] || [ "$GRP_ID" != "$CURRENT_GID" ]; then
        echo "WARNING: User with differing UID ${CURRENT_UID}/GID ${CURRENT_GID} already exists, most likely this container was started before with a different UID/GID. Re-create it to change UID/GID."
    fi
else
    export USERNAME=root
    export HOME=/root
    CURRENT_UID="$USER_ID"
    CURRENT_GID="$GRP_ID"
    echo "WARNING: Starting container processes as root. This has some security implications and goes against docker best practice."
fi
export CARGO_HOME=/opt/rust/cargo

if eval "${NEED_NPM}"; then 
  curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts

  chown -Rf "$CURRENT_UID":"$CURRENT_GID" ${HOME}/.npm
fi

rustup show
cargo -vV
cargo install --list
CARGO_AUDIT_VERSION=$(cargo audit --version | sed -r "~s~cargo-audit ~~")
if [[ "${CARGO_AUDIT_VERSION}" == "0.16.0" ]] ; then 
  # Install cargo audit that is missed or outdated
  echo "Replace outdated cargo audit version '${CARGO_AUDIT_VERSION}'"
  cargo install cargo-audit --force; 
fi
if [ "$NEED_CARGO_README" = "false" ]; then
  echo -e "\nWithout cargo readme support"
elif [ "$NEED_CARGO_README" != "true" ]; then
  echo -e "\nERROR: NEED_CARGO_README should be only true|false and not '$NEED_CARGO_README'"
  exit 1
fi

if eval "$NEED_CARGO_README" && ! cargo install --list | grep -w -q cargo-readme ; then 
  # Install missed cargo-readme
  echo "Install cargo-readme"
  cargo install cargo-readme;
fi

if [ "$NEED_WASMPACK" = "false" ]; then
  echo -e "\nWithout wasm-pack support"
elif [ "$NEED_WASMPACK" != "true" ]; then
  echo -e "\nERROR: NEED_WASMPACK should be only true|false and not '$NEED_WASMPACK'"
  exit 1
fi

eval "$NEED_WASMPACK" && curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | bash && rustup target add wasm32-unknown-unknown

echo
lscpu
echo
free -h
echo
echo "Username: $USERNAME, HOME: $HOME, UID: $CURRENT_UID, GID: $CURRENT_GID"
echo "CARGOARGS: ${CARGOARGS:-unset}, RUSTFLAGS: ${RUSTFLAGS:-unset}, RUST_CROSS_TARGETS: ${RUST_CROSS_TARGETS:-unset}, RUSTUP_TOOLCHAIN: ${RUSTUP_TOOLCHAIN:-unset}"

if [ "$PROTOBUF_VERSION" != "none" ]; then
  tmp_dir=$(mktemp -d)
  out_protoc_path=${tmp_dir}/protoc.zip

  curl -o "${out_protoc_path}" -sSLO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip \
      && unzip "${out_protoc_path}" -d /usr/local/
else
  echo "Protobuf not installed"
fi

# cargo audit need to modify '/opt/rust/cargo/advisory-db' as unprivileged
# user.
mkdir -p ${CARGO_HOME}/advisory-db
chown -Rf "$CURRENT_UID":"$CURRENT_GID" ${CARGO_HOME}/advisory-db

# We should access to the registry
chown -Rf "$CURRENT_UID":"$CURRENT_GID" ${CARGO_HOME}

# If this project need to use pinned rust version we need to unfortunately guarantee 
# that the unprivileged can install a different version of Rust.
# The needed Rust version could be overriden by the code in the git repo,
# see https://rust-lang.github.io/rustup/overrides.html#the-toolchain-file.
# Without doing this any attempt to install a new version of Rust would fail
# with permission errors.
# In this case you can use the follow line
# chown -Rf "$CURRENT_UID":"$CURRENT_GID" /opt/rust

script=$1
shift

if [ "$USERNAME" = "root" ]; then
  exec "${script}" "$@"
else
  exec gosu "$USERNAME" "${script}" "$@"
fi

