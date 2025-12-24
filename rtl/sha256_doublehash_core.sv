module sha256_doublehash_core (
    input logic clk,
    input logic reset,
    input logic start,
    input logic [639:0] blockHeader,
    output logic [255:0] digest,
    output logic finish
);

  logic [1023:0] chunk;
  logic [511:0] chunk_second;
  logic [255:0] state_in_core_1;
  logic [255:0] state_out_core_1;
  logic [255:0] state_out_core_2;
  logic finish_core_1;
  logic finish_core_2;
  assign state_in_core_1 = {
    32'h6a09e667,
    32'hbb67ae85,
    32'h3c6ef372,
    32'ha54ff53a,
    32'h510e527f,
    32'h9b05688c,
    32'h1f83d9ab,
    32'h5be0cd19
  };
  assign chunk = {blockHeader, 1'b1, 319'b0, 64'd640};
  assign chunk_second = {state_out_core_2, 1'b1, 191'b0, 64'd256};

  /* first hash */
  sha256_compress core_1 (
      .clk(clk),
      .reset(reset),
      .start(start),
      .chunk(chunk[1023:512]),
      .state_in(state_in_core_1),
      .state_out(state_out_core_1),
      .finish(finish_core_1)
  );

  sha256_compress core_2 (
      .clk(clk),
      .reset(reset),
      .start(finish_core_1),
      .chunk(chunk[511:0]),
      .state_in(state_out_core_1),
      .state_out(state_out_core_2),
      .finish(finish_core_2)
  );

  /* second hash */
  sha256_compress core_3 (
      .clk(clk),
      .reset(reset),
      .start(finish_core_2),
      .chunk(chunk_second),
      .state_in(state_in_core_1),
      .state_out(digest),
      .finish(finish)
  );

endmodule
