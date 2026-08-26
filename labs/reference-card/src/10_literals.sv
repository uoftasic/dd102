// 10_literals.sv — how to write a number, and what it is worth.
//
// The shape is  <width>'<base><digits>.  Bases: b binary, d decimal, h hex,
// o octal. Underscores are free and are only for your eyes.
//   iverilog -g2012 -o 10.vvp src/10_literals.sv && vvp 10.vvp
module card10;
    logic [3:0]  four;
    logic [7:0]  eight;
    logic [31:0] wide;
    initial begin
        four = 4'b1010;  $write("10_literals: 4'b1010=%0d", four);
        four = 4'd10;    $write("  4'd10=%b", four);
        four = 4'hA;     $write("  4'hA=%b", four);
        four = 4'o12;    $write("  4'o12=%b", four);
        eight = 8'b1010_1010; $write("  8'b1010_1010=%0d", eight);
        eight = '0;      $write("  '0=%b", eight);
        eight = '1;      $write("  '1=%b", eight);
        wide  = 10;      $display("  bare 10 is %0d bits wide, value %0d", $bits(wide), wide);
    end
endmodule
