#!/usr/bin/env bash
set -e

export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_ENABLE_HIGHDPI_SCALING=0
export QT_SCALE_FACTOR=1
export QT_SCREEN_SCALE_FACTORS=1
export QT_FONT_DPI=96
export XFT_DPI=96

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-default}"
mkdir -p "$XDG_RUNTIME_DIR" || true
chmod 700 "$XDG_RUNTIME_DIR" || true

export HOME="${HOME:-/home/default}"
if [[ ! -f "$HOME/.grsim.xml" ]]; then
  cp /usr/local/share/firasim/grsim.xml "$HOME/.grsim.xml"
  chmod 644 "$HOME/.grsim.xml" || true
fi

if [[ "${1:-}" == "vnc" ]]; then
  shift
  echo "Launch in VNC mode"

  : "${VNC_PASSWORD:=vncpassword}"
  : "${VNC_GEOMETRY:=1280x1024}"

  mkdir -p "$HOME/.vnc"
  x11vnc -storepasswd "${VNC_PASSWORD}" "$HOME/.vnc/passwd"

  export DISPLAY=:99

  Xvfb "$DISPLAY" -screen 0 "${VNC_GEOMETRY}x24" -dpi 96 -ac +extension GLX +render -noreset &
  XVFB_PID=$!

  for i in $(seq 1 80); do
    if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
      break
    fi
    sleep 0.1
  done

  if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    echo "ERROR: Xvfb did not start on $DISPLAY"
    ps aux | grep -E 'Xvfb|x11vnc|FIRASim' || true
    exit 1
  fi

  /usr/local/bin/FIRASim "$@" &

  exec x11vnc -forever -shared -usepw -display "$DISPLAY" -rfbport 5900 -noxdamage

elif [[ -n "${DISPLAY:-}" ]]; then
  echo "Launch with host X11 display: $DISPLAY"
  exec /usr/local/bin/FIRASim "$@"

else
  echo "Launch in offscreen mode (no DISPLAY)"
  exec /usr/local/bin/FIRASim -platform offscreen "$@"
fi
