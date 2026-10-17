#!/usr/bin/env python3
"""Mostra versionCode/versionName/minSdk/targetSdk/extractNativeLibs di un APK (legge il manifest binario)."""
import struct
import sys
import zipfile


def parse(data):
    off = 8
    strings = []
    out = {}
    while off < len(data):
        t, hs, sz = struct.unpack_from("<HHI", data, off)
        if t == 0x0001:  # string pool
            n, ns, flags, ss, so = struct.unpack_from("<IIIII", data, off + 8)
            utf8 = flags & 0x100
            offs = struct.unpack_from("<%dI" % n, data, off + 28)
            base = off + ss
            for o in offs:
                p = base + o
                if utf8:
                    l = data[p + 1] if data[p] & 0x80 == 0 else 0
                    p2 = p + 2
                    ln = data[p + 1]
                    strings.append(data[p2:p2 + ln].decode("utf8", "ignore"))
                else:
                    ln = struct.unpack_from("<H", data, p)[0]
                    strings.append(data[p + 2:p + 2 + ln * 2].decode("utf-16le", "ignore"))
        elif t == 0x0102:  # start element
            ns2, name = struct.unpack_from("<II", data, off + 16)
            astart, asize, count = struct.unpack_from("<HHH", data, off + 24)
            ename = strings[name]
            ao = off + 16 + astart
            for i in range(count):
                a_ns, a_name, a_raw, a_size, a_res0, a_type, a_data = struct.unpack_from("<IIIHBBI", data, ao + i * asize)
                an = strings[a_name]
                if an in ("versionCode", "versionName", "minSdkVersion", "targetSdkVersion", "extractNativeLibs", "package", "isGame"):
                    out[an] = strings[a_raw] if a_raw != 0xFFFFFFFF else a_data
        off += sz
    return out


if __name__ == "__main__":
    for f in sys.argv[1:]:
        z = zipfile.ZipFile(f)
        print(f, parse(z.read("AndroidManifest.xml")))
