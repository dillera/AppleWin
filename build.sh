#!/usr/bin/env bash
#
# A build script for AppleWin Linux or Windows (via mingw-w64 cross-compile using Docker)
#

function show_help {
  echo "Usage: $(basename $0) [options] -- [additional args]"
  echo ""
  echo "building options:"
  echo "   -b       # run build"
  echo "   -w       # target Windows (cross-compile with mingw-w64 Docker)"
  echo ""
  echo "flags for building options"
  echo "   -c       # run clean before build"
  echo "   -g       # compile with debug enabled"
  echo "   -G GEN   # Use GEN as the Generator for cmake (e.g. -G \"Unix Makefiles\" or -G Ninja)"
  echo ""
  echo "other options:"
  echo "   -h       # this help"
  echo ""
  echo "Additional Args can be accepted to pass values onto sub processes where supported."
  echo "  e.g. ./build.sh -cb -- -DFOO=BAR"
  echo ""
  exit 1
}

if [ $# -eq 0 ]; then
  show_help
fi

DO_BUILD=0
DO_CLEAN=0
TARGET_WINDOWS=0
RELEASE_TYPE="Release"
CMAKE_GENERATOR=""

while getopts "bcgwG:h" flag; do
  case "$flag" in
  b) DO_BUILD=1 ;;
  c) DO_CLEAN=1 ;;
  g) RELEASE_TYPE="Debug" ;;
  w) TARGET_WINDOWS=1 ;;
  G) CMAKE_GENERATOR=${OPTARG} ;;
  h) show_help ;;
  *) show_help ;;
  esac
done
shift $((OPTIND - 1))

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
BUILD_DIR="$SCRIPT_DIR/build"

# Create build directory if missing
if [ ! -d "$BUILD_DIR" ]; then
  mkdir "$BUILD_DIR"
fi

# If target Windows, we run inside the dockcross docker container
if [ $TARGET_WINDOWS -eq 1 ]; then
  DOCKER_IMAGE="ghcr.io/fujinetwifi/applewin-dockcross-windows-static-x64:latest"

  # Pull Docker image if missing locally
  if ! docker image inspect "$DOCKER_IMAGE" > /dev/null 2>&1; then
    echo "Docker image $DOCKER_IMAGE not found locally. Pulling from GHCR..."
    docker pull "$DOCKER_IMAGE"
    if [ $? -ne 0 ]; then
      echo "Failed to pull Docker image $DOCKER_IMAGE. Aborting."
      exit 1
    fi
  fi

  # Get user id/group to avoid permission issues on mounted volumes
  USER_ID=$(id -u)
  GROUP_ID=$(id -g)

  if [ $DO_CLEAN -eq 1 ]; then
    echo "Cleaning build directory inside Docker container"
    docker run --rm -u "$USER_ID:$GROUP_ID" -v "$SCRIPT_DIR":/work -w /work \
      $DOCKER_IMAGE rm -rf build/*
  fi

  if [ $DO_BUILD -eq 1 ]; then
    echo "Building AppleWin project for Windows inside Docker container"

    GEN_CMD=()
    if [ -n "$CMAKE_GENERATOR" ]; then
      GEN_CMD+=("-G" "$CMAKE_GENERATOR")
    fi

    # Run cmake configure step inside container
    docker run --rm -u "$USER_ID:$GROUP_ID" -v "$SCRIPT_DIR":/work -w /work/build \
      $DOCKER_IMAGE \
      x86_64-w64-mingw32.static-cmake "${GEN_CMD[@]}" .. \
      -DBUILD_SA2=on \
      -DCMAKE_BUILD_TYPE=$RELEASE_TYPE \
      "$@"

    if [ $? -ne 0 ]; then
      echo "Error running cmake inside Docker container. Aborting"
      exit 1
    fi

    # Run build inside container
    docker run --rm -u "$USER_ID:$GROUP_ID" -v "$SCRIPT_DIR":/work -w /work/build \
      $DOCKER_IMAGE \
      cmake --build .

    if [ $? -ne 0 ]; then
      echo "ERROR: Could not build inside Docker container."
      exit 1
    fi
  fi

else
  # Native Linux build

  if [ $DO_CLEAN -eq 1 ]; then
    echo "Removing old build artifacts"
    rm -rf "$BUILD_DIR"/*
    rm "$BUILD_DIR"/.ninja* 2>/dev/null || true
  fi

  if [ $DO_BUILD -eq 1 ]; then
    echo "Building AppleWin project for native Linux target"
    cd "$BUILD_DIR"

    GEN_CMD=""
    if [ -n "$CMAKE_GENERATOR" ]; then
      GEN_CMD="-G $CMAKE_GENERATOR"
    fi

    cmake $GEN_CMD .. \
      -DBUILD_SA2=on \
      -DCMAKE_BUILD_TYPE=$RELEASE_TYPE \
      "$@"

    if [ $? -ne 0 ]; then
      echo "Error running cmake. Aborting"
      exit 1
    fi

    cmake --build .

    if [ $? -ne 0 ]; then
      echo "ERROR: Could not run cmake."
      exit 1
    fi
  fi
fi
