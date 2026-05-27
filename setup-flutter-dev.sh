#!/bin/bash
# Flutter dev environment setup for SteamOS + distrobox
# Run from the HOST (outside any container)
#
# Usage:
#   ./setup-flutter-dev.sh           Normal setup
#   ./setup-flutter-dev.sh --test    Create a temp container, verify, then clean up

set -e

IMAGE="docker.io/library/ubuntu:22.04"
TEST_MODE=false

# ---- Parse flags ----
for arg in "$@"; do
  case $arg in
    --test) TEST_MODE=true ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

if $TEST_MODE; then
  CONTAINER_NAME="flutter-dev-test"
  echo "==> TEST MODE: using temporary container '$CONTAINER_NAME'"
else
  CONTAINER_NAME="flutter-dev"
fi

# ---- Cleanup function (used in test mode) ----
cleanup() {
  echo ""
  echo "==> Cleaning up test container '$CONTAINER_NAME'..."
  distrobox stop "$CONTAINER_NAME" 2>/dev/null || true
  distrobox rm "$CONTAINER_NAME" 2>/dev/null || true
  echo "==> Cleanup done."
}

# In test mode, always clean up on exit (success or failure)
if $TEST_MODE; then
  trap cleanup EXIT
fi

# ---- STEP 1: Pull image & create container ----

echo "==> Pulling image $IMAGE..."
podman pull "$IMAGE"

echo "==> Creating distrobox container '$CONTAINER_NAME'..."
if distrobox list | grep -q "$CONTAINER_NAME"; then
  echo "    Container already exists, skipping creation."
else
  distrobox create --image "$IMAGE" --name "$CONTAINER_NAME"
fi

# ---- STEP 2: Install everything inside the container ----

echo "==> Running setup inside container..."
distrobox enter "$CONTAINER_NAME" -- bash -c '
set -e

echo "==> Updating packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

echo "==> Installing dependencies..."
sudo apt-get install -y \
  curl git unzip xz-utils zip \
  libglu1-mesa \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev \
  libnotify-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libcanberra-gtk-module libcanberra-gtk3-module \
  mesa-utils

echo "==> Cloning Flutter SDK (stable)..."
if [ -d "$HOME/flutter" ]; then
  echo "    ~/flutter already exists, skipping clone."
else
  git clone https://github.com/flutter/flutter.git -b stable ~/flutter
fi

echo "==> Adding Flutter to PATH..."
if ! grep -q "flutter/bin" ~/.bashrc; then
  echo "export PATH=\"\$HOME/flutter/bin:\$PATH\"" >> ~/.bashrc
fi
export PATH="$HOME/flutter/bin:$PATH"

echo "==> Running flutter doctor..."
~/flutter/bin/flutter doctor
'

# ---- STEP 3: Verify (test mode only) ----

if $TEST_MODE; then
  echo ""
  echo "==> Verifying installation..."

  PASS=0
  FAIL=0

  run_check() {
    local description="$1"
    local command="$2"
    if distrobox enter "$CONTAINER_NAME" -- bash -c "$command" &>/dev/null; then
      echo "    [PASS] $description"
      PASS=$((PASS + 1))
    else
      echo "    [FAIL] $description"
      FAIL=$((FAIL + 1))
    fi
  }

  run_check "Flutter binary exists"         "test -f \$HOME/flutter/bin/flutter"
  run_check "Flutter runs"                  "\$HOME/flutter/bin/flutter --version"
  run_check "Flutter PATH in .bashrc"       "grep -q 'flutter/bin' ~/.bashrc"
  run_check "libnotify-dev installed"       "dpkg -s libnotify-dev"
  run_check "libgstreamer installed"        "dpkg -s libgstreamer1.0-dev"
  run_check "Linux toolchain available"     "\$HOME/flutter/bin/flutter doctor | grep -q '✓.*Linux toolchain'"

  echo ""
  echo "==> Results: $PASS passed, $FAIL failed."
  if [ $FAIL -gt 0 ]; then
    echo "    Some checks failed — review output above."
    exit 1
  else
    echo "    All checks passed."
  fi
fi

# ---- Done ----

if ! $TEST_MODE; then
  echo ""
  echo "==> All done. Enter the container with:"
  echo "    distrobox enter $CONTAINER_NAME"
  echo ""
  echo "    Then run your project:"
  echo "    cd ~/Documents/Projects/pomodoro && flutter pub get && flutter run"
fi
