module game(
    input clk,
    input rst,
    input [15:0] sw,
    input [1:0] player1,
    input [1:0] player2
    input start,
    input set,
    output [1:0] win;
)

    parameter INITIAL = 3'b000;
    parameter WAITING = 3'b001;
    parameter GAMING = 3'b010;
    parameter SETTLEMENT = 3'b011;
    parameter SETTING = 3'b100;

    reg [2:0] state = INITIAL, next_state;
    reg turn, next_turn;

    wire start_db, start_1pulse;
    wire set_db, set_1pulse;
    wire clk16;

    clock_divider #(16) clkdiv1 (.clk(clk), .clk_div(clk16));

    debounce db_1 (.pd_debound(start_db), .pd(start), .clk(clk16));
    onepulse onepulse_1 (.rst(rst), .clk(clk16), .pb_debounced(start_db), .pb_1pulse(start_1pulse));
    debounce db_2 (.pd_debound(set_db), .pd(set), .clk(clk16));
    onepulse onepulse_2 (.rst(rst), .clk(clk16), .pb_debounced(set_db), .pb_1pulse(set_1pulse));


    always@(posedge clk, posedge rst)begin
        if(rst)begin
            state <= INITIAL;
        end else begin
            state <= next_state;
            turn <= next_turn;
        end
    end

    always@(posedge clk)begin
        if(rst)begin
            next_state = INITIAL;
        end else begin
            case(state)
                INITIAL:begin
                    next_state = WAITING;
                end
                WAITING:begin // 遊戲準備畫面， 按下set -> 進入setting ， 按下 start -> 進入遊戲
                    if(start_1pulse)begin
                        next_state = GAMING;
                    end
                    if(set_1pulse)begin
                        next_state = SETTING;
                    end
                end
                SETTING:begin // 設定畫面， (1)調整音量 (2)調整模式(PVP or PVE) (3) 調整遊戲速度
                    if(set_1pulse)begin
                        next_state = WAITING;
                        next_turn = 0;
                    end
                end
                GAMING:begin // 遊戲過程， player1先攻
                    if(player1 == player2)begin
                        next_state = SETTLEMENT;
                    end else begin
                        next_turn = ~turn;
                    end
                end
                SETTLEMENT:begin
                    if(turn == 0)begin
                        //player1 win
                    end else if(turn == 1)begin
                        //player2 win
                    end
                    if(start_1pulse)begin
                        next_state = WAITING;
                    end
                end 
        end
    end
endmodule

module clock_divider #(parameter n = 25)(clk, clk_div);
    input clk;
    output clk_div;

    reg [n-1:0] num = 0;
    wire [n-1:0] next_num; 
    always @(posedge clk) begin
        num = next_num;
    end
    assign next_num = num +1;
    assign clk_div = num[n-1];

endmodule

module debounce(pd_debound, pd, clk);
    output pd_debound;
    input pd;
    input clk;
    reg [3:0] shift_reg;
    always @(posedge clk) begin
        shift_reg[3:1] <= shift_reg[2:0];
        shift_reg[0] <= pd;
    end
    assign pd_debound = ((shift_reg == 4'b1111) ? 1'b1 : 1'b0);
endmodule

module onepulse (
    input wire rst,
    input wire clk,
    input wire pb_debounced,
    output reg pb_1pulse
);
    reg pb_1pulse_next;
    reg pb_debounced_delay;
    always @* begin
        pb_1pulse_next = pb_debounced & ~pb_debounced_delay;
    end
    always @(posedge clk, posedge rst)begin
        if (rst == 1'b1) begin
            pb_1pulse <= 1'b0;
            pb_debounced_delay <= 1'b0;
        end else begin
            pb_1pulse <= pb_1pulse_next;
            pb_debounced_delay <= pb_debounced;
        end
    end
endmodule