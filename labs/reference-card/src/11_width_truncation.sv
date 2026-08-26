// 11_width_truncation.sv — the trap. Widths are decided by the LEFT side.
//
// Adding two 4-bit numbers can need five bits. If the destination is four bits
// wide, the fifth is thrown away, silently, with no error and no warning.
// This file demonstrates the loss and then shows the one-line fix.
//   iverilog -g2012 -o 11.vvp src/11_width_truncation.sv && vvp 11.vvp
module adders (
    input  logic [3:0] a,
    input  logic [3:0] b,
    output logic [3:0] narrow,     // four bits. The carry has nowhere to go.
    output logic [4:0] wide        // five bits. The carry has a seat.
);
    assign narrow = a + b;
    assign wide   = a + b;
endmodule

module card11;
    logic [3:0] a, b, narrow;
    logic [4:0] wide;
    adders dut (.a(a), .b(b), .narrow(narrow), .wide(wide));
    initial begin
        a = 4'd9; b = 4'd9; #1;
        $display("11_width_truncation: 9+9 -> narrow[3:0]=%0d  wide[4:0]=%0d", narrow, wide);
    end
endmodule
