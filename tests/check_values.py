"""Compare the Sounds the reader made from the fixtures with tests/expected.json.
Usage: python3 tests/check_values.py <folder with the .Sound files>"""
import json, struct, sys, math
import os
HERE = os.path.dirname(os.path.abspath(__file__))
OUTDIR = sys.argv[1]
exp = json.load(open(os.path.join(HERE, 'expected.json')))
ok = True
for case in exp:
    name = case['file'].replace('.adibin', '')
    b = open(os.path.join(OUTDIR, name + '.Sound'), 'rb').read()
    nch = len(case['values']); n = case['n_samples']
    vals = struct.unpack('>%dd' % (nch * n), b[-nch * n * 8:])
    i = b.index(b'Sound 2') + 7
    xmin, xmax = struct.unpack('>dd', b[i:i+16]); nx = struct.unpack('>i', b[i+16:i+20])[0]; dx, x1 = struct.unpack('>dd', b[i+20:i+36])
    bad = 0
    for c in range(nch):
        for k in range(n):
            got = vals[c * n + k]; want = case['values'][c][k]
            if want is None:
                if not (math.isnan(got) or math.isinf(got)): bad += 1  # Praat stores undefined as inf
            elif got != want or (want == 0 and math.copysign(1, got) != math.copysign(1, want)):
                if not (want == 0 and got == 0): bad += 1
                if got != want: print('  mismatch', name, c + 1, k + 1, repr(got), repr(want))
    t_ok = abs(x1 - case['first_time']) < 1e-12 and abs(dx - case['dt']) < 1e-15 and nx == n
    print(name, 'values exact' if bad == 0 else f'{bad} BAD', '| x1', x1, 'dx', dx, 'nx', nx, '| axis', 'ok' if t_ok else 'BAD')
    ok = ok and bad == 0 and t_ok
print('ALL PASS' if ok else 'FAILURES')
sys.exit(0 if ok else 1)
