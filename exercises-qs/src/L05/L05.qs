// Quantum Software Development
// Lab 5: Toy Algorithms
// Copyright 2024 The MITRE Corporation. All Rights Reserved.
//
// Due 3/13.

namespace MITRE.QSD.L05 {

    import Std.Diagnostics.DumpMachine;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;


    /// # Summary
    /// This oracle always "returns" zero, so it never phase-flips the target
    /// qubit.
    ///
    /// # Input
    /// ## input
    /// The input register to evaluate.
    ///
    /// ## target
    /// The target qubit to phase-flip.
    operation AlwaysZero (input : Qubit[], target : Qubit) : Unit {
        // This literally does nothing, no matter what the input is.
    }


    /// # Summary
    /// This oracle always "returns" one, so it always phase-flips the target
    /// qubit.
    ///
    /// # Input
    /// ## input
    /// The input register to evaluate.
    ///
    /// ## target
    /// The target qubit to phase-flip.
    operation AlwaysOne (input : Qubit[], target : Qubit) : Unit {
        // All this does is phase-flip the target. The input is useless here.
        Z(target);
    }


    /// # Summary
    /// In this exercise, you are given a register with an unknown number of
    /// qubits, in an unknown state, and a target qubit in the |1> state.
    /// Your goal is to construct an oracle that will flip the phase of the
    /// target qubit if the register bit value contains an odd number of 1's,
    /// and leave the target qubit alone if it contains an even number of 1's.
    ///
    /// For example, if the register was in the state |10101>, you would
    /// phase-flip the target qubit because there was an odd number of |1>
    /// qubits. If the register was in the state |01010>, you would leave the
    /// target qubit alone.
    ///
    /// # Input
    /// ## input
    /// A register of qubits in an unknown state. It could be in an arbitrary
    /// superposition.
    ///
    /// ## target
    /// A target qubit to phase-flip if the oracle's conditions are met. It
    /// will be in the |1> state to start; you must put it in the -|1> state
    /// if the input register bit value contains an odd number of 1's.
    operation E01_PhaseFlipOnOdd1s (input : Qubit[], target : Qubit) : Unit {
        // Note: Oracles aren't allowed to collapse the superposition of the
        // input register, so you aren't allowed to do any qubit measurements.
        // You'll need to use some kind of controlled gate that will give the
        // correct result, no matter what the input is.
        //
        // Hint: If you phase-flip the target qubit twice, it will have the
        // same effect as not flipping it at all. Phase-flipping it three
        // times will have the same effect as only flipping it once, etc.

        // TODO
        for q in input {
          Controlled Z([q], target);
        }

        // mutable i = 0;
        // for q in input {
        //   if M(q) == One {
        //     i += 1;
        //   }
        // }

        // if i % 2 == 1 {
        //     Z(target);
        // }
    }


    /// # Summary
    /// In this exercise, you are given a register with an unknown number of
    /// qubits, in an unknown state, and a target qubit in the |1> state. You
    /// are also given two indices of qubits in the register. Your goal is to
    /// construct an oracle that will phase-flip the target qubit if the two
    /// qubits with the given indices have different parity. That is, if both
    /// qubits have the same bit value, you should leave the target qubit
    /// alone; if the qubits have opposite bit values, you should phase-flip
    /// the target.
    ///
    /// # Input
    /// ## firstIndex
    /// The index in the register of the first qubit to use in the parity
    /// check.
    ///
    /// ## secondIndex
    /// The index in the register of the second qubit to use in the parity
    /// check.
    ///
    /// ## input
    /// A register of qubits in an unknown state. It could be in an arbitrary
    /// superposition.
    ///
    /// ## target
    /// A target qubit to phase-flip if the oracle's conditions are met. It
    /// will be in the |1> state to start; you must put it in the -|1> state
    /// if the two qubits in the register at the given indices have opposite
    /// parity.
    operation E02_PhaseFlipOnOddParity (
        firstIndex : Int,
        secondIndex : Int,
        input : Qubit[],
        target : Qubit
    ) : Unit {
        // TODO
        Controlled Z([input[firstIndex]], target);
        Controlled Z([input[secondIndex]], target);
    }


