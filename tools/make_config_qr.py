#!/usr/bin/env python3
"""Erzeugt einen QR-Code, der die Supabase-Verbindungsdaten als JSON enthält.

Die TODO-App (Setup-Screen oder Zahnrad -> "QR-Code scannen") liest diesen
QR-Code und speichert URL + Anon-Key lokal auf dem Gerät. So muss der lange
Key nicht am Handy abgetippt werden.

Voraussetzung:
    pip install "qrcode[pil]"

Beispiele:
    # Werte direkt übergeben
    python tools/make_config_qr.py \
        --url https://xxxx.supabase.co \
        --key eyJhbGciOi... \
        --out config_qr.png

    # Werte aus Umgebungsvariablen (SUPABASE_URL / SUPABASE_ANON_KEY)
    export SUPABASE_URL=https://xxxx.supabase.co
    export SUPABASE_ANON_KEY=eyJhbGciOi...
    python tools/make_config_qr.py

    # Nur ASCII im Terminal anzeigen (ohne PNG)
    python tools/make_config_qr.py --ascii

Das gescannte JSON hat die Form:
    {"supabaseUrl": "https://xxxx.supabase.co", "supabaseAnonKey": "eyJ..."}
"""

import argparse
import json
import os
import sys


def build_payload(url: str, key: str) -> str:
    url = url.strip()
    key = key.strip()
    if not url.startswith("http"):
        sys.exit("Fehler: --url muss mit http(s) beginnen.")
    if not key:
        sys.exit("Fehler: --key (Anon-Key) darf nicht leer sein.")
    # Kompaktes JSON -> kleinerer / robuster scanbarer QR-Code.
    return json.dumps(
        {"supabaseUrl": url, "supabaseAnonKey": key},
        separators=(",", ":"),
        ensure_ascii=False,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--url", default=os.environ.get("SUPABASE_URL", ""),
                        help="Supabase-Projekt-URL (oder env SUPABASE_URL)")
    parser.add_argument("--key", default=os.environ.get("SUPABASE_ANON_KEY", ""),
                        help="Supabase Anon/Publishable Key (oder env SUPABASE_ANON_KEY)")
    parser.add_argument("--out", default="config_qr.png",
                        help="Pfad der PNG-Ausgabe (Standard: config_qr.png)")
    parser.add_argument("--ascii", action="store_true",
                        help="QR zusätzlich als ASCII im Terminal ausgeben")
    args = parser.parse_args()

    if not args.url or not args.key:
        sys.exit(
            "Bitte --url und --key angeben (oder SUPABASE_URL / SUPABASE_ANON_KEY setzen).\n"
            "Siehe: python tools/make_config_qr.py --help"
        )

    payload = build_payload(args.url, args.key)

    try:
        import qrcode
    except ImportError:
        sys.exit('Das Paket "qrcode" fehlt. Installiere es mit:\n'
                 '    pip install "qrcode[pil]"')

    # Fehlerkorrektur M -> guter Kompromiss aus Robustheit und Datenmenge.
    qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=8, border=2)
    qr.add_data(payload)
    qr.make(fit=True)

    if args.ascii:
        qr.print_ascii(invert=True)

    img = qr.make_image(fill_color="black", back_color="white")
    img.save(args.out)
    print(f"QR-Code gespeichert: {args.out}  ({len(payload)} Zeichen Nutzlast)")
    print("In der App: Zahnrad -> 'QR-Code scannen' (oder Setup-Screen beim ersten Start).")


if __name__ == "__main__":
    main()
