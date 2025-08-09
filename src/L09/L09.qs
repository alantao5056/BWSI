// Quantum Software Development
// Lab 9: Shor's Factorization Algorithm
// Copyright 2024 The MITRE Corporation. All Rights Reserved.
//
// Due 4/24.
//
// Note: Use little endian ordering when storing and retrieving integers from
// qubit registers in this lab.

namespace MITRE.QSD.L09 {

    import Std.Math.ExpModI;
    import Std.Math.Floor;
    import MITRE.QSD.L08.E01_QFT;
    import Std.Math.Log;
    import Std.Math.LogOf2;
    import Std.Diagnostics.DumpMachine;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Unstable.Arithmetic;


    /// # Summary
    /// Performs modular in-place multiplication by a classical constant.
    ///
    /// # Description
    /// Given the classical constants `c` and `modulus`, and an input quantum
    /// register |𝑦⟩ in little-endian format, this operation computes
    /// `(c*y) % modulus` into |𝑦⟩.
    ///
    /// # Input
    /// ## modulus
    /// Modulus to use for modular multiplication
    /// ## c
    /// Constant by which to multiply |𝑦⟩
    /// ## y
    /// Quantum register of target
    ///
    /// # Remarks
    /// Taken from code sample in Q# playground.
    operation ModularMultiplyByConstant(modulus : Int, c : Int, y : Qubit[])
    : Unit is Adj + Ctl {
        use qs = Qubit[Length(y)];
        for idx in IndexRange(y) {
            let shiftedC = (c <<< idx) % modulus;
            Controlled ModularAddConstant(
                [y[idx]],
                (modulus, shiftedC, qs));
        }
        for idx in IndexRange(y) {
            SWAP(y[idx], qs[idx]);
        }
        let invC = InverseModI(c, modulus);
        for idx in IndexRange(y) {
            let shiftedC = (invC <<< idx) % modulus;
            Controlled ModularAddConstant(
                [y[idx]],
                (modulus, modulus - shiftedC, qs));
        }
    }


    /// # Summary
    /// Performs modular in-place addition of a classical constant into a
    /// quantum register.
    ///
    /// Given the classical constants `c` and `modulus`, and an input quantum
    /// register |𝑦⟩ in little-endian format, this operation computes
    /// `(y+c) % modulus` into |𝑦⟩.
    ///
    /// # Input
    /// ## modulus
    /// Modulus to use for modular addition
    /// ## c
    /// Constant to add to |𝑦⟩
    /// ## y
    /// Quantum register of target
    ///
    /// # Remarks
    /// Taken from code sample in Q# playground.
    operation ModularAddConstant(modulus : Int, c : Int, y : Qubit[])
    : Unit is Adj + Ctl {
        body (...) {
            Controlled ModularAddConstant([], (modulus, c, y));
        }
        controlled (ctrls, ...) {
            // We apply a custom strategy to control this operation instead of
            // letting the compiler create the controlled variant for us in
            // which the `Controlled` functor would be distributed over each
            // operation in the body.
            //
            // Here we can use some scratch memory to save ensure that at most
            // one control qubit is used for costly operations such as
            // `AddConstant` and `CompareGreaterThenOrEqualConstant`.
            if Length(ctrls) >= 2 {
                use control = Qubit();
                within {
                    Controlled X(ctrls, control);
                } apply {
                    Controlled ModularAddConstant([control], (modulus, c, y));
                }
            } else {
                use carry = Qubit();
                Controlled IncByI(ctrls, (c, y + [carry]));
                Controlled Adjoint IncByI(ctrls, (modulus, y + [carry]));
                Controlled IncByI([carry], (modulus, y));
                Controlled ApplyIfLessOrEqualL(ctrls, (X, IntAsBigInt(c), y, carry));
            }
        }
    }


