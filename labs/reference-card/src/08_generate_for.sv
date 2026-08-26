// 08_generate_for.sv — `generate for` writes the four instances for you.
//
// Nothing loops in silicon. The loop runs once, while the tool is reading your
// file, and leaves four full adders behind. `genvar` is the loop counter,
// `begin : slice` gives the copies names — slice[0], slice[1], and so on.
//   iverilog -g2012 -o 08.vvp src/08_generate_for.sv && vvp 08.vvp
module full_adder (
    input  logic a, b, cin,
    output logic sum, cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule

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
        for (i = 0; i < 4; i = i + 1) begin : slice
            full_adder fa (.a(a[i]), .b(b[i]), .cin(c[i]),
                           .sum(sum[i]), .cout(c[i+1]));
        end
    endgenerate

    assign cout = c[4];
endmodule

module card08;
    logic [3:0] a, b, sum;
    logic cin, cout;
    ripple4 dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));
    initial begin
        a = 4'd9; b = 4'd9; cin = 1'b0; #1;
        $display("08_generate_for: 9+9+0 -> cout=%b sum=%0d (= %0d)", cout, sum, {cout, sum});
    end
endmodule
