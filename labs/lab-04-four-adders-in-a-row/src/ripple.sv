// ripple.sv — the same adder with its width left as a parameter.
// ripple #(.N(4)) is exactly src/ripple4.sv. ripple #(.N(64)) is 64 bits and
// the file does not get any longer.
module ripple #(
    parameter int N = 4
) (
    input  logic [N-1:0] a,
    input  logic [N-1:0] b,
    input  logic         cin,
    output logic [N-1:0] sum,
    output logic         cout
);
    logic [N:0] c;
    assign c[0] = cin;

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : slice
            full_adder fa (
                .a    (a[i]),
                .b    (b[i]),
                .cin  (c[i]),
                .sum  (sum[i]),
                .cout (c[i+1])
            );
        end
    endgenerate

    assign cout = c[N];
endmodule