    /// # Summary
    /// In this exercise, you must implement the quantum modular
    /// exponentiation function: |o> = a^|x> mod b.
    /// |x> and |o> are input and output registers respectively, and a and b
    /// are classical integers.
    ///
    /// # Input
    /// ## a
    /// The base power of the term being exponentiated.
    ///
    /// ## b
    /// The modulus for the function.
    ///
    /// ## input
    /// The register containing a superposition of all of the exponent values
    /// that the user wants to calculate; this superposition is arbitrary.
    ///
    /// ## output
    /// This register must contain the output |o> of the modular
    /// exponentiation function. It will start in the |0...0> state.
    operation E01_ModExp (
        a : Int,
        b : Int,
        input : Qubit[],
        output : Qubit[]
    ) : Unit {
        // Notes:
        //  - Use Microsoft.Quantum.Math.ExpModI() to calculate a modular
        //    exponent classically.
        //  - Use the ModularMultiplyByConstant operation above to multiply a
        //    qubit register by a constant under some modulus.

        // TODO
        let n = Length(input);
        let m = Length(output);
        X(output[m-1]);
        Message($"A {a}, B {b}, N {n}, M {m}");
        for i in 0..(n-1) {
            let p = n - 1 - i;
            let pow = 2 ^ p;
            let c = ExpModI(a, pow, b); // c = A^(2^(n-i-1)) mod b
            Controlled ModularMultiplyByConstant([input[i]], (b, c, output));
        }

        //DumpMachine();
    }


    /// # Summary
    /// In this exercise, you must implement the quantum subroutine of Shor's
    /// algorithm. You will be given a number to factor and some guess to a
    /// possible factor - both of which are integers.
    /// You must set up, execute, and measure the quantum circuit.
    /// You should return the fraction that was produced by measuring the
    /// result at the end of the subroutine, in the form of a tuple:
    /// the first value should be the number you measured, and the second
    /// value should be 2^n, where n is the number of qubits you use in your
    /// input register.
    ///
    /// # Input
    /// ## numberToFactor
    /// The number that the user wants to factor. This will become the modulus
    /// for the modular arithmetic used in the subroutine.
    ///
    /// ## guess
    /// The number that's being guessed as a possible factor. This will become
    /// the base of exponentiation for the modular arithmetic used in the 
    /// subroutine.
    ///
    /// # Output
    /// A tuple representing the continued fraction approximation that the
    /// subroutine measured. The first value should be the numerator (the
    /// value that was measured from the qubits), and the second value should
    /// be the denominator (the total size of the input space, which is 2^n
    /// where n is the size of your input register).
    function GCD (a: Int, b: Int) : Int {
      if (b == 0) {return a};
      return GCD(b, a % b);
    }
    operation E02_FindApproxPeriod (
        numberToFactor : Int,
        guess : Int
    ) : (Int, Int) {
        // Hint: you can use the Microsoft.Quantum.Measurement.MeasureInteger()
        // function to measure a whole set of qubits and transform them into
        // their integer representation.

        // TODO
        // let temp = GCD(numberToFactor, guess);
        // if temp != 1 {
        //     return (temp, numberToFactor/temp); // If guess is not coprime with numberToFactor
        // }

        // find period of f(x) = g^x mod N
        //let n = Ceiling(Lg(IntAsDouble(numberToFactor)));
        //let n = Ceiling(Log(IntAsDouble(numberToFactor)+1.0)/(LogOf2()));
        let n = BitSizeI(numberToFactor);

        use input = Qubit[2*n];
        use output = Qubit[n];
        ApplyToEach(H, input);

        E01_ModExp(guess, numberToFactor, input, output);
        //MeasureInteger(output);
        // swap??
        //E01_QFT(input);
        Adjoint ApplyQFT(input);
        // swap??
        let estFreq = MeasureInteger(input);

        ResetAll(input);
        ResetAll(output);

        Message($"Measured frequency: {estFreq}");

        return (estFreq, 2^(2*n));
    }


