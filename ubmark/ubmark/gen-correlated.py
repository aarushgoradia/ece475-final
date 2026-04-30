#!/usr/bin/env python3
import numpy as np

np.random.seed(42)
N = 500

# Random data: mix of positive and negative so branches are ~50/50
data = np.random.randint(-1000000, 1000000, size=N).astype(np.int32)

# Reference computation — exactly matches the kernel
ref = []
for x in data:
    val = 0
    if x > 0:
        val = val + x
    if x > 0:
        val = val * 2
    val32 = np.int32(val & 0xFFFFFFFF)
    ref.append(int(val32))

with open("ubmark-correlated.dat", "w") as f:
    f.write("// Data set for ubmark-correlated\n\n")
    f.write("int src[] = {\n")
    for x in data:
        f.write(f"  {x},\n")
    f.write("};\n\n")
    f.write("int ref[] = {\n")
    for x in ref:
        f.write(f"  {x},\n")
    f.write("};\n")

print(f"Generated ubmark-correlated.dat with {N} entries")