module experiment #(parameter int N = 32)(
input logic [N-1:0] a,b,
output logic y
);
generate

	always_comb begin
	// Not combinational loop
		logic test;
		test = a[0];
	// Combinational loop
	//	logic test = 1'b0;

		for (int i = 0; i < N; i++) begin
		test &= a[i];
//		y &= a[i];
		end
		test &= b[0];
		y = test;
//		y &= b[0];
	end
endgenerate
endmodule