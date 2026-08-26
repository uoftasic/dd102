// tb_six_cases.sv — the testbench a reasonable person writes in five minutes.
//
// Six cases, chosen by hand, each one a case that obviously matters. This is
// not a straw man: it is what almost everybody writes first, including people
// who have been paid to do this for years.

`timescale 1ns/1ps

module tb_six_cases;

    logic [3:0] a, b;
    logic       cin;
    logic [3:0] sum;
    logic       cout;
    logic [4:0] expected;       // five bits, so the expectation never overflows

    int checked = 0;
    int errors  = 0;

    ripple4 dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    task try_one(input logic [3:0] ia, input logic [3:0] ib, input logic icin,
                 input string why);
        a        = ia;
        b        = ib;
        cin      = icin;
        expected = ia + ib + icin;
        #10;
        checked = checked + 1;
        if ({cout, sum} !== expected) begin
            errors = errors + 1;
            $display("  MISMATCH  %0d + %0d + %0d : ripple4 said %0d, the answer is %0d   (%0s)",
                     ia, ib, icin, {cout, sum}, expected, why);
        end else begin
            $display("  ok        %0d + %0d + %0d = %0d   (%0s)",
                     ia, ib, icin, expected, why);
        end
        #10;
    endtask

    initial begin
        $dumpfile("six.vcd");
        $dumpvars(0, tb_six_cases);

        $display("tb_six_cases: six cases somebody thought were representative");

        //      a          b        cin
        try_one(4'd0,  4'd0,  1'b0, "zero");
        try_one(4'd1,  4'd0,  1'b0, "smallest");
        try_one(4'd2,  4'd3,  1'b0, "no carries at all");
        try_one(4'd7,  4'd1,  1'b0, "carry ripples all the way");
        try_one(4'd15, 4'd1,  1'b0, "overflow into cout");
        try_one(4'd15, 4'd15, 1'b0, "biggest inputs");

        $display("TESTED %0d", checked);
        $display("ERRORS %0d", errors);
        if (errors == 0) $display("VERDICT PASS");
        else             $display("VERDICT FAIL");
        $finish;
    end
endmodule
