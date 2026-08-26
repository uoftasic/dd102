// 09_parameter.sv — `parameter` lets one file be every width.
//
// The default is used when you instantiate the module plainly. `#(.N(8))`
// overrides it for that one copy. The file does not get any longer.
//   iverilog -g2012 -o 09.vvp src/09_parameter.sv && vvp 09.vvp
module zero_extend #(
    parameter int N = 4
) (
    input  logic [N-1:0] a,
    output logic [7:0]   wide
);
    assign wide = {{(8-N){1'b0}}, a};
endmodule

module card09;
    logic [3:0] a4;
    logic [5:0] a6;
    logic [7:0] w4, w6;
    zero_extend           u_default (.a(a4), .wide(w4));   // N takes its default, 4
    zero_extend #(.N(6))  u_six     (.a(a6), .wide(w6));   // this copy is 6 bits wide
    initial begin
        a4 = 4'b1111; a6 = 6'b111111; #1;
        $display("09_parameter: N=4 -> %b   N=6 -> %b", w4, w6);
    end
endmodule
