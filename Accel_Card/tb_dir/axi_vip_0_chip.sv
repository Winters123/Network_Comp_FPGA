
`timescale 1 ps / 1 ps

module chip
   (
    aresetn,
  
    aclk
    );
  input aclk;
  input aresetn;
  

  wire aclk;
  wire aresetn;
  

  // tb_monitor_adapter tb_monitor
  //      (
  //      .clk(aclk),
  //      .aresetn(aresetn)
  //      );
  tb_controller tb_controller
       (
       .clk(aclk),
       .aresetn(aresetn)
       );
endmodule

