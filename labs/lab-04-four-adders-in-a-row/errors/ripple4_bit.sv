// errors/ripple4_bit.sv — src/ripple4.sv with ONE word changed: the generate
// block is labelled `bit` instead of `slice`.
//
// `bit` is a SystemVerilog data type. You cannot use it as a name. This file
// does not compile in Yosys and CRASHES Icarus. That is on purpose --
// `make gotcha` runs it so you can see both failures before you cause one.
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
        for (i = 0; i < 4; i = i + 1) begin : bit
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
