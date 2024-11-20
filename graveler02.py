#!/usr/bin/env python3
NUM_ITERS = 1000000;

import random

maxNumber = 0
maxOnes = 0

for rolls in range(NUM_ITERS):

    maxNumber = 0

    for _ in range(231):
        roll = random.getrandbits(2)
        if not roll: maxNumber += 1 

    maxOnes = max(maxOnes, maxNumber)

    if maxNumber >= 177: break

print(f"Highest Ones Roll: {maxOnes}")
print(f"Number of Roll Sessions: {rolls+1}")
