#!/bin/sh
# Called by socat for each HTTP request to /api/log-qr.
# stdin/stdout are connected to the TCP socket by socat.

# Consume HTTP request headers (stop at blank line)
while IFS= read -r line; do
  stripped="${line%$'\r'}"
  [ -z "$stripped" ] && break
done

printf 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\nQR code printed to container logs.\n'

# Print QR to stderr → container logs
printf '\n=== SUPABASE KEY QR CODE ===\n' >&2
python3 -c "
import qrcode, os, sys
qr = qrcode.QRCode(
    error_correction=qrcode.constants.ERROR_CORRECT_L,
    box_size=1,
    border=1,
)
qr.add_data(os.environ.get('QR_KEY', ''))
qr.make(fit=True)
qr.print_ascii(invert=True, out=sys.stderr)
" >&2
printf '============================\n\n' >&2
