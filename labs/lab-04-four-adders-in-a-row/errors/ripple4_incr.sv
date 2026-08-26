// errors/ripple4_incr.sv — src/ripple4.sv with `i = i + 1` written as `i++`.
//
// This file is in errors/ because people will tell you it belongs there.
// It does not. On this workbench it compiles and synthesises to exactly the
// same 8 SB_LUT4 as src/ripple4.sv, and `make gotcha` proves it.
module ripple4 (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic       cin,
    output logic [3:0] sum,
    output logic       cout
);
    logic [4:0] c;
    assign c[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : slice
            full_adder fa (
                .a    (a[i]),
                .b    (b[i]),
                .cin  (c[i]),
                .sum  (sum[i]),
                .cout (c[i+1])
            );
        end
    endgenerate

    assign cout = c[4];
endmodule
