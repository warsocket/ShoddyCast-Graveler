# Shoddycast Graveller challenge  proofs / measurements

## Take Notice
> All tests performed with a MegaIteration (1.000.000) instead of a GigaIteration (1.000.000.000), because all stuf is run multiple times and I dont feel like waiting around for months on end :).
So you can just multiply all results by 1000, the relative performance improvement is more improtant that absolute time (I mean else I whould have beaten Austin by almost 5x by just runnig his script on my cpu)

> This algorithm will 100% scale trough multi-core use: Each of the 1.000.000 (or even 1.000.000.000 for the full test) iteration can run in its own process without needint to sync up. But since more cores equals more better, it says little about the algorithm itself. Moreover performance is very dependant on the pc its being run on, (eg using exactly the right amount of cores), and intel's heterogenical multicore layout ( e-cores + p-cores ) make getting good performance without benchmarkig first virutally impossible. And since tuning that feels like kind of out of sscope, I just focussed on single threaded workload tha goed as fast as possible.

## Measurements



### Original code [python3]: 69 seconds
Just ran the original code using python3

```
$ time ./graveler.py         
Highest Ones Roll: 92
Number of Roll Sessions:  1000000
./graveler.py  68,92s user 0,00s system 99% cpu 1:08,93 total
```


### Original code [pypy3]: 20 seconds
Ran the original code using the python jit compiler pypy3

```
$ time pypy3 graveler.py 
Highest Ones Roll: 93
Number of Roll Sessions:  1000000
pypy3 graveler.py  20,10s user 0,05s system 98% cpu 20,451 total
```

That's a `3.43`x improvement totalling `3.43`x.
> Tip for Austin: Try this first next time, a 3x speedup for basically free is always welcome. pypy is a jit compiler for python and is compatible with 99.9% of python (withholding some funky libraries). So if you use no or only builtin libraries you can be virtually sure that pypy wil run your code as well.


### Improved code [pypy3]: 8 seconds

Just replacing 
```
roll = random.choice(items)
numbers[roll-1] = numbers[roll-1] + 1
```
for
```
roll = random.getrandbits(2)
numbers[roll] = numbers[roll] + 1
```
(And removing the, now defunct +1's in the following idices)

[this](./graveler.py) becomes [this](./graveler01.py)

improves the time signigficantly:
```
$ time pypy3 graveler01.py
Highest Ones Roll: 89
Number of Roll Sessions:  1000000
pypy3 graveler01.py  7,88s user 0,02s system 99% cpu 7,918 total
```

That's a `2.55`x improvement totalling `8.75`x.

### Code cleanup on ilse 5
> This refactoring will also make it more easy to implement it in other languages later.

Just gonna refactor a bit now to make code more readable:

* Removing unused imports.
* Using formatted strings to print.
* Some code spacing.
* Cleaned up loop iterating over list of None, it was just a plain loop
* Refactored the while loop into a for loop with a break statement
* Removed numbers array, since we only used index 0, so we can just use a normal varaible for that
* Arguably using `max` reads more easily than using a 2 line if statement
* Added a constant to set the number of iterations: NUM_ITERS

> `if not roll:` triggers if roll is not 0, ergo the only index we actually used.

[this](./graveler01.py) becomes [this](./graveler02.py)

Since its a refactor only it has no significant impact on runtime:
```
$ time pypy3 graveler02.py
Highest Ones Roll: 92
Number of Roll Sessions: 999999
pypy3 graveler02.py  7,76s user 0,02s system 99% cpu 7,801 total
```

### Improved code [rust]: 0.55 seconds

Implemented the same thing in rust, and for structure you should be able to reconise it form what we made in Python:
[See here](./graveler-rust/src/main.rs)
> Please beware that this is linked the code to run a billion (1.000.000.000) times and not a million (1.000.000) times like the rest of the tests.
> You can change this by setting the NUM_ITERS constant.

to compile:
`cd graveler-rust && cargo build --release ; cd -`

> Don't forget the `--release` flag, since without you will build a debug version, which is easyer to debug but significantly slower!

lets time it:

```
$ time ./graveler-rust/target/release/graveler-rust 
Highest Ones Roll: 91
Number of Roll Sessions: 1000000
./graveler-rust/target/release/graveler-rust  0,55s user 0,00s system 99% cpu 0,554 total

```

That's a `14.33`x improvement Over our python code (running pypy3)) totalling `125.31`x.
And you wonder why python is called slow ;).

Since that really borders on a micro benchmark (where initialising stuff etc can really ipact the measurement), I decided to also run the full billion iterations :)

```
$ time ./graveler-rust/target/release/graveler-rust 
Highest Ones Roll: 101
Number of Roll Sessions: 1000000000
./graveler-rust/target/release/graveler-rust  534,98s user 3,61s system 99% cpu 8:58,61 total

```



### Own code [x86 assembler (using AVX2 instruction set)]: 0.13s
In your video you said flex, so its tiome to flex :D

I wil not only hand-careft this in assembler, I will gain over more power by utilising the parallel instruction sets like SSEx/AVX2.
That are the instruction with opcodes that look like someone had a seizure on his keyboard (`vpsadbw` anyone?).

[See here](./graveler.nasm)
> Please beware that this is linked the code to run a billion (1.000.000.000) times and not a million (1.000.000) times like the rest of the tests.
> You can change this by setting the NUM_ITERS constant.

to compile:
`nasm -f elf64 graveler.nasm && ld -o  graveler graveler.o`

> Please beware that assembly is not platform agnostic, even if it runs on the smae cpu, this version is made for linux.

lets time it:
```
$ time ./graveler
Highest Ones Roll: 094
./graveler  0,13s user 0,00s system 99% cpu 0,134 total

```

That's a `4.23`x improvement Over our rust code totalling `530.15`x.

Since that really borders on a micro benchmark (where initialising stuff etc can really ipact the measurement), I decided to also run the full billion iterations :)

```
$ time ./graveler
Highest Ones Roll: 106
./graveler  125,84s user 0,00s system 99% cpu 2:05,84 total

```
Compared to rusts 1 billion run that's a `4.25`x Which is close enough to the measured 4.23.


125,84s is aprox. 2 mins, so given that your cpu was aprox. 5x slower you would have been done in roughly 10min; Enough time to run it twice while you had dinner :)

Sincerely,
Warsocket

