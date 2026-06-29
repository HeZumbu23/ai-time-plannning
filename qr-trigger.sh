#!/bin/sh
# Called by socat for each HTTP request to /api/log-qr.
# stdin/stdout are connected to the TCP socket by socat.
# Reads past the HTTP request headers, then sends a 200 response
# and prints an ASCII QR code of $QR_KEY to stderr (→ container logs).

# Consume request headers (stop at blank line)
while IFS= read -r line; do
  stripped="${line%$'\r'}"
  [ -z "$stripped" ] && break
done

printf 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\nQR code printed to container logs.\n'

printf '\n=== SUPABASE KEY QR CODE ===\n' >&2
qrencode -t ANSIUTF8 -s 3 -- "$QR_KEY" >&2
printf '============================\n\n' >&2
