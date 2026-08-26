// top12.sv — a 12-bit ripple adder with every bit brought out to a physical pin.
//
// This wrapper exists because src/ripple.sv is parameterised, and nextpnr needs a
// top module whose ports are fixed. `ripple #(.N(12))` is the whole design; this
// file only gives it a name and a width so the place-and-route tool has something
// to place.

module top (
    input  logic [11:0] a,
    input  logic [11:0] b,
    input  logic       cin,
    output logic [11:0] sum,
    output logic       cout
);

    ripple #(.N(12)) u (
        .a    (a),
        .b    (b),
        .cin  (cin),
        .sum  (sum),
        .cout (cout)
    );

endmodule
