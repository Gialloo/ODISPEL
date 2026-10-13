#!/usr/bin/env python3
"""Ricomprime un APK esportato da Godot (deflate al massimo, anche le librerie native) e lo firma di nuovo.

Uso: python3 tools/shrink_apk.py ingresso.apk uscita.apk
Serve apksigner (Android SDK build-tools) e la chiave di debug in /root/debug.keystore.
resources.arsc resta senza compressione e allineato a 4 byte, come richiede Android 11+.
"""
import os
import struct
import subprocess
import sys
import zipfile
import zlib

SIGN_FILES = ("META-INF/",)


def main(src, dst):
    tmp = dst + ".unsigned"
    with zipfile.ZipFile(src) as zin, open(tmp, "wb") as raw:
        zout = zipfile.ZipFile(raw, "w", zipfile.ZIP_DEFLATED, compresslevel=9)
        for info in zin.infolist():
            if info.filename.startswith(SIGN_FILES):
                continue           # le firme si rifanno
            data = zin.read(info.filename)
            ni = zipfile.ZipInfo(info.filename, date_time=info.date_time)
            ni.external_attr = info.external_attr
            if info.filename == "resources.arsc":
                ni.compress_type = zipfile.ZIP_STORED
                # allineamento a 4 byte dell'inizio dei dati
                start = raw.tell() + 30 + len(info.filename.encode())
                pad = (-start) % 4
                if pad:
                    ni.extra = b"\x00" * pad
            else:
                ni.compress_type = zipfile.ZIP_DEFLATED
            zout.writestr(ni, data, compress_type=ni.compress_type, compresslevel=9)
        zout.close()
    subprocess.check_call([
        "/root/android-sdk/build-tools/35.0.1/apksigner", "sign",
        "--ks", "/root/debug.keystore", "--ks-pass", "pass:android", "--key-pass", "pass:android",
        "--out", dst, tmp])
    os.remove(tmp)
    # controlli: firma valida e resources.arsc allineato
    subprocess.check_call(["/root/android-sdk/build-tools/35.0.1/apksigner", "verify", "--verbose", dst])
    with zipfile.ZipFile(dst) as z:
        i = z.getinfo("resources.arsc")
        assert i.compress_type == zipfile.ZIP_STORED
        with open(dst, "rb") as f:
            f.seek(i.header_offset)
            h = f.read(30)
            n, e = struct.unpack("<HH", h[26:30])
            assert (i.header_offset + 30 + n + e) % 4 == 0, "resources.arsc non allineato"
        assert z.testzip() is None
    print("ok: %d -> %d byte" % (os.path.getsize(src), os.path.getsize(dst)))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
