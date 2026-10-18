#!/usr/bin/env python3
"""Ricomprime e firma un APK esportato da Godot (firma APK v2), senza Android SDK.

Uso: python3 tools/sign_apk.py ingresso.apk uscita.apk chiave.pem

- Tutto compresso al massimo (anche le librerie native, come la V2), tranne resources.arsc:
  quello resta senza compressione e allineato a 4 byte, come richiede Android 11+.
- Firma APK Signature Scheme v2 (RSA 2048, SHA-256). Basta per Android 7+ (minSdk del template Godot = 24).
- La chiave: se il file .pem non esiste, ne crea una nuova (con certificato autofirmato).
  ATTENZIONE: un aggiornamento firmato con una chiave diversa non si installa sopra la versione precedente
  (bisogna disinstallare prima). La chiave NON va nel repo.
- Alla fine ricontrolla da sola digest e firma.
"""
import datetime
import hashlib
import os
import struct
import sys
import zipfile

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.x509.oid import NameOID

V2_ID = 0x7109871A
ALG_RSA_PKCS1_SHA256 = 0x0103
MAGIC = b"APK Sig Block 42"
CHUNK = 1024 * 1024


def lp(b: bytes) -> bytes:
    return struct.pack("<I", len(b)) + b


def load_key(path):
    if not os.path.exists(path):
        key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "ODISPEL V3 test"), x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Gialloo")])
        now = datetime.datetime(2026, 1, 1)
        cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(key.public_key())
                .serial_number(x509.random_serial_number()).not_valid_before(now)
                .not_valid_after(now + datetime.timedelta(days=365 * 30)).sign(key, hashes.SHA256()))
        with open(path, "wb") as f:
            f.write(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))
            f.write(cert.public_bytes(serialization.Encoding.PEM))
        os.chmod(path, 0o600)
    data = open(path, "rb").read()
    key = serialization.load_pem_private_key(data, None)
    cert = x509.load_pem_x509_certificate(data[data.index(b"-----BEGIN CERTIFICATE-----"):])
    return key, cert


def repack(src, dst):
    with zipfile.ZipFile(src) as zin, open(dst, "wb") as raw:
        zout = zipfile.ZipFile(raw, "w", zipfile.ZIP_DEFLATED, compresslevel=9)
        for info in zin.infolist():
            if info.filename.startswith("META-INF/") and info.filename.split("/")[-1].upper().endswith((".SF", ".RSA", ".EC", ".DSA", "MANIFEST.MF")):
                continue
            data = zin.read(info.filename)
            ni = zipfile.ZipInfo(info.filename, date_time=info.date_time)
            ni.external_attr = info.external_attr
            if info.filename == "resources.arsc":
                ni.compress_type = zipfile.ZIP_STORED
                start = raw.tell() + 30 + len(info.filename.encode())
                pad = (-start) % 4
                if pad:
                    ni.extra = b"\x00" * pad
            else:
                ni.compress_type = zipfile.ZIP_DEFLATED
            zout.writestr(ni, data, compress_type=ni.compress_type, compresslevel=9)
        zout.close()


def find_eocd(buf):
    i = buf.rfind(b"PK\x05\x06")
    if i < 0:
        raise SystemExit("EOCD non trovato")
    cd_size, cd_off = struct.unpack("<II", buf[i + 12:i + 20])
    return i, cd_off, cd_size


def chunk_digest(sections):
    digests = []
    for sec in sections:
        for k in range(0, len(sec), CHUNK):
            part = sec[k:k + CHUNK]
            digests.append(hashlib.sha256(b"\xa5" + struct.pack("<I", len(part)) + part).digest())
    return hashlib.sha256(b"\x5a" + struct.pack("<I", len(digests)) + b"".join(digests)).digest()


def v2_digest(entries, cd, eocd, cd_offset_for_digest):
    e = bytearray(eocd)
    e[16:20] = struct.pack("<I", cd_offset_for_digest)
    return chunk_digest([entries, cd, bytes(e)])


