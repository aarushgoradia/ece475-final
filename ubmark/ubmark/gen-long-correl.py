#!/usr/bin/env python3
import numpy as np

np.random.seed(42)
N = 1000
NOISE_LEN = 12

# Generate random arrays
src = np.random.randint(-1000000, 1000000, size=N).astype(np.int32)
noise = np.random.randint(0, 100000, size=N * NOISE_LEN).astype(np.int32)

# Reference: matches the kernel exactly
ref = 0
for i in range(N):
    flag = 0
    
    if src[i] > 0:
        flag = 1
        
    for j in range(NOISE_LEN):
        if noise[i*NOISE_LEN + j] % 2 == 0:
            ref += 1
        else:
            ref -= 1
            
    if flag == 1:
        ref += 10
    else:
        ref -= 10

# Wrap to int32
ref = np.int32(ref & 0xFFFFFFFF)

with open("ubmark-long-correl.dat", "w") as f:
    f.write("// Data set for ubmark-long-correl\n\n")
    
    # Write src array
    f.write(f"int src[{N}] = {{\n")
    for x in src:
        f.write(f"  {x},\n")
    f.write("};\n\n")
    
    # Write noise array
    f.write(f"int noise[{N * NOISE_LEN}] = {{\n")
    for x in noise:
        f.write(f"  {x},\n")
    f.write("};\n\n")
    
    # Write reference value
    f.write(f"int ref = {int(ref)};\n")

print(f"Generated ubmark-long-correl.dat with N={N} (Total inner loops = {N * NOISE_LEN})")