    /// # Summary
    /// In this exercise, you will implement the Deutsch-Jozsa algorithm. You
    /// are given an oracle, which is an operation that takes in a qubit
    /// register and a target qubit that will be phase-flipped if the
    /// register meets the oracle's condition. The register must be in the
    /// |+...+> state, and the target qubit must be in the |1> state. Your
    /// goal is to prepare the input register and target qubit, run the oracle,
    /// and use the resulting state of the register to determine whether the
    /// oracle represents a constant function or a balanced function.
    ///
    /// # Input
    /// ## inputLength
    /// The number of qubits that the oracle expects the input register to
    /// contain. You must allocate a register with this many qubits to provide
    /// to the oracle.
    ///
    /// ## oracle
    /// A quantum operation that represents some function. It will take in an
    /// input register (that must be in the |+...+> state) and a target qubit
    /// (that must be in the |1> state). It will phase-flip the target qubit
    /// for each term in the register's superposition that meets its criteria,
    /// with the effect of that term being phase-flipped due to phase kickback.
    ///
    /// # Output
    /// You should return true if the function is constant, or false if it is
    /// balanced.
    operation E03_DeutschJozsa (
        inputLength : Int,
        oracle : ((Qubit[], Qubit) => Unit)
    ) : Bool {
        // Tip: you can allocate multiple different things at once using tuple
        // notation. For example:
        //      use (input, target) = (Qubit[inputLength], Qubit())
        // will allocate a qubit register called "input", and a single qubit
        // called "target".
        //
        // Note: Remember to put the input and target in the correct states
        // before running the oracle!

        // TODO
        use (input, target) = (Qubit[inputLength], Qubit());
        Reset(target);
        ResetAll(input);

        X(target);
//        H(target);
        ApplyToEach(H, input);

        // oracle automatically does H(target)
        oracle(input, target);

        ApplyToEach(H, input);

        DumpMachine();

        mutable ans = true;
        for i in 0..Length(input)-1 {
            let result = M(input[i]);
            if result == One {
                Reset(input[i]); // Reset to |0⟩
                ans = false;
            }
        }

        Reset(target);

        Message("TRUE");
        return ans;
    }


    /// # Summary
    /// In this exercise, you are given a register with an unknown number of
    /// qubits, in an unknown state, and a target qubit in the |1> state.
    /// Your goal is to construct an oracle that will flip the phase of the
    /// target qubit if the bitwise (mod-2) dot product of the register value
    /// with the bitstring 's' is 1.
    ///
    /// For example, if s=110 and the register was in the state |101>, you would
    /// phase-flip the target qubit because 110 * 101 = 1 + 0 + 0 (mod 2) = 1.
    /// If the register was in the state |111>, you would leave the target qubit
    /// alone because 110 * 111 = 1 + 1 + 0 (mod 2) = 0.
    ///
    /// # Input
    /// ## s
    /// A Boolean array representing the first argument of the dot product.
    ///
    /// ## input
    /// A register of qubits in an unknown state. It could be in an arbitrary
    /// superposition.
    ///
    /// ## target
    /// A target qubit to phase-flip if the oracle's conditions are met. It
    /// will be in the |1> state to start.
    operation E04_BitwiseDotProduct (
        s : Bool[],
        input : Qubit[],
        target : Qubit
    ) : Unit {
        for i in 0..Length(s)-1 {
            if s[i] {
                Controlled Z([input[i]], target);
            }
        }
    }


    /// # Summary
    /// In this exercise, you will implement the Bernstein-Vazirani algorithm.
    /// You are given an oracle, which is an operation that takes in a qubit
    /// register and a target qubit that will be phase-flipped based on the
    /// bitwise dot product of the register value and the secret bitstring s.
    /// Your goal is to prepare the input register and target qubit, run the
    /// oracle, and use the resulting state of the register to find s.
    ///
    /// # Input
    /// ## inputLength
    /// The number of qubits that the oracle expects the input register to
    /// contain. You must allocate a register with this many qubits to provide
    /// to the oracle.
    ///
    /// ## oracle
    /// A B-V phase-flip oracle with a secret bitstring s. Takes an input
    /// register and target qubit.
    ///
    /// # Output
    /// Return s as Boolean array.
    operation E05_BernsteinVazirani (
        inputLength : Int,
        oracle : ((Qubit[], Qubit) => Unit)
    ) : Bool[] {
        use (input, target) = (Qubit[inputLength], Qubit());
        Reset(target);
        ResetAll(input);

        X(target);
//        H(target);
        ApplyToEach(H, input);

        // oracle automatically does H(target)
        oracle(input, target);

        ApplyToEach(H, input);

        DumpMachine();

        mutable resultArray = [false, size=Length(input)];

        for i in 0..Length(input)-1 {
            let result = M(input[i]);
            if result == One {
                Reset(input[i]); // Reset to |0⟩
                resultArray[i] = true;
            }
        }

        Reset(target);
        return resultArray;
    }
}
