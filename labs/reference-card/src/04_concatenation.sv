// 04_concatenation.sv — `{ }` glues bits into a wider bus.
//
// This is how a testbench compares a 1-bit carry and a 1-bit sum against one
// 2-bit answer, and how a 4-bit adder's five output bits become one number.
//   iverilog -g2012 -o 04.vvp src/04_concatenation.sv && vvp 04.vvp
module joiner (
    input  logic       cout,
    input  logic [3:0] sum,
    output logic [4:0] total
);
    assign total = {cout, sum};      // cout is the top bit, sum is the low four
endmodule

module card04;
    logic cout;
    logic [3:0] sum;
    logic [4:0] total;
    joiner dut (.cout(cout), .sum(sum), .total(total));
    initial begin
        cout = 1'b1; sum = 4'd2; #1;
        $display("04_concatenation: {cout=%b, sum=%0d} = %b = %0d", cout, sum, total, total);
    end
endmodule
