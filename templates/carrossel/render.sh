#!/usr/bin/env bash
# Renderiza cada slide de um carrossel.html em PNG 1080x1350 com Edge/Chrome headless.
# Uso: templates/carrossel/render.sh divulgacao/<slug>/instagram/carrossel.html
# Saída: slide-01.png ... na mesma pasta do HTML.
set -euo pipefail

html="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
out="$(dirname "$html")"
n=$(grep -c 'class="slide' "$html")

browser=""
for b in "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
         "/c/Program Files/Microsoft/Edge/Application/msedge.exe" \
         "/c/Program Files/Google/Chrome/Application/chrome.exe" \
         "$(command -v google-chrome 2>/dev/null || true)" \
         "$(command -v chromium 2>/dev/null || true)"; do
	[ -n "$b" ] && [ -x "$b" ] && browser="$b" && break
done
[ -z "$browser" ] && { echo "Edge/Chrome não encontrado"; exit 1; }

url_base="file:///$(cygpath -m "$html" 2>/dev/null || echo "$html")"
for i in $(seq 1 "$n"); do
	png="$out/$(printf 'slide-%02d.png' "$i")"
	"$browser" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
		--window-size=1080,1350 --virtual-time-budget=10000 \
		--screenshot="$(cygpath -w "$png" 2>/dev/null || echo "$png")" "$url_base?s=$i" >/dev/null 2>&1
	echo "ok $png"
done
