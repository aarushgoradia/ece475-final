#!/usr/bin/env python3
import numpy as np

np.random.seed(42)
N = 50

src = np.random.randint(-1000000, 1000000, size=N).astype(np.int32)

# Reference: matches the kernel exactly
ref = 0
for i in range(N):
    for j in range(10):
        for k in range(10):
            ref += int(src[i]) + j + k

# Wrap to int32
ref = np.int32(ref & 0xFFFFFFFF)

with open("ubmark-nested-loops.dat", "w") as f:
    f.write("// Data set for ubmark-nested-loops\n\n")
    f.write("int src[] = {\n")
    for x in src:
        f.write(f"  {x},\n")
    f.write("};\n\n")
    f.write(f"int ref = {int(ref)};\n")

print(f"Generated ubmark-nested-loops.dat with {N} entries")