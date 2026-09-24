"""Encode 24-bit BMP frames into a looping GIF89a with a 32-step gray palette."""
import struct
import sys
from pathlib import Path


def read_bmp(path):
    data = Path(path).read_bytes()
    if data[:2] != b"BM":
        raise SystemExit(f"not a bmp: {path}")
    offset = struct.unpack_from("<I", data, 10)[0]
    width, height = struct.unpack_from("<ii", data, 18)
    bpp = struct.unpack_from("<H", data, 28)[0]
    if bpp not in (24, 32):
        raise SystemExit(f"expected 24 or 32bpp, got {bpp}")
    top_down = height < 0
    height = abs(height)
    channels = bpp // 8
    row_stride = (width * channels + 3) & ~3
    pixels = []
    for y in range(height):
        src_y = y if top_down else height - 1 - y
        row = data[offset + src_y * row_stride : offset + src_y * row_stride + width * channels]
        idx = bytearray(width)
        for x in range(width):
            b = row[x * channels]
            g = row[x * channels + 1]
            r = row[x * channels + 2]
            gray = (r * 30 + g * 59 + b * 11) // 100
            idx[x] = min(31, gray * 32 // 256)
        pixels.append(idx)
    return width, height, pixels


def lzw(indexes, min_code_size):
    clear = 1 << min_code_size
    eoi = clear + 1
    code_size = min_code_size + 1
    next_code = eoi + 1
    table = {bytes([i]): i for i in range(clear)}
    out = bytearray()
    bit_buf = 0
    bit_count = 0

    def write(code, size):
        nonlocal bit_buf, bit_count
        bit_buf |= code << bit_count
        bit_count += size
        while bit_count >= 8:
            out.append(bit_buf & 0xFF)
            bit_buf >>= 8
            bit_count -= 8

    write(clear, code_size)
    w = b""
    for byte in indexes:
        k = bytes([byte])
        wk = w + k
        if wk in table:
            w = wk
            continue
        write(table[w], code_size)
        if next_code < 4096:
            table[wk] = next_code
            next_code += 1
            if next_code > (1 << code_size) and code_size < 12:
                code_size += 1
        else:
            write(clear, code_size)
            table = {bytes([i]): i for i in range(clear)}
            next_code = eoi + 1
            code_size = min_code_size + 1
        w = k
    if w:
        write(table[w], code_size)
    write(eoi, code_size)
    if bit_count:
        out.append(bit_buf & 0xFF)
    return bytes(out)


def subblocks(blob):
    parts = []
    for i in range(0, len(blob), 255):
        chunk = blob[i : i + 255]
        parts.append(bytes([len(chunk)]) + chunk)
    parts.append(b"\x00")
    return b"".join(parts)


def encode(frame_paths, dest, delay_cs=12):
    frames = [read_bmp(p) for p in frame_paths]
    width, height, _ = frames[0]
    # 32-color global table. Size flag 4 => 2^(4+1)=32. min code size 5.
    gct = bytearray()
    for i in range(32):
        v = min(255, i * 255 // 31)
        gct += bytes((v, v, v))
    out = bytearray(b"GIF89a")
    packed = 0x80 | (7 << 4) | 4
    out += struct.pack("<HHBBB", width, height, packed, 0, 0)
    out += gct
    # loop forever
    out += b"\x21\xff\x0bNETSCAPE2.0\x03\x01\x00\x00\x00"
    for _, _, rows in frames:
        out += b"\x21\xf9\x04\x04"
        out += struct.pack("<H", delay_cs)
        out += b"\x00\x00"
        out += b"\x2c" + struct.pack("<HHHHB", 0, 0, width, height, 0)
        indexes = b"".join(rows)
        out += bytes([5])
        out += subblocks(lzw(indexes, 5))
    out += b"\x3b"
    Path(dest).write_bytes(out)
    print(dest, len(out))


if __name__ == "__main__":
    encode(sys.argv[3:], sys.argv[1], delay_cs=int(sys.argv[2]))
