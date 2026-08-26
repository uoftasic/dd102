// src/full_adder.sv  --  THIS IS THE FILE YOU WRITE.
//
// The ports are already here, because the ports are not the interesting part:
// they are the five labels that are already on your DD101 paper drawing, in
// the same order. What is missing is the middle.
//
// Nothing in this file is an excerpt. It compiles exactly as shipped -- it just
// does not drive anything yet, which is why `make` prints x for every output
// until you write the assign lines.

module full_adder (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);

    // Your drawing has three wires inside it that never touch the edge of the
    // box: the two leaving the first half adder, and the carry leaving the
    // second. You cannot write down a wire you have not named, so name them,
    // and then write one assign per wire.
    //
    // logic ha1_sum, ha1_carry, ha2_carry;
    //
    // assign ha1_sum   = ... ;    // first half adder, sum
    // assign ha1_carry = ... ;    // first half adder, carry
    // assign sum       = ... ;    // second half adder, sum
    // assign ha2_carry = ... ;    // second half adder, carry
    // assign cout      = ... ;    // the Or gate
    //
    // If you would rather write two lines straight off the truth table -- one
    // for sum, one for cout -- that passes too. The grader checks the eight
    // rows, not the shape. A truth table does not have *a* circuit; you proved
    // that to yourself in DD101 with Combinational Analysis.

endmodule
