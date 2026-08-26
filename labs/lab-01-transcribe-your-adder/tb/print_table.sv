// tb/print_table.sv  --  a table PRINTER. It is not a testbench.
//
// This file walks {a, b, cin} through 0, 1, 2, ... 7 and prints what came out.
// It has no idea what the right answer is and it will never tell you that you
// are wrong. The judging is done afterwards, in Python, by src/check_table.py.
//
// You do not write anything like this in Lab 01. In Lab 02 you write the real
// thing -- a testbench that knows the answers and says so itself.
//
// This file is complete and it runs as shipped. Nothing here is an excerpt.

`timescale 1ns/1ps

module print_table;

    logic a, b, cin;
    logic sum, cout;

    full_adder dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    integer i;

    initial begin
        $display("a b cin | cout sum");
        for (i = 0; i < 8; i = i + 1) begin
            {a, b, cin} = i[2:0];
            #1;
            $display("%b %b  %b  |  %b    %b", a, b, cin, cout, sum);
        end
        $finish;
    end

endmodule