    /// # Summary
    /// In this exercise, you will be given an arbitrary numerator and
    /// denominator for a fraction, along with some threshold value for the
    /// denominator.
    /// Your goal is to return the largest convergent of the continued
    /// fraction that matches the provided number, with the condition that the
    /// denominator of your convergent must be less than the threshold value.
    ///
    /// # Input
    /// ## numerator
    /// The numerator of the original fraction
    ///
    /// ## denominator
    /// The denominator of the original fraction
    ///
    /// ## denominatorThreshold
    /// A threshold value for the denominator. The continued fraction
    /// convergent that you find must be less than this value. If it's higher,
    /// you must return the previous convergent.
    ///
    /// # Output
    /// A tuple representing the convergent that you found. The first element
    /// should be the numerator, and the second should be the denominator.
    function E03_FindPeriodCandidate (
        numerator : Int,
        denominator : Int,
        denominatorThreshold : Int
    ) : (Int, Int) {
        mutable p = numerator;
        mutable q = denominator;
        mutable n = 1;
        mutable prevN = 0;
        mutable d = 0;
        mutable prevD = 1;

        Message($"p: {p}, q: {q}, threshold: {denominatorThreshold}");

        mutable r = 1;
        while d <= denominatorThreshold and r != 0 {
            let a = p / q;
            r = p % q;
            p = q;
            q = r;
            let tn = n;
            let td = d;
            n = a*n + prevN;
            d = a*d + prevD;
            prevN = tn;
            prevD = td;
            Message($"p: {p}, q: {q}, n: {n}, d: {d}");
        }

        if d <= denominatorThreshold {
            return (n, d);
        }
        return (prevN, prevD);
    }


    /// # Summary
    /// In this exercise, you are given two integers - a number that you want
    /// to find the factors of, and an arbitrary guess as to one of the
    /// factors of the number. This guess was already checked to see if it was
    /// a factor of the number, so you know that it *isn't* a factor. It is
    /// guaranteed to be co-prime with numberToFactor.
    ///
    /// Your job is to find the period of the modular exponentation function
    /// using these two values as the arguments. That is, you must find the
    /// period of the equation y = guess^x mod numberToFactor.
    ///
    /// # Input
    /// ## numberToFactor
    /// The number that the user wants to find the factors for
    ///
    /// ## guess
    /// Some co-prime integer that is smaller than numberToFactor
    ///
    /// # Output
    /// The period of y = guess^x mod numberToFactor.
    operation E04_FindPeriod (numberToFactor : Int, guess : Int) : Int
    {
        // Note: you can't use while loops in operations in Q#.
        // You'll have to use a repeat loop if you want to run
        // something several times.

        // Hint: you can use the
        // Microsoft.Quantum.Math.GreatestCommonDivisorI()
        // function to calculate the GCD of two numbers.

        // TODO
        mutable x = 1;
        while true {
            if ExpModI(guess, x, numberToFactor) == 1 {
                Message($"Found period: {x}");
                return x;
            }
            x += 1;
        }
        return -1;
    }


    /// # Summary
    /// In this exercise, you are given a number to find the factors of,
    /// a guess of a factor (which is guaranteed to be co-prime), and the
    /// period of the modular exponentiation function that you found in
    /// Exercise 4.
    ///
    /// Your goal is to use the period to find a factor of the number if
    /// possible.
    ///
    /// # Input
    /// ## numberToFactor
    /// The number to find a factor of
    ///
    /// ## guess
    /// A co-prime number that is *not* a factor
    ///
    /// ## period
    /// The period of the function y = guess^x mod numberToFactor.
    ///
    /// # Output
    /// - If you can find a factor, return that factor.
    /// - If the period is odd, return -1.
    /// - If the period doesn't work for factoring, return -2.
    function E05_FindFactor (
        numberToFactor : Int,
        guess : Int,
        period : Int
    ) : Int {
        // TODO
        if (period % 2 != 0) {
            return -1; // Period is odd, can't factor
        }

        let a = ExpModI(guess, period / 2, numberToFactor);
        let b = GCD(a - 1, numberToFactor);
        if (b == 1 or b == numberToFactor) {
            return -2; // Can't find a factor
        }
        return b; // Found a factor
    }
}
