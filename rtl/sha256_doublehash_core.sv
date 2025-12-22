module sha256_doublehash_core (
    input logic clk,
    input logic reset,
    input logic [639:0] blockHeader,
    output logic [31:0] a,
    output logic [31:0] b,
    output logic [31:0] c,
    output logic [31:0] d,
    output logic [31:0] e,
    output logic [31:0] f,
    output logic [31:0] g,
    output logic [31:0] h,
    output reg [255:0] digest
);

  localparam logic [2:0] INITIAL = 3'b000;
  localparam logic [2:0] PROCESSBLOCK_1 = 3'b001;
  localparam logic [2:0] PROCESSBLOCK_2 = 3'b011;
  localparam logic [2:0] SCHEDULEARRAY = 3'b100;
  localparam logic [2:0] MAINLOOP = 3'b101;
  localparam logic [2:0] CHUNKCHOOSE = 3'B111;
  localparam logic [2:0] DONE = 3'b110;

  logic [   2:0] state;

  logic [1023:0] padded_block;
  logic          chunk;
  logic          step;
  logic [ 255:0] first_hash;

  logic [  31:0] hash         [ 0:7];  /* hash values */
  logic [  31:0] k            [0:63];  /* round constants k */
  initial $readmemh("rom/sha256_k.hex", k);

  logic [31:0] w[63:0];  /* message schedule array */
  logic [31:0] s0, s1, S0, S1, ch, maj, temp1, temp2;
  integer j;  /* loop index for reset logic */
  integer i;  /* loop index for other operations */

  always_ff @(posedge clk) begin
    if (reset) begin
      /* initialize hash values */
      $readmemh("rom/sha256_h0.hex", hash);
      chunk <= 0;
      step  <= 0;
      /* reset message schedule array */
      for (j = 0; j < 64; j++) begin
        w[j] <= 32'd0;
      end
      /* set initial state */
      state <= INITIAL;
    end else begin

      case (state)
        INITIAL: begin
          if (!step) begin
            padded_block <= {blockHeader, 1'b1, 319'b0, 64'd640};
          end else begin
            padded_block <= {first_hash, 1'b1, 191'b0, 64'd256};
          end
          a <= hash[0];
          b <= hash[1];
          c <= hash[2];
          d <= hash[3];
          e <= hash[4];
          f <= hash[5];
          g <= hash[6];
          h <= hash[7];

          if (!step) state <= chunk ? PROCESSBLOCK_2 : PROCESSBLOCK_1;
          else state <= PROCESSBLOCK_2;
        end

        PROCESSBLOCK_1: begin
          for (i = 0; i < 16; i++) begin
            w[i] <= padded_block[1023-(i*32)-:32];
          end
          state <= SCHEDULEARRAY;
        end

        PROCESSBLOCK_2: begin
          for (i = 0; i < 16; i++) begin
            w[i] <= padded_block[511-(i*32)-:32];
          end
          state <= SCHEDULEARRAY;
        end

        SCHEDULEARRAY: begin
          i <= 16;
          if (i < 64) begin
            /* compute s0 and s1 for the current i */
            s0 = (w[i-15] >> 7 | w[i-15] << 25) ^ (w[i-15] >> 18 | w[i-15] << 14) ^ (w[i-15] >> 3);
            s1 = (w[i-2] >> 17 | w[i-2] << 15) ^ (w[i-2] >> 19 | w[i-2] << 13) ^ (w[i-2] >> 10);
            /* update w[i] */
            w[i] <= w[i-16] + s0 + w[i-7] + s1;
            /* increment i for the next clock cycle */
            i <= i + 1;
          end else begin
            /* Move to the next state after completing all 64 words */
            state <= MAINLOOP;
          end
        end

        MAINLOOP: begin
          /* compression function main loop */
          for (i = 0; i < 64; i++) begin
            S1 = ({e[5:0], e[31:6]}) ^ ({e[10:0], e[31:11]}) ^ ({e[24:0], e[31:25]});
            ch = (e & f) ^ (~e & g);
            temp1 = h + S1 + ch + k[i] + w[i];
            S0 = ({a[1:0], a[31:2]}) ^ ({a[12:0], a[31:13]}) ^ ({a[21:0], a[31:22]});
            maj = (a & b) ^ (a & c) ^ (b & c);
            temp2 = S0 + maj;

            h = g;
            g = f;
            f = e;
            e = d + temp1;
            d = c;
            c = b;
            b = a;
            a = temp1 + temp2;
          end
          hash[0] <= hash[0] + a;
          hash[1] <= hash[1] + b;
          hash[2] <= hash[2] + c;
          hash[3] <= hash[3] + d;
          hash[4] <= hash[4] + e;
          hash[5] <= hash[5] + f;
          hash[6] <= hash[6] + g;
          hash[7] <= hash[7] + h;

          state   <= CHUNKCHOOSE;
        end

        CHUNKCHOOSE: begin
          if (!chunk) begin
            chunk <= 1;  /* move to next chunk */
          end else if (!step) begin
            first_hash <= {hash[0], hash[1], hash[2], hash[3], hash[4], hash[5], hash[6], hash[7]};
            step <= 1;  /* move to second step */
            $readmemh("rom/sha256_h0.hex", hash);
          end
          state <= step ? DONE : INITIAL;
        end

        DONE: begin
          digest <= {hash[0], hash[1], hash[2], hash[3], hash[4], hash[5], hash[6], hash[7]};
          state  <= reset ? INITIAL : DONE;
        end
        default: state <= INITIAL;
      endcase
    end
  end

endmodule
