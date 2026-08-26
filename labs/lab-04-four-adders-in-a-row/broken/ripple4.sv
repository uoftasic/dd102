// broken/ripple4.sv — ONE character different from src/ripple4.sv.
// Do not fix it. Lab 04 asks you to read the FAIL it produces.
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
        for (i = 0; i < 3; i = i + 1) begin : slice
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
