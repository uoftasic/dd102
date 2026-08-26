// reference/tb_full_adder.sv  --  one complete answer to Lab 02.
//
// Do not open this before you have run `make` at least twice: once as shipped
// (one row, zero mutants caught) and once with your own eight rows in.
//
// `make reference` runs this file through the same three mutants your file
// goes through, so a PASS here proves the harness works even when yours does
// not. There is nothing clever in it. That is the point.

`timescale 1ns/1ps

module tb_full_adder;

    logic a, b, cin;
    logic sum, cout;

    int checked = 0;
    int errors  = 0;

    full_adder dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    task check(input logic ia, input logic ib, input logic icin,
               input logic want_cout, input logic want_sum);
        a   = ia;
        b   = ib;
        cin = icin;
        #1;
        checked = checked + 1;
        if (sum !== want_sum || cout !== want_cout) begin
            errors = errors + 1;
            $display("  MISMATCH  a=%b b=%b cin=%b : got cout=%b sum=%b, want cout=%b sum=%b",
                     ia, ib, icin, cout, sum, want_cout, want_sum);
        end
    endtask

    initial begin
        $display("tb_full_adder: checking module full_adder");

        //    a  b  cin   cout  sum
        check(0, 0,  0,    0,    0);
        check(0, 0,  1,    0,    1);
        check(0, 1,  0,    0,    1);
        check(0, 1,  1,    1,    0);
        check(1, 0,  0,    0,    1);
        check(1, 0,  1,    1,    0);
        check(1, 1,  0,    1,    0);
        check(1, 1,  1,    1,    1);

        $display("TESTED %0d", checked);
        $display("ERRORS %0d", errors);
        if (errors == 0) $display("VERDICT PASS");
        else             $display("VERDICT FAIL");
        $finish;
    end

endmodule
