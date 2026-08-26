// mutants/mut2_carry_needs_all_three.sv  --  a full adder with one thing wrong.
//
// sum is right. cout only fires when ALL THREE inputs are 1, instead of when
// at least two are. This is the single most common way to misread a majority
// gate, and it is invisible on the rows where fewer than two inputs are high.

module full_adder (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);

    assign sum  = a ^ b ^ cin;
    assign cout = a & b & cin;                        // <-- & where | belongs

endmodule
