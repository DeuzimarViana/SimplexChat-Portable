#!/bin/bash
# SimpleX Chat portátil - inicia o app mantendo todos os dados nesta pasta
DIR="$(cd "$(dirname "$0")" && pwd)"
export XDG_DATA_HOME="$DIR/dados"
export XDG_CONFIG_HOME="$DIR/config"
export XDG_CACHE_HOME="$DIR/cache"
exec "$DIR/simplex-desktop.AppImage" "$@"