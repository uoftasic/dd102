// tb_spellings.sv — four spellings of one adder, driven by the same eight rows.
// Every column should read the same thing on every row.
`timescale 1ns/1ps
module tb_spellings;

    logic a, b, cin;
    logic s1, c1, s2, c2, s3, c3, s4, c4;

    full_adder       d1 (.a(a), .b(b), .cin(cin), .sum(s1), .cout(c1));
    full_adder_flat  d2 (.a(a), .b(b), .cin(cin), .sum(s2), .cout(c2));
    full_adder_table d3 (.a(a), .b(b), .cin(cin), .sum(s3), .cout(c3));
    full_adder_hier  d4 (.a(a), .b(b), .cin(cin), .sum(s4), .cout(c4));

    int errors = 0;

    task row(input logic ia, ib, ic);
        begin
            a = ia; b = ib; cin = ic;
            #1;
            $display("  %b %b  %b  |   %b%b     %b%b     %b%b     %b%b",
                     a, b, cin, c1, s1, c2, s2, c3, s3, c4, s4);
            if ({c1,s1} !== {c2,s2} || {c1,s1} !== {c3,s3} || {c1,s1} !== {c4,s4})
                errors = errors + 1;
        end
    endtask

    initial begin
        $display("");
        $display("  every column below is cout then sum, on the same eight rows");
        $display("");
        $display("           drawing  flat  table  boxes");
        $display("  a b cin |   cs     cs     cs     cs");
        $display("  --------+---------------------------");
        row(0,0,0); row(0,0,1); row(0,1,0); row(0,1,1);
        row(1,0,0); row(1,0,1); row(1,1,0); row(1,1,1);
        $display("");
        if (errors == 0)
            $display("PASS - four spellings, eight rows, zero disagreements.");
        else
            $display("FAIL - %0d rows where the spellings disagree.", errors);
        $display("");
        $finish;
    end
endmodule