def sign(src, dst, key_path):
    key, cert = load_key(key_path)
    buf = open(src, "rb").read()
    eocd_i, cd_off, cd_size = find_eocd(buf)
    entries, cd, eocd = buf[:cd_off], buf[cd_off:cd_off + cd_size], buf[eocd_i:]
    digest = v2_digest(entries, cd, eocd, cd_off)
    cert_der = cert.public_bytes(serialization.Encoding.DER)
    pub_der = key.public_key().public_bytes(serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo)
    signed_data = (lp(lp(struct.pack("<I", ALG_RSA_PKCS1_SHA256) + lp(digest)))
                   + lp(lp(cert_der))
                   + lp(b""))
    sig = key.sign(signed_data, padding.PKCS1v15(), hashes.SHA256())
    signer = lp(signed_data) + lp(lp(struct.pack("<I", ALG_RSA_PKCS1_SHA256) + lp(sig))) + lp(pub_der)
    value = lp(lp(signer))
    pair = struct.pack("<Q", len(value) + 4) + struct.pack("<I", V2_ID) + value
    size = len(pair) + 8 + 16
    block = struct.pack("<Q", size) + pair + struct.pack("<Q", size) + MAGIC
    new_eocd = bytearray(eocd)
    new_eocd[16:20] = struct.pack("<I", cd_off + len(block))
    with open(dst, "wb") as f:
        f.write(entries + block + cd + bytes(new_eocd))


def verify(path):
    buf = open(path, "rb").read()
    eocd_i, cd_off, cd_size = find_eocd(buf)
    assert buf[cd_off - 16:cd_off] == MAGIC, "blocco di firma mancante"
    size = struct.unpack("<Q", buf[cd_off - 24:cd_off - 16])[0]
    bstart = cd_off - size - 8
    assert struct.unpack("<Q", buf[bstart:bstart + 8])[0] == size
    pairs = buf[bstart + 8:cd_off - 24]
    p = 0
    value = None
    while p < len(pairs):
        ln = struct.unpack("<Q", pairs[p:p + 8])[0]
        pid = struct.unpack("<I", pairs[p + 8:p + 12])[0]
        if pid == V2_ID:
            value = pairs[p + 12:p + 8 + ln]
        p += 8 + ln
    assert value is not None, "firma v2 assente"

    def rd(b, o):
        n = struct.unpack("<I", b[o:o + 4])[0]
        return b[o + 4:o + 4 + n], o + 4 + n
    signers, _ = rd(value, 0)
    signer, _ = rd(signers, 0)
    sd, o = rd(signer, 0)
    sigs, o = rd(signer, o)
    pub, _ = rd(signer, o)
    s1, _ = rd(sigs, 0)
    sig, _ = rd(s1, 4)
    pk = serialization.load_der_public_key(pub)
    pk.verify(sig, sd, padding.PKCS1v15(), hashes.SHA256())
    dg, _ = rd(sd, 0)
    d1, _ = rd(dg, 0)
    want, _ = rd(d1, 4)
    got = v2_digest(buf[:bstart], buf[cd_off:cd_off + cd_size], buf[eocd_i:], bstart)
    assert got == want, "digest non corrisponde"
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        i = z.getinfo("resources.arsc")
        assert i.compress_type == zipfile.ZIP_STORED
        with open(path, "rb") as f:
            f.seek(i.header_offset)
            h = f.read(30)
            n, e = struct.unpack("<HH", h[26:30])
            assert (i.header_offset + 30 + n + e) % 4 == 0, "resources.arsc non allineato"
    return True


def main(src, dst, key_path):
    tmp = dst + ".unsigned"
    repack(src, tmp)
    sign(tmp, dst, key_path)
    os.remove(tmp)
    verify(dst)
    print("ok: %d -> %d byte, firma v2 verificata" % (os.path.getsize(src), os.path.getsize(dst)))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
