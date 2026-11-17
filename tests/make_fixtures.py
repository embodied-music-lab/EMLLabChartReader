"""Write small synthetic LabChart binary (.adibin) files for testing the
EML LabChart Reader plugin, plus tests/expected.json with the values each
file should decode to. The files hold plain known numbers, not recordings.

Usage: python3 tests/make_fixtures.py
"""
import json
import math
import os
import struct

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "fixtures")


def header(dt, n_ch, n_samples, has_time, fmt, date=(2026, 11, 16, 9, 5), sec=7.25, pre=0.0):
    h = b"CFWB" + struct.pack("<i", 1) + struct.pack("<d", dt)
    h += struct.pack("<5i", *date) + struct.pack("<2d", sec, pre)
    h += struct.pack("<4i", n_ch, n_samples, 1 if has_time else 0, fmt)
    return h


def channel_block(title, unit, scale=1.0, offset=0.0, hi=1e9, lo=-1e9):
    return (title.encode("latin-1").ljust(32, b"\0") + unit.encode("latin-1").ljust(32, b"\0")
            + struct.pack("<4d", scale, offset, hi, lo))


def write(name, dt, channels, columns, has_time, fmt, times=None, **kw):
    """channels: list of (title, unit, scale, offset); columns: list of
    per-channel stored values (same length); times: stored time column."""
    n = len(columns[0])
    code = {1: "<d", 2: "<f", 3: "<h"}[fmt]
    b = header(dt, len(channels), n, has_time, fmt, **kw)
    for title, unit, scale, offset in channels:
        b += channel_block(title, unit, scale, offset)
    for i in range(n):
        if has_time:
            b += struct.pack(code, times[i])
        for col in columns:
            b += struct.pack(code, col[i])
    with open(os.path.join(OUT, name), "wb") as f:
        f.write(b)
    # expected real values: (stored + offset) * scale, with float32 rounding
    expected = []
    for (title, unit, scale, offset), col in zip(channels, columns):
        vals = []
        for v in col:
            if fmt == 2:
                v = struct.unpack("<f", struct.pack("<f", v))[0]
            if isinstance(v, float) and (math.isnan(v) or math.isinf(v)):
                vals.append(None)
            else:
                vals.append((v + offset) * scale)
        expected.append(vals)
    first = 0.0
    if has_time and fmt != 3:
        first = times[0] if fmt == 1 else struct.unpack("<f", struct.pack("<f", times[0]))[0]
    return {"file": name, "format": fmt, "has_time": has_time, "dt": dt, "n_samples": n,
            "titles": [c[0].strip() for c in channels], "units": [c[1] for c in channels],
            "first_time": first, "values": expected}


def main():
    os.makedirs(OUT, exist_ok=True)
    cases = []
    dt = 0.001
    n = 10
    t = [i * dt for i in range(n)]
    tiny = 5e-324                      # smallest 64-bit denormal
    a = [0.0, -0.0, 1.5, -2.25, tiny, -tiny, 1e300, -1e-300, 123456.789, 3.0]
    b = [float("nan"), 1.0, float("inf"), -1.0, 0.5, 2.0, -3.5, 4.0, 5.0, 6.0]
    c = [i * 0.1 - 0.3 for i in range(n)]
    cases.append(write("format1_time.adibin", dt,
                       [("Alpha ", "V", 1.0, 0.0), ("Beta Flow", "L/s", 1.0, 0.0), ("Gamma", "mV", 1.0, 0.0)],
                       [a, b, c], True, 1, t))
    ints = [-32768, -1, 0, 1, 2, 100, 32767, -500]
    ints2 = [10, 20, 30, 40, 50, 60, 70, 80]
    cases.append(write("format3_notime.adibin", 0.0005,
                       [("Pressure", "cmH2O", 0.001, 5.0), ("Count", "", 1.0, 0.0)],
                       [ints, ints2], False, 3, date=(2025, 1, 2, 3, 4), sec=59.5, pre=0.25))
    f32tiny = 1.401298464324817e-45     # smallest 32-bit denormal
    d = [0.0, -0.0, f32tiny, -f32tiny, 1.0e-38, 3.4e38, -0.121875, 7.0]
    e = [1.25, 2.5, -1.0, 0.0, 1e-3, -1e-3, 0.333333, 9.0]
    cases.append(write("format2_notime.adibin", 1 / 44100,
                       [("Mic", "V", 1.0, 0.0), ("EGG", "mV", 1.0, 0.0)],
                       [d, e], False, 2))
    tb = [0.0, 0.001, 0.002, 0.0035, 0.004, 0.005]
    cases.append(write("format2_badtime.adibin", 0.001,
                       [("RC", "V", 1.0, 0.0)],
                       [[1.0, 2.0, 3.0, 4.0, 5.0, 6.0]], True, 2, tb))
    cases.append(write("format3_time.adibin", 0.001,
                       [("Belt", "mV", 0.5, -10.0)],
                       [[-3, 0, 7, 32767]], True, 3, [0, 1, 2, 3]))
    cases.append(write("format1_notime.adibin", 0.002,
                       [("A", "V", 2.0, 1.0), ("B", "L", 1.0, 0.0)],
                       [[0.25, -0.5, 1e-310], [9.0, -9.0, 0.0]], False, 1))
    # files the reader must refuse with a message
    good = open(os.path.join(OUT, "format2_badtime.adibin"), "rb").read()
    with open(os.path.join(OUT, "truncated.adibin"), "wb") as f:
        f.write(good[:-6])
    with open(os.path.join(OUT, "badmagic.adibin"), "wb") as f:
        f.write(b"XXXX" + good[4:])
    with open(os.path.join(HERE, "expected.json"), "w") as f:
        json.dump(cases, f, indent=1)


if __name__ == "__main__":
    main()
