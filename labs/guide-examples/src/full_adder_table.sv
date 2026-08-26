// full_adder_table.sv — your DD101 truth table, one line per row.
// Nothing here mentions a gate. It is the eight rows and nothing else.
module full_adder_table (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);
    always_comb begin
        case ({a, b, cin})
            3'b000:  {cout, sum} = 2'b00;
            3'b001:  {cout, sum} = 2'b01;
            3'b010:  {cout, sum} = 2'b01;
            3'b011:  {cout, sum} = 2'b10;
            3'b100:  {cout, sum} = 2'b01;
            3'b101:  {cout, sum} = 2'b10;
            3'b110:  {cout, sum} = 2'b10;
            3'b111:  {cout, sum} = 2'b11;
            default: {cout, sum} = 2'b00;
        endcase
    end
endmodule
