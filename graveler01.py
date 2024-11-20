#!/usr/bin/env python3
import random

numbers = [0,0,0,0]
rolls = 0
maxOnes = 0

while numbers[0] < 177 and rolls < 1000000:

    numbers = [0,0,0,0]

    for _ in range(231):
        roll = random.getrandbits(2)
        numbers[roll] += 1

    if numbers[0] > maxOnes:
        maxOnes = numbers[0]

    rolls += 1

print(f"Highest Ones Roll: {maxOnes}")
print(f"Number of Roll Sessions: {rolls}")
