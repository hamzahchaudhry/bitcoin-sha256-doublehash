module miner_top (
    input logic clk,
    input logic reset,
    input logic start,
    input logic [607:0] blockHeader_noNonce,
    input logic [255:0] target,
    output logic [255:0] digest,
    output logic [31:0] golden_nonce,
    output logic finish
);

  logic [255:0] IV;
  assign IV = {
    32'h6a09e667,
    32'hbb67ae85,
    32'h3c6ef372,
    32'ha54ff53a,
    32'h510e527f,
    32'h9b05688c,
    32'h1f83d9ab,
    32'h5be0cd19
  };

  logic start_core, finish_core;
  logic [511:0] chunk_core;
  logic [255:0] state_in_core, state_out_core;
  sha256_compress core (
      .clk(clk),
      .reset(reset),
      .start(start_core),
      .chunk(chunk_core),
      .state_in(state_in_core),
      .state_out(state_out_core),
      .finish(finish_core)
  );

  logic [511:0] chunk0, chunk1_template, chunk2_from_H1;
  logic [255:0] midstate, H1;
  logic [31:0] nonce;
  assign chunk0 = blockHeader_noNonce[607:96];
  assign chunk1_template = {blockHeader_noNonce[95:0], nonce, 1'b1, 319'b0, 64'd640};
  assign chunk2_from_H1 = {H1, 1'b1, 191'b0, 64'd256};

  localparam logic [4:0] IDLE = 5'b0_0000;
  localparam logic [4:0] MIDSTATE_START = 5'b0_0001;
  localparam logic [4:0] MIDSTATE_WAIT = 5'b0_0010;
  localparam logic [4:0] H1_START = 5'b0_0011;
  localparam logic [4:0] H1_WAIT = 5'b0_0100;
  localparam logic [4:0] H2_START = 5'b0_0101;
  localparam logic [4:0] H2_WAIT = 5'b0_0111;
  localparam logic [4:0] CHECK = 5'b0_1000;
  localparam logic [4:0] INCR_NONCE = 5'b0_1001;
  localparam logic [4:0] FINISH = 5'b1_1010;

  logic [4:0] state;

  assign finish = state[4];

  always_ff @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
      nonce <= 32'd0;
      start_core <= 1'b0;
      chunk_core <= 512'd0;
      state_in_core <= 256'd0;
      midstate <= 256'd0;
      H1 <= 256'd0;
      digest <= 256'd0;
      golden_nonce <= 32'd0;
    end else begin
      start_core <= 1'b0;
      case (state)
        IDLE: begin
          golden_nonce <= 32'd0;
          state <= start ? MIDSTATE_START : IDLE;
        end
        MIDSTATE_START: begin
          start_core <= 1'd1;
          chunk_core <= chunk0;
          state_in_core <= IV;
          state <= MIDSTATE_WAIT;
        end
        MIDSTATE_WAIT: begin
          start_core <= 1'd0;
          if (finish_core) begin
            midstate <= state_out_core;
            state <= H1_START;
          end
        end
        H1_START: begin
          start_core <= 1'd1;
          chunk_core <= chunk1_template;
          state_in_core <= midstate;
          state <= H1_WAIT;
        end
        H1_WAIT: begin
          start_core <= 1'd0;
          if (finish_core) begin
            H1 <= state_out_core;
            state <= H2_START;
          end
        end
        H2_START: begin
          start_core <= 1'd1;
          chunk_core <= chunk2_from_H1;
          state_in_core <= IV;
          state <= H2_WAIT;
        end
        H2_WAIT: begin
          if (finish_core) begin
            digest <= state_out_core;
            state  <= CHECK;
          end
        end
        CHECK: begin
          if (digest <= target) begin
            golden_nonce <= nonce;
            state <= FINISH;
          end else state <= INCR_NONCE;
        end
        INCR_NONCE: begin
          nonce <= nonce + 32'd1;
          state <= H1_START;
        end
        FINISH: begin
          state <= IDLE;
        end
        default: state <= IDLE;
      endcase
    end
  end

endmodule
