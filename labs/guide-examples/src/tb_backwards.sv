// tb_backwards.sv — the same eight rows, aimed at full_adder_backwards.
`timescale 1ns/1ps
module tb_backwards;
    logic a, b, cin, sum, cout;
    full_adder_backwards dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));
    int errors = 0;
    task check(input logic ia, ib, ic, exp_cout, exp_sum);
        begin
            a = ia; b = ib; cin = ic;
            #1;
            if (sum !== exp_sum || cout !== exp_cout) errors = errors + 1;
        end
    endtask
    initial begin
        check(0,0,0, 0,0); check(0,0,1, 0,1); check(0,1,0, 0,1); check(0,1,1, 1,0);
        check(1,0,0, 0,1); check(1,0,1, 1,0); check(1,1,0, 1,0); check(1,1,1, 1,1);
        $display("");
        if (errors == 0)
            $display("PASS - the lines in reverse order, all 8 rows still match.");
        else
            $display("FAIL - %0d of 8 rows disagree.", errors);
        $display("");
        $finish;
    end
endmodule
