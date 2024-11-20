// change number of iterations here:
const NUM_ITERS:usize = 1000000000;

use rand::prelude::*;
use std::cmp::max;

fn rnd() -> usize{
    usize::from(random::<u8>() & 0x03)
}

fn main() {

    let mut maxNumber:usize = 0;
    let mut maxOnes:usize = 0;
    let mut rolls:usize = 0;

    for _ in 0..NUM_ITERS{
        maxNumber = 0;

        for _ in 0..231{
            let roll = rnd();
            if (roll == 0){ maxNumber += 1; }
        }

        maxOnes = max(maxOnes, maxNumber);

        rolls += 1;
        if maxNumber >= 177{ break }
    }

    println!("Highest Ones Roll: {maxOnes}");
    println!("Number of Roll Sessions: {rolls}");

}
