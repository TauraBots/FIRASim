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

if [[ "$1" == "vnc" ]]; then
  shift
  echo "Launch in VNC mode"

  : "${VNC_PASSWORD:=vncpassword}"
  : "${VNC_GEOMETRY:=1280x1024}"

  mkdir -p ~/.vnc
  x11vnc -storepasswd "${VNC_PASSWORD}" ~/.vnc/passwd

  export DISPLAY=:99
  Xvfb :99 -screen 0 "${VNC_GEOMETRY}x24" -dpi 96 -ac +extension GLX +render -noreset &

  /usr/local/bin/FIRASim "$@" &

  exec x11vnc -forever -shared -usepw -display :99 -rfbport 5900 -noxdamage

elif [[ -n "$DISPLAY" ]]; then
  echo "Launch with host X11 display: $DISPLAY"
  exec /usr/local/bin/FIRASim "$@"

else
  echo "Launch in offscreen mode (no DISPLAY)"
  exec /usr/local/bin/FIRASim -platform offscreen "$@"
fi
