////////////////////////////////////////////////////////////////////////////////
// THIS FILE WAS AUTOMATICALLY GENERATED FROM controller.v.mako
// DO NOT EDIT
////////////////////////////////////////////////////////////////////////////////



module controller( 

    input clk,
    input reset_npu,
    input done_mvm,
    input done_mfu_0,
    input done_mfu_1,
    
    
    input[`INSTR_WIDTH-1:0] instruction,
    output reg get_instr,
    output reg[`INSTR_MEM_AWIDTH-1:0] get_instr_addr,
    
    input[`DRAM_DWIDTH-1:0] input_data_from_dram,
    input[`ORF_DWIDTH-1:0] output_final_stage, 
    output reg[`DRAM_AWIDTH-1:0] dram_addr_wr,
    output reg dram_write_enable,
    output reg [`DRAM_DWIDTH-1:0] output_data_to_dram,

    //output reg start_mvu,
    output reg start_mv_mul,
    output reg start_mfu_0,
    output reg start_mfu_1,
    //output reg reset_mvu,
    output reg in_data_available_mfu_0,
    output reg in_data_available_mfu_1,
    
    output reg[1:0] activation,
    output reg[1:0] operation,

    //FOR MVU IO

    input[`VRF_DWIDTH-1:0] vrf_out_data_mvu_0,
    output reg vrf_readn_enable_mvu_0,
    output reg vrf_wr_enable_mvu_0,


    input[`VRF_DWIDTH-1:0] vrf_out_data_mvu_1,
    output reg vrf_readn_enable_mvu_1,
    output reg vrf_wr_enable_mvu_1,


    input[`VRF_DWIDTH-1:0] vrf_out_data_mvu_2,
    output reg vrf_readn_enable_mvu_2,
    output reg vrf_wr_enable_mvu_2,


    input[`VRF_DWIDTH-1:0] vrf_out_data_mvu_3,
    output reg vrf_readn_enable_mvu_3,
    output reg vrf_wr_enable_mvu_3,

    
    output reg[`VRF_AWIDTH-1:0] vrf_addr_read,
    output reg[`VRF_AWIDTH-1:0] vrf_addr_wr, //*********************

    //FOR MFU STAGE -0
    input[`ORF_DWIDTH-1:0] vrf_out_data_mfu_add_0,
    output reg vrf_readn_enable_mfu_add_0,
    output reg vrf_wr_enable_mfu_add_0,
    output reg[`ORF_AWIDTH-1:0] vrf_addr_read_mfu_add_0,
    output reg[`ORF_AWIDTH-1:0] vrf_addr_wr_mfu_add_0,
    
    input[`ORF_DWIDTH-1:0] vrf_out_data_mfu_mul_0,
    output reg vrf_readn_enable_mfu_mul_0,
    output reg vrf_wr_enable_mfu_mul_0,
    output reg[`ORF_AWIDTH-1:0] vrf_addr_read_mfu_mul_0,
    output reg[`ORF_AWIDTH-1:0] vrf_addr_wr_mfu_mul_0,
    //
    
    //FOR MFU STAGE -1 
    input[`ORF_DWIDTH-1:0] vrf_out_data_mfu_add_1,
    output reg vrf_readn_enable_mfu_add_1,
    output reg vrf_wr_enable_mfu_add_1,
    output reg[`ORF_AWIDTH-1:0] vrf_addr_read_mfu_add_1,
    output reg[`ORF_AWIDTH-1:0] vrf_addr_wr_mfu_add_1,
    
    input[`ORF_DWIDTH-1:0] vrf_out_data_mfu_mul_1,
    output reg vrf_readn_enable_mfu_mul_1,
    output reg vrf_wr_enable_mfu_mul_1,
    output reg[`ORF_AWIDTH-1:0] vrf_addr_read_mfu_mul_1,
    output reg[`ORF_AWIDTH-1:0] vrf_addr_wr_mfu_mul_1,
    
    //VRF MUXED 
    input[`ORF_DWIDTH-1:0] vrf_muxed_out_data_dram,
    output reg[`ORF_AWIDTH-1:0] vrf_muxed_wr_addr_dram,
    output reg[`ORF_AWIDTH-1:0] vrf_muxed_read_addr,
    output reg vrf_muxed_wr_enable_dram,
    output reg vrf_muxed_readn_enable,
    //

    output reg[`MAX_VRF_DWIDTH-1:0] vrf_in_data,
    
    output mvu_or_vrf_mux_select,

    //MRF IO PORTS
    output reg[`MRF_AWIDTH*`NUM_LDPES*`NUM_TILES-1:0] mrf_addr_wr,
    output reg[`NUM_LDPES*`NUM_TILES-1:0] mrf_wr_enable, //NOTE: LOG(NUM_LDPES) = TARGET_OP_WIDTH
    output reg[`MRF_DWIDTH-1:0] mrf_in_data,
    //
    
   // output reg orf_addr_increment,
    
    //BYPASS SIGNALS
    output[`TARGET_OP_WIDTH-1:0] dstn_id
);

    wire[`OPCODE_WIDTH-1:0] opcode;
    wire[`VRF_AWIDTH-1:0] op1_address;
    wire[`VRF_AWIDTH-1:0] op2_address;
    wire[`VRF_AWIDTH-1:0] dstn_address;
    wire[`TARGET_OP_WIDTH-1:0] src1_id;
    //wire[`TARGET_OP_WIDTH-1:0] dstn_id;
    
    reg[1:0] state;
    
    //NOTE - CORRECT NAMING FOR OPERANDS AND EXTRACTION SCHEME FOR YOUR PARTS OF INSTRUCTION
    assign op1_address = instruction[3*`VRF_AWIDTH+(`TARGET_OP_WIDTH)-1:(2*`VRF_AWIDTH) +(`TARGET_OP_WIDTH)];
    assign op2_address = instruction[2*`VRF_AWIDTH+`TARGET_OP_WIDTH-1:`VRF_AWIDTH+`TARGET_OP_WIDTH];
    assign dstn_address = instruction[`VRF_AWIDTH-1:0];
    assign opcode = instruction[`INSTR_WIDTH-1:`INSTR_WIDTH-`OPCODE_WIDTH];
    assign src1_id = instruction[3*`VRF_AWIDTH+2*`TARGET_OP_WIDTH:3*`VRF_AWIDTH+`TARGET_OP_WIDTH]; //or can be called mem_id
    assign dstn_id = instruction[`VRF_AWIDTH+`TARGET_OP_WIDTH-1:`VRF_AWIDTH];//LSB for dram_write bypass

    assign mvu_or_vrf_mux_select = (op2_address!={`VRF_AWIDTH{1'b0}}); //UNUSED BIT FOR MFU OPERATIONS


    //TODO - MAKE THIS SEQUENTIAL LOGIC - DONE
    always@(posedge clk) begin

    if(reset_npu == 1'b1) begin
          //reset_mvu<=1'b1;
          //start_mvu<=1'b0;
          get_instr<=1'bX;
          
          get_instr_addr<=0;
          
          start_mv_mul <= 1'b0;
    
          in_data_available_mfu_0 <= 1'b0;
          start_mfu_0 <= 1'b0;
          
          in_data_available_mfu_1 <= 1'b0;
          start_mfu_1 <= 1'b0;
          dram_write_enable <= 1'b0;
          mrf_wr_enable<='bX;


          vrf_wr_enable_mvu_0<='bX;
          vrf_readn_enable_mvu_0 <= 'bX;


          vrf_wr_enable_mvu_1<='bX;
          vrf_readn_enable_mvu_1 <= 'bX;


          vrf_wr_enable_mvu_2<='bX;
          vrf_readn_enable_mvu_2 <= 'bX;


          vrf_wr_enable_mvu_3<='bX;
          vrf_readn_enable_mvu_3 <= 'bX;


          vrf_wr_enable_mfu_add_0 <= 'bX;
          vrf_wr_enable_mfu_mul_0 <= 'bX;
          vrf_wr_enable_mfu_add_1 <= 'bX;
          vrf_wr_enable_mfu_mul_1 <= 'bX;
   
          dram_addr_wr<='bX;
          vrf_addr_wr <= 'bX;
          //vrf_addr_wr_mvu_1 <= 0;
          vrf_addr_wr_mfu_add_0 <= 'bX;
          vrf_addr_wr_mfu_mul_0 <= 'bX;
          vrf_addr_wr_mfu_add_1 <= 'bX;
          vrf_addr_wr_mfu_mul_1 <= 'bX;
          
          vrf_addr_read <= 'bX;
          //vrf_addr_read_mvu_1 <= 0;
          vrf_addr_read_mfu_add_0 <= 'bX;
          vrf_addr_read_mfu_mul_0 <= 'bX;
          vrf_addr_read_mfu_add_1 <= 'bX;
          vrf_addr_read_mfu_mul_1 <= 'bX;
          
        
           //vrf_muxed_wr_addr_dram <= 0;
           //vrf_muxed_read_addr <= 0;
           vrf_muxed_wr_enable_dram <= 'bX;
           vrf_muxed_readn_enable <= 'bX;
    
        //  orf_addr_increment<=1'b0;
          
          mrf_addr_wr <= 'bX;
          
          state <= 0;
    end
    else begin
        if(state==0) begin //FETCH
            get_instr <= 1'b0;
            state <= 1;
            vrf_wr_enable_mvu_0 <= 1'b0;
            vrf_wr_enable_mvu_1 <= 1'b0;
            vrf_wr_enable_mvu_2 <= 1'b0;
            vrf_wr_enable_mvu_3 <= 1'b0;
            vrf_wr_enable_mfu_add_0 <= 1'b0;
            vrf_wr_enable_mfu_mul_0 <= 1'b0;
            vrf_wr_enable_mfu_add_1 <= 1'b0;
            vrf_wr_enable_mfu_mul_1 <= 1'b0;
            vrf_muxed_wr_enable_dram <= 1'b0;
            dram_write_enable <= 1'b0;
            mrf_wr_enable <= 0;
        end
        else if(state==1) begin //DECODE
          case(opcode)
            `V_WR: begin
                state <= 2;
                get_instr<=0;
                //get_instr_addr<=get_instr_addr+1'b1;
                case(src1_id) 
                `VRF_0: begin vrf_wr_enable_mvu_0 <= 1'b0;
                vrf_addr_wr <= op1_address; 
                end
                `VRF_1: begin vrf_wr_enable_mvu_1 <= 1'b0;
                vrf_addr_wr <= op1_address; 
                end
                `VRF_2: begin vrf_wr_enable_mvu_2 <= 1'b0;
                vrf_addr_wr <= op1_address; 
                end
                `VRF_3: begin vrf_wr_enable_mvu_3 <= 1'b0;
                vrf_addr_wr <= op1_address; 
                end

                `VRF_4: begin vrf_wr_enable_mfu_add_0 <= 1'b0;
                vrf_addr_wr_mfu_add_0 <= op1_address; 
                end
                
                `VRF_5: begin vrf_wr_enable_mfu_mul_0 <= 1'b0;
                vrf_addr_wr_mfu_mul_0 <= op1_address; 
                end
                
                `VRF_6: begin vrf_wr_enable_mfu_add_1 <= 1'b0;
                vrf_addr_wr_mfu_add_1 <= op1_address; 
                end
                
                `VRF_7: begin 
                vrf_wr_enable_mfu_mul_1 <= 1'b0;
                vrf_addr_wr_mfu_mul_1 <= op1_address; 
                end
                
                `VRF_MUXED: begin 
                vrf_muxed_wr_enable_dram <= 1'b0;
                vrf_muxed_wr_addr_dram <= op1_address; 
                end
                
                default: begin 
                vrf_wr_enable_mvu_0 <= 1'bX;
                output_data_to_dram <= 'bX;
                end
    
                endcase
                
                dram_addr_wr <= dstn_address;
                dram_write_enable <= 1'b1;
            end
            `V_RD: begin
                state <= 2;
                
                get_instr<=0;
                dram_addr_wr <= op1_address;
                dram_write_enable <= 1'b0;
                
            end
            //CHANGE NAMING CONVENTION FOR WRITE AND READ TO STORE AND LOAD
            //ADD COMMENTS FOR SRC AND DESTINATION
            `M_RD: begin
                state <= 2;
                get_instr<=0;
                dram_addr_wr <= op1_address;
                dram_write_enable <= 1'b0;
            end
            `MV_MUL: begin
              //op1_id is don't care for this instructions
              //$display("------------- in instr dec %b", mrf_addr_wr);
               state <= 2;
               get_instr<=1'b0;
               start_mv_mul <= 1'b1;
               mrf_addr_wr[(1*`MRF_AWIDTH)-1:0*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(2*`MRF_AWIDTH)-1:1*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(3*`MRF_AWIDTH)-1:2*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(4*`MRF_AWIDTH)-1:3*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(5*`MRF_AWIDTH)-1:4*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(6*`MRF_AWIDTH)-1:5*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(7*`MRF_AWIDTH)-1:6*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(8*`MRF_AWIDTH)-1:7*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(9*`MRF_AWIDTH)-1:8*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(10*`MRF_AWIDTH)-1:9*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(11*`MRF_AWIDTH)-1:10*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(12*`MRF_AWIDTH)-1:11*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(13*`MRF_AWIDTH)-1:12*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(14*`MRF_AWIDTH)-1:13*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(15*`MRF_AWIDTH)-1:14*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(16*`MRF_AWIDTH)-1:15*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(17*`MRF_AWIDTH)-1:16*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(18*`MRF_AWIDTH)-1:17*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(19*`MRF_AWIDTH)-1:18*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(20*`MRF_AWIDTH)-1:19*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(21*`MRF_AWIDTH)-1:20*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(22*`MRF_AWIDTH)-1:21*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(23*`MRF_AWIDTH)-1:22*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(24*`MRF_AWIDTH)-1:23*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(25*`MRF_AWIDTH)-1:24*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(26*`MRF_AWIDTH)-1:25*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(27*`MRF_AWIDTH)-1:26*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(28*`MRF_AWIDTH)-1:27*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(29*`MRF_AWIDTH)-1:28*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(30*`MRF_AWIDTH)-1:29*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(31*`MRF_AWIDTH)-1:30*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(32*`MRF_AWIDTH)-1:31*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(33*`MRF_AWIDTH)-1:32*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(34*`MRF_AWIDTH)-1:33*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(35*`MRF_AWIDTH)-1:34*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(36*`MRF_AWIDTH)-1:35*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(37*`MRF_AWIDTH)-1:36*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(38*`MRF_AWIDTH)-1:37*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(39*`MRF_AWIDTH)-1:38*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(40*`MRF_AWIDTH)-1:39*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(41*`MRF_AWIDTH)-1:40*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(42*`MRF_AWIDTH)-1:41*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(43*`MRF_AWIDTH)-1:42*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(44*`MRF_AWIDTH)-1:43*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(45*`MRF_AWIDTH)-1:44*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(46*`MRF_AWIDTH)-1:45*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(47*`MRF_AWIDTH)-1:46*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(48*`MRF_AWIDTH)-1:47*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(49*`MRF_AWIDTH)-1:48*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(50*`MRF_AWIDTH)-1:49*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(51*`MRF_AWIDTH)-1:50*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(52*`MRF_AWIDTH)-1:51*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(53*`MRF_AWIDTH)-1:52*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(54*`MRF_AWIDTH)-1:53*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(55*`MRF_AWIDTH)-1:54*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(56*`MRF_AWIDTH)-1:55*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(57*`MRF_AWIDTH)-1:56*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(58*`MRF_AWIDTH)-1:57*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(59*`MRF_AWIDTH)-1:58*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(60*`MRF_AWIDTH)-1:59*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(61*`MRF_AWIDTH)-1:60*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(62*`MRF_AWIDTH)-1:61*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(63*`MRF_AWIDTH)-1:62*`MRF_AWIDTH] <= op1_address;
               mrf_addr_wr[(64*`MRF_AWIDTH)-1:63*`MRF_AWIDTH] <= op1_address;
               vrf_addr_read <= op2_address;  
               vrf_readn_enable_mvu_0 <= 1'b0;
               vrf_readn_enable_mvu_1 <= 1'b0;
               vrf_readn_enable_mvu_2 <= 1'b0;
               vrf_readn_enable_mvu_3 <= 1'b0;
               mrf_wr_enable <= 0;
            end
            `VV_ADD,`VV_SUB:begin
            
              //MFU_STAGE-0 DESIGNATED FOR ELTWISE ADD
              state <= 2;
              get_instr<=1'b0;
              operation<=`ELT_WISE_ADD;      //NOTE - 2nd VRF INDEX IS FOR ADD UNITS ELT WISE

              case(src1_id) 
              
               `VRF_4: begin 
                start_mfu_0 <= 1'b1;

                vrf_muxed_readn_enable <= 1'b0;
                vrf_muxed_wr_addr_dram <= op2_address;

                in_data_available_mfu_0 <= 1'b1;
                vrf_addr_read_mfu_add_0 <= op1_address;
                vrf_readn_enable_mfu_add_0 <= 1'b0; 
               end
              
               
               `VRF_6: begin 
                start_mfu_1 <= 1'b1;
                in_data_available_mfu_1 <= 1'b1;
                vrf_addr_read_mfu_add_1 <= op1_address;
                vrf_readn_enable_mfu_add_1 <= 1'b0; 
               end
               
               
               default: begin
                start_mfu_0 <= 1'bX;
                in_data_available_mfu_0 <= 1'bX;
                vrf_addr_read_mfu_add_0 <= 'bX;
                vrf_readn_enable_mfu_add_0 <= 1'bX; 
                vrf_addr_read_mfu_add_1 <= 'bX;
                vrf_readn_enable_mfu_add_1 <= 1'bX;
               end
               
             endcase

            end
            `VV_MUL:begin
             state <= 2;
             get_instr<=1'b0;

              operation<=`ELT_WISE_MULTIPLY;     //NOTE - 3RD VRF INDEX IS FOR ADD UNITS ELT WISE
              case(src1_id) 
              
               `VRF_5: begin 
                start_mfu_0 <= 1'b1;

                vrf_muxed_readn_enable <= 1'b0;
                vrf_muxed_wr_addr_dram <= op2_address;

                in_data_available_mfu_0 <= 1'b1;
                vrf_addr_read_mfu_mul_0 <= op1_address;
                vrf_readn_enable_mfu_mul_0 <= 1'b0; 
               end
               
               `VRF_7: begin 
                start_mfu_1 <= 1'b1;
                in_data_available_mfu_1 <= 1'b1;
                vrf_addr_read_mfu_mul_1 <= op1_address;
                vrf_readn_enable_mfu_mul_1 <= 1'b0; 
               end
  
               default: begin
                start_mfu_0 <= 1'bX;
                in_data_available_mfu_0 <= 1'bX;
                vrf_addr_read_mfu_mul_0 <= 'bX;
                vrf_readn_enable_mfu_mul_0 <= 1'bX; 
                vrf_addr_read_mfu_mul_1 <= 'bX;
                vrf_readn_enable_mfu_mul_1 <= 1'bX; 
               end
               
             endcase
             
            end
            `V_RELU:begin

              get_instr<=1'b0;
              case(src1_id) 
              
              `MFU_0: begin 
                start_mfu_0<=1'b1;
                in_data_available_mfu_0<=1'b1;

                vrf_muxed_readn_enable <= 1'b0;
                vrf_muxed_wr_addr_dram <= op2_address;
               end
               
               `MFU_1: begin
                 start_mfu_1<=1'b1;
                 in_data_available_mfu_1<=1'b1;
                end
                
                default: begin
                start_mfu_0<=1'bX;
                in_data_available_mfu_0<=1'bX;
                end
               
              endcase
              operation<=`ACTIVATION;
              activation<=`RELU;
              state <= 2;

            end
            `V_SIGM:begin

              get_instr<=1'b0;
              case(src1_id) 
              
              `MFU_0: begin 
                start_mfu_0<=1'b1;
                in_data_available_mfu_0<=1'b1;

                vrf_muxed_readn_enable <= 1'b0;
                vrf_muxed_wr_addr_dram <= op2_address;
               end
               
               `MFU_1: begin
                 start_mfu_1<=1'b1;
                 in_data_available_mfu_1<=1'b1;
                end
                
                default: begin
                start_mfu_0<=1'bX;
                in_data_available_mfu_0<=1'bX;
                end
                
              endcase
              operation<=`ACTIVATION;
              activation<=`SIGM;
              state <= 2;
            end
            `V_TANH:begin
            //dram_write_enable <= bypass_id[0];
              get_instr<=1'b0;
              case(src1_id) 
              
              `MFU_0: begin 
                start_mfu_0<=1'b1;
                in_data_available_mfu_0<=1'b1;

                vrf_muxed_readn_enable <= 1'b0;
                vrf_muxed_wr_addr_dram <= op2_address;
               end
               
               `MFU_1: begin
                 start_mfu_1<=1'b1;
                 in_data_available_mfu_1<=1'b1;
                end
                
                default: begin
                start_mfu_0<=1'bX;
                in_data_available_mfu_0<=1'bX;
                end
                
              endcase
              operation<=`ACTIVATION;
              activation<=`TANH;
              state <= 2;

            end
            `END_CHAIN, `VV_PASS:begin

              start_mv_mul<=1'b0;
              get_instr<=1'b0;

              in_data_available_mfu_0<=1'b0;
              start_mfu_0<=1'b0;
              
              in_data_available_mfu_1<=1'b0;
              start_mfu_1<=1'b0;
              
              mrf_wr_enable<=0;


              vrf_wr_enable_mvu_0<='b0;
              vrf_readn_enable_mvu_0 <= 'b0;


              vrf_wr_enable_mvu_1<='b0;
              vrf_readn_enable_mvu_1 <= 'b0;


              vrf_wr_enable_mvu_2<='b0;
              vrf_readn_enable_mvu_2 <= 'b0;


              vrf_wr_enable_mvu_3<='b0;
              vrf_readn_enable_mvu_3 <= 'b0;

              
              vrf_wr_enable_mfu_add_0 <= 0;
              vrf_wr_enable_mfu_mul_0 <= 0;
              vrf_wr_enable_mfu_add_1 <= 0;
              vrf_wr_enable_mfu_mul_1 <= 0;

              vrf_muxed_readn_enable <= 1'b0;
              vrf_muxed_wr_addr_dram <= 1'b0;
              
              vrf_readn_enable_mfu_add_0 <= 0;
              vrf_readn_enable_mfu_mul_0 <= 0;
              vrf_readn_enable_mfu_add_1 <= 0;
              vrf_readn_enable_mfu_mul_1 <= 0;
              
              //orf_addr_increment<=1'b0;
              mrf_addr_wr <= 0;
              dram_write_enable <=  1'b0;
              state <= 1;
            end
          endcase          
         end
         else begin //EXECUTE
         
            case(opcode) 
            `V_WR: begin
                state <= 0;
                get_instr<=1'b1;
                get_instr_addr<=get_instr_addr+1'b1;
        
                case(src1_id) 

                `VRF_0: begin 
                output_data_to_dram <= vrf_out_data_mvu_0;
                end
                `VRF_1: begin 
                output_data_to_dram <= vrf_out_data_mvu_1;
                end
                `VRF_2: begin 
                output_data_to_dram <= vrf_out_data_mvu_2;
                end
                `VRF_3: begin 
                output_data_to_dram <= vrf_out_data_mvu_3;
                end
    
                `VRF_4: begin  
                output_data_to_dram <= vrf_out_data_mfu_add_0;
                end
                
                `VRF_5: begin 
                output_data_to_dram <= vrf_out_data_mfu_mul_0;
                end
                
                `VRF_6: begin 
                    output_data_to_dram <= vrf_out_data_mfu_add_1;
                end
                
                `VRF_7: begin 
                    output_data_to_dram <= vrf_out_data_mfu_mul_1;
                end
                
               `VRF_MUXED: begin 
                    output_data_to_dram <= vrf_muxed_out_data_dram;
                end
                default: begin 
                    output_data_to_dram <= 'bX;
                end
              endcase
              
            end
            `V_RD: begin
                state <= 0;
                get_instr<=1'b1;
                get_instr_addr<=get_instr_addr+1'b1;
                vrf_in_data <= input_data_from_dram;
                case(dstn_id) 
                  `VRF_0: begin 
                  vrf_wr_enable_mvu_0 <= 1'b1;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  
                  vrf_addr_wr <= dstn_address;
                  end
                  `VRF_1: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b1;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  
                  vrf_addr_wr <= dstn_address;
                  end
                  `VRF_2: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b1;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  
                  vrf_addr_wr <= dstn_address;
                  end
                  `VRF_3: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b1;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  
                  vrf_addr_wr <= dstn_address;
                  end
                  `VRF_4: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b1;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  
                  vrf_addr_wr_mfu_add_0 <= dstn_address;
                  
                  end
                  
                  `VRF_5: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b1;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  
                  vrf_addr_wr_mfu_mul_0 <= dstn_address;
                  
                  end
                  
                  `VRF_6: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b1;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  
                  vrf_addr_wr_mfu_add_1 <= dstn_address;
                  end
                  
                  `VRF_7: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b1;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  
                  vrf_addr_wr_mfu_mul_1 <= dstn_address;
                  end
                  
                  `VRF_MUXED: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b1;
                  
                   
                  vrf_muxed_wr_addr_dram <= dstn_address;
                  end
    
                  default: begin 
                  vrf_wr_enable_mvu_0 <= 1'bX;
                  vrf_wr_enable_mvu_1 <= 1'bX;
                  vrf_wr_enable_mvu_2 <= 1'bX;
                  vrf_wr_enable_mvu_3 <= 1'bX;
                  vrf_wr_enable_mfu_add_0 <= 1'bX;
                  vrf_wr_enable_mfu_mul_0 <= 1'bX;
                  vrf_wr_enable_mfu_add_1 <= 1'bX;
                  vrf_wr_enable_mfu_mul_1 <= 1'bX;
                  vrf_muxed_wr_enable_dram <= 1'bX;
 
                  end
                endcase
/*
                vrf_wr_enable_mvu_0 <= 1'b0;
                vrf_wr_enable_mvu_1 <= 1'b0;
                vrf_wr_enable_mvu_2 <= 1'b0;
                vrf_wr_enable_mvu_3 <= 1'b0;
                vrf_wr_enable_mfu_add_0 <= 1'b0;
                vrf_wr_enable_mfu_mul_0 <= 1'b0;
                vrf_wr_enable_mfu_add_1 <= 1'b0;
                vrf_wr_enable_mfu_mul_1 <= 1'b0;
                vrf_muxed_wr_enable_dram <= 1'b0;
*/
                
            end
            `M_RD: begin
                state <= 0;
                get_instr<=1'b1;
                get_instr_addr<=get_instr_addr+1'b1;
                mrf_in_data <= input_data_from_dram;

                case(dstn_id) 
                  `MRF_0: begin 
                    mrf_wr_enable[0] <= 1;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[1*`MRF_AWIDTH-1:0*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_1: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 1;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[2*`MRF_AWIDTH-1:1*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_2: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 1;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[3*`MRF_AWIDTH-1:2*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_3: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 1;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[4*`MRF_AWIDTH-1:3*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_4: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 1;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[5*`MRF_AWIDTH-1:4*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_5: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 1;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[6*`MRF_AWIDTH-1:5*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_6: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 1;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[7*`MRF_AWIDTH-1:6*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_7: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 1;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[8*`MRF_AWIDTH-1:7*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_8: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 1;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[9*`MRF_AWIDTH-1:8*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_9: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 1;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[10*`MRF_AWIDTH-1:9*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_10: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 1;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[11*`MRF_AWIDTH-1:10*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_11: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 1;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[12*`MRF_AWIDTH-1:11*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_12: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 1;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[13*`MRF_AWIDTH-1:12*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_13: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 1;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[14*`MRF_AWIDTH-1:13*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_14: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 1;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[15*`MRF_AWIDTH-1:14*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_15: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 1;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[16*`MRF_AWIDTH-1:15*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_16: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 1;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[17*`MRF_AWIDTH-1:16*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_17: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 1;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[18*`MRF_AWIDTH-1:17*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_18: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 1;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[19*`MRF_AWIDTH-1:18*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_19: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 1;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[20*`MRF_AWIDTH-1:19*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_20: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 1;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[21*`MRF_AWIDTH-1:20*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_21: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 1;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[22*`MRF_AWIDTH-1:21*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_22: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 1;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[23*`MRF_AWIDTH-1:22*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_23: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 1;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[24*`MRF_AWIDTH-1:23*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_24: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 1;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[25*`MRF_AWIDTH-1:24*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_25: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 1;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[26*`MRF_AWIDTH-1:25*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_26: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 1;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[27*`MRF_AWIDTH-1:26*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_27: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 1;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[28*`MRF_AWIDTH-1:27*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_28: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 1;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[29*`MRF_AWIDTH-1:28*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_29: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 1;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[30*`MRF_AWIDTH-1:29*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_30: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 1;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[31*`MRF_AWIDTH-1:30*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_31: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 1;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[32*`MRF_AWIDTH-1:31*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_32: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 1;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[33*`MRF_AWIDTH-1:32*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_33: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 1;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[34*`MRF_AWIDTH-1:33*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_34: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 1;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[35*`MRF_AWIDTH-1:34*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_35: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 1;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[36*`MRF_AWIDTH-1:35*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_36: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 1;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[37*`MRF_AWIDTH-1:36*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_37: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 1;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[38*`MRF_AWIDTH-1:37*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_38: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 1;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[39*`MRF_AWIDTH-1:38*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_39: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 1;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[40*`MRF_AWIDTH-1:39*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_40: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 1;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[41*`MRF_AWIDTH-1:40*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_41: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 1;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[42*`MRF_AWIDTH-1:41*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_42: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 1;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[43*`MRF_AWIDTH-1:42*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_43: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 1;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[44*`MRF_AWIDTH-1:43*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_44: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 1;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[45*`MRF_AWIDTH-1:44*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_45: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 1;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[46*`MRF_AWIDTH-1:45*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_46: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 1;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[47*`MRF_AWIDTH-1:46*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_47: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 1;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[48*`MRF_AWIDTH-1:47*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_48: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 1;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[49*`MRF_AWIDTH-1:48*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_49: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 1;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[50*`MRF_AWIDTH-1:49*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_50: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 1;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[51*`MRF_AWIDTH-1:50*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_51: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 1;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[52*`MRF_AWIDTH-1:51*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_52: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 1;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[53*`MRF_AWIDTH-1:52*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_53: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 1;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[54*`MRF_AWIDTH-1:53*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_54: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 1;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[55*`MRF_AWIDTH-1:54*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_55: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 1;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[56*`MRF_AWIDTH-1:55*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_56: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 1;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[57*`MRF_AWIDTH-1:56*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_57: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 1;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[58*`MRF_AWIDTH-1:57*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_58: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 1;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[59*`MRF_AWIDTH-1:58*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_59: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 1;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[60*`MRF_AWIDTH-1:59*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_60: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 1;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[61*`MRF_AWIDTH-1:60*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_61: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 1;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[62*`MRF_AWIDTH-1:61*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_62: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 1;
                    mrf_wr_enable[63] <= 0;
                    mrf_addr_wr[63*`MRF_AWIDTH-1:62*`MRF_AWIDTH] = dstn_address;            
                  end
                  `MRF_63: begin 
                    mrf_wr_enable[0] <= 0;
                    mrf_wr_enable[1] <= 0;
                    mrf_wr_enable[2] <= 0;
                    mrf_wr_enable[3] <= 0;
                    mrf_wr_enable[4] <= 0;
                    mrf_wr_enable[5] <= 0;
                    mrf_wr_enable[6] <= 0;
                    mrf_wr_enable[7] <= 0;
                    mrf_wr_enable[8] <= 0;
                    mrf_wr_enable[9] <= 0;
                    mrf_wr_enable[10] <= 0;
                    mrf_wr_enable[11] <= 0;
                    mrf_wr_enable[12] <= 0;
                    mrf_wr_enable[13] <= 0;
                    mrf_wr_enable[14] <= 0;
                    mrf_wr_enable[15] <= 0;
                    mrf_wr_enable[16] <= 0;
                    mrf_wr_enable[17] <= 0;
                    mrf_wr_enable[18] <= 0;
                    mrf_wr_enable[19] <= 0;
                    mrf_wr_enable[20] <= 0;
                    mrf_wr_enable[21] <= 0;
                    mrf_wr_enable[22] <= 0;
                    mrf_wr_enable[23] <= 0;
                    mrf_wr_enable[24] <= 0;
                    mrf_wr_enable[25] <= 0;
                    mrf_wr_enable[26] <= 0;
                    mrf_wr_enable[27] <= 0;
                    mrf_wr_enable[28] <= 0;
                    mrf_wr_enable[29] <= 0;
                    mrf_wr_enable[30] <= 0;
                    mrf_wr_enable[31] <= 0;
                    mrf_wr_enable[32] <= 0;
                    mrf_wr_enable[33] <= 0;
                    mrf_wr_enable[34] <= 0;
                    mrf_wr_enable[35] <= 0;
                    mrf_wr_enable[36] <= 0;
                    mrf_wr_enable[37] <= 0;
                    mrf_wr_enable[38] <= 0;
                    mrf_wr_enable[39] <= 0;
                    mrf_wr_enable[40] <= 0;
                    mrf_wr_enable[41] <= 0;
                    mrf_wr_enable[42] <= 0;
                    mrf_wr_enable[43] <= 0;
                    mrf_wr_enable[44] <= 0;
                    mrf_wr_enable[45] <= 0;
                    mrf_wr_enable[46] <= 0;
                    mrf_wr_enable[47] <= 0;
                    mrf_wr_enable[48] <= 0;
                    mrf_wr_enable[49] <= 0;
                    mrf_wr_enable[50] <= 0;
                    mrf_wr_enable[51] <= 0;
                    mrf_wr_enable[52] <= 0;
                    mrf_wr_enable[53] <= 0;
                    mrf_wr_enable[54] <= 0;
                    mrf_wr_enable[55] <= 0;
                    mrf_wr_enable[56] <= 0;
                    mrf_wr_enable[57] <= 0;
                    mrf_wr_enable[58] <= 0;
                    mrf_wr_enable[59] <= 0;
                    mrf_wr_enable[60] <= 0;
                    mrf_wr_enable[61] <= 0;
                    mrf_wr_enable[62] <= 0;
                    mrf_wr_enable[63] <= 1;
                    mrf_addr_wr[64*`MRF_AWIDTH-1:63*`MRF_AWIDTH] = dstn_address;            
                  end
                  
                  default: begin 
                    mrf_wr_enable[0] <= 1'bX;
                    mrf_wr_enable[1] <= 1'bX;
                    mrf_wr_enable[2] <= 1'bX;
                    mrf_wr_enable[3] <= 1'bX;
                    mrf_wr_enable[4] <= 1'bX;
                    mrf_wr_enable[5] <= 1'bX;
                    mrf_wr_enable[6] <= 1'bX;
                    mrf_wr_enable[7] <= 1'bX;
                    mrf_wr_enable[8] <= 1'bX;
                    mrf_wr_enable[9] <= 1'bX;
                    mrf_wr_enable[10] <= 1'bX;
                    mrf_wr_enable[11] <= 1'bX;
                    mrf_wr_enable[12] <= 1'bX;
                    mrf_wr_enable[13] <= 1'bX;
                    mrf_wr_enable[14] <= 1'bX;
                    mrf_wr_enable[15] <= 1'bX;
                    mrf_wr_enable[16] <= 1'bX;
                    mrf_wr_enable[17] <= 1'bX;
                    mrf_wr_enable[18] <= 1'bX;
                    mrf_wr_enable[19] <= 1'bX;
                    mrf_wr_enable[20] <= 1'bX;
                    mrf_wr_enable[21] <= 1'bX;
                    mrf_wr_enable[22] <= 1'bX;
                    mrf_wr_enable[23] <= 1'bX;
                    mrf_wr_enable[24] <= 1'bX;
                    mrf_wr_enable[25] <= 1'bX;
                    mrf_wr_enable[26] <= 1'bX;
                    mrf_wr_enable[27] <= 1'bX;
                    mrf_wr_enable[28] <= 1'bX;
                    mrf_wr_enable[29] <= 1'bX;
                    mrf_wr_enable[30] <= 1'bX;
                    mrf_wr_enable[31] <= 1'bX;
                    mrf_wr_enable[32] <= 1'bX;
                    mrf_wr_enable[33] <= 1'bX;
                    mrf_wr_enable[34] <= 1'bX;
                    mrf_wr_enable[35] <= 1'bX;
                    mrf_wr_enable[36] <= 1'bX;
                    mrf_wr_enable[37] <= 1'bX;
                    mrf_wr_enable[38] <= 1'bX;
                    mrf_wr_enable[39] <= 1'bX;
                    mrf_wr_enable[40] <= 1'bX;
                    mrf_wr_enable[41] <= 1'bX;
                    mrf_wr_enable[42] <= 1'bX;
                    mrf_wr_enable[43] <= 1'bX;
                    mrf_wr_enable[44] <= 1'bX;
                    mrf_wr_enable[45] <= 1'bX;
                    mrf_wr_enable[46] <= 1'bX;
                    mrf_wr_enable[47] <= 1'bX;
                    mrf_wr_enable[48] <= 1'bX;
                    mrf_wr_enable[49] <= 1'bX;
                    mrf_wr_enable[50] <= 1'bX;
                    mrf_wr_enable[51] <= 1'bX;
                    mrf_wr_enable[52] <= 1'bX;
                    mrf_wr_enable[53] <= 1'bX;
                    mrf_wr_enable[54] <= 1'bX;
                    mrf_wr_enable[55] <= 1'bX;
                    mrf_wr_enable[56] <= 1'bX;
                    mrf_wr_enable[57] <= 1'bX;
                    mrf_wr_enable[58] <= 1'bX;
                    mrf_wr_enable[59] <= 1'bX;
                    mrf_wr_enable[60] <= 1'bX;
                    mrf_wr_enable[61] <= 1'bX;
                    mrf_wr_enable[62] <= 1'bX;
                    mrf_wr_enable[63] <= 1'bX;
                    mrf_addr_wr[1*`MRF_AWIDTH-1:0*`MRF_AWIDTH] = 'bX;
                       
                  end
                  
                endcase 
            end
            default: begin
            
            if(done_mvm || done_mfu_0 || done_mfu_1) begin
                start_mv_mul <= 0;
                start_mfu_0 <= 0;
                start_mfu_1 <= 0;
                state <= 0;
                get_instr<=1'b1;
                get_instr_addr<=get_instr_addr+1'b1;
               
                case(dstn_id) 
                  `VRF_0: begin 
                  vrf_wr_enable_mvu_0 <= 1'b1;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  dram_write_enable<=1'b0;
                  
                  vrf_in_data <= output_final_stage;
                  
                  vrf_addr_wr<=dstn_address;
                  //vrf_addr_wr_mvu_0 <= dstn_address;
                  end
                  `VRF_1: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b1;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  dram_write_enable<=1'b0;
                  
                  vrf_in_data <= output_final_stage;
                  
                  vrf_addr_wr<=dstn_address;
                  //vrf_addr_wr_mvu_0 <= dstn_address;
                  end
                  `VRF_2: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b1;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  dram_write_enable<=1'b0;
                  
                  vrf_in_data <= output_final_stage;
                  
                  vrf_addr_wr<=dstn_address;
                  //vrf_addr_wr_mvu_0 <= dstn_address;
                  end
                  `VRF_3: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b1;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  dram_write_enable<=1'b0;
                  
                  vrf_in_data <= output_final_stage;
                  
                  vrf_addr_wr<=dstn_address;
                  //vrf_addr_wr_mvu_0 <= dstn_address;
                  end

                  `VRF_4: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b1;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  dram_write_enable<=1'b0;
                  
                  vrf_in_data <= output_final_stage;
                  
                  vrf_addr_wr_mfu_add_0 <= dstn_address;
                  
                  end
                  
                  `VRF_5: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b1;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  vrf_in_data <= output_final_stage;
                  
                  vrf_addr_wr_mfu_mul_0 <= dstn_address;
                  
                  end
                  
                  `VRF_6: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b1;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  dram_write_enable<=1'b0;
                  
                  vrf_in_data <= output_final_stage;
                  
                  vrf_addr_wr_mfu_add_1 <= dstn_address;
                  end
                  
                  `VRF_7: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b1;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  dram_write_enable<=1'b0;
                  
                  vrf_in_data <= output_final_stage;
                  
                  vrf_addr_wr_mfu_mul_1 <= dstn_address;
                  end
                  
                  `VRF_MUXED: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b1;
                   dram_write_enable<=1'b0;
                   
                   vrf_in_data <= output_final_stage;
                   
                  vrf_muxed_wr_addr_dram <= dstn_address;
                  end
    
                  `DRAM_MEM_ID: begin
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  dram_write_enable<=1'b1;
                  
                  output_data_to_dram <= output_final_stage;
                   
                  dram_addr_wr <= dstn_address;
                  end
                  
                  //MFU_OUT_STAGE IDS USED FOR MUXING
                  
                  default: begin 
                  vrf_wr_enable_mvu_0 <= 1'b0;
                  vrf_wr_enable_mvu_1 <= 1'b0;
                  vrf_wr_enable_mvu_2 <= 1'b0;
                  vrf_wr_enable_mvu_3 <= 1'b0;
                  vrf_wr_enable_mfu_add_0 <= 1'b0;
                  vrf_wr_enable_mfu_mul_0 <= 1'b0;
                  vrf_wr_enable_mfu_add_1 <= 1'b0;
                  vrf_wr_enable_mfu_mul_1 <= 1'b0;
                  vrf_muxed_wr_enable_dram <= 1'b0;
                  dram_write_enable<=1'b0;
                  end
                 endcase
                end
              end 
             endcase      
            end
         end
       end          
endmodule             