#!/bin/bash

set -e

# --- BỔ SUNG: Dọn dẹp import thừa trước khi build ---
echo "==> Cleaning up unused imports and formatting code..."
go mod tidy
# Nếu bạn đã cài goimports, hãy bỏ comment dòng dưới
# goimports -w . 
# ---------------------------------------------------

targets=(
  "linux amd64"
  "linux 386"
  "linux arm64"
  "linux arm 5"
  "linux arm 6"
  "linux arm 7"
  "linux s390x"
  "windows amd64"
)

ENTRYPOINT="."
mkdir -p dist

for target in "${targets[@]}"; do
  read -r GOOS GOARCH GOARM <<< "$target"

  FILENAME="x-ui-${GOOS}-${GOARCH}"
  [ -n "$GOARM" ] && FILENAME="${FILENAME}v${GOARM}"

  echo "==> Building for $GOOS/$GOARCH $([ -n "$GOARM" ] && echo "v$GOARM")"

  export GOOS=$GOOS
  export GOARCH=$GOARCH
  export GOARM=$GOARM

  BUILD_DIR="build/${FILENAME}"
  mkdir -p "$BUILD_DIR"

  OUT_BIN="$BUILD_DIR/x-ui"
  [ "$GOOS" = "windows" ] && OUT_BIN="$BUILD_DIR/x-ui.exe"

  # Chạy build và bắt lỗi nếu có
  if ! go build -ldflags="-s -w" -o "$OUT_BIN" "$ENTRYPOINT"; then
      echo "ERROR: Build failed for $GOOS/$GOARCH"
      exit 1
  fi

  # Copy file (Sử dụng thêm các cờ để tránh lỗi file không tồn tại)
  mkdir -p "$BUILD_DIR/bin"
  cp -r bin/xray-${GOOS}-${GOARCH}* "$BUILD_DIR/bin/" 2>/dev/null || true
  
  if [ "$GOOS" = "windows" ]; then
    zip -r "dist/${FILENAME}.zip" -j "$BUILD_DIR"/* > /dev/null
  else
    tar -czf "dist/${FILENAME}.tar.gz" -C "$BUILD_DIR" .
  fi

  rm -rf "$BUILD_DIR"
done

echo "==> All builds completed in ./dist"