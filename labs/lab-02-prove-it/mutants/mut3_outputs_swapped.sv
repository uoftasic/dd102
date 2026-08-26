// mutants/mut3_outputs_swapped.sv  --  a full adder with one thing wrong.
//
// Both expressions are correct. They are connected to the wrong ports. This is
// what a typo in a port list looks like, and it is the reason the DD101
// worksheet made you write the column headings down as "cout sum".

module full_adder (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);

    assign sum  = (a & b) | (b & cin) | (a & cin);    // <-- these two
    assign cout = a ^ b ^ cin;                        // <-- are the wrong way round

endmodule
