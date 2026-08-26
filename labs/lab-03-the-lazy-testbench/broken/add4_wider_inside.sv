// broken/add4_wider_inside.sv  --  the fix that is not a fix.
//
// This is what most people try first: "the answer needs five bits, so make it
// five bits." The internal wire is five bits wide. The port it drives is still
// four. SystemVerilog quietly throws the top bit away at the assignment, and
// the module behaves exactly like src/add4.sv -- wrong on the same 256 inputs.
//
// A complete, compilable, wrong file. `make trap` runs it.

module add4 (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic       cin,
    output logic [3:0] sum
);

    logic [4:0] wide;           // five bits, so nothing is lost HERE

    assign wide = a + b + cin;
    assign sum  = wide;         // ...and lost here instead, in silence

endmodule
