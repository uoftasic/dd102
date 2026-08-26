// tb_full_adder.sv — the eight rows of your DD101 truth table, as a test.
// You did not write this file. Read it anyway; it is short on purpose.
`timescale 1ns/1ps
module tb_full_adder;

    logic a, b, cin;        // what the testbench drives
    logic sum, cout;        // what it watches

    // One instance of your module. `.a(a)` means "my wire a to your port a".
    full_adder dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    int errors = 0;

    task check(input logic ia, ib, ic, exp_cout, exp_sum);
        begin
            a = ia; b = ib; cin = ic;
            #1;                     // let the gates settle for 1 ns
            if (sum === exp_sum && cout === exp_cout)
                $display("  %b %b  %b  |   %b   %b   ok", a, b, cin, cout, sum);
            else begin
                $display("  %b %b  %b  |   %b   %b   WRONG - expected cout=%b sum=%b",
                         a, b, cin, cout, sum, exp_cout, exp_sum);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $display("");
        $display("  a b cin | cout sum");
        $display("  --------+---------");
        check(0,0,0, 0,0);
        check(0,0,1, 0,1);
        check(0,1,0, 0,1);
        check(0,1,1, 1,0);
        check(1,0,0, 0,1);
        check(1,0,1, 1,0);
        check(1,1,0, 1,0);
        check(1,1,1, 1,1);
        $display("");
        if (errors == 0)
            $display("PASS - all 8 rows match your DD101 table.");
        else
            $display("FAIL - %0d of 8 rows disagree.", errors);
        $display("");
        $finish;
    end
endmodule
