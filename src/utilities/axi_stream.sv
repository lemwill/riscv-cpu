interface Axis #(
    parameter type data_type = logic [7:0]
);
  localparam DATA_WIDTH = $bits(data_type);

  data_type tdata;
  logic tvalid;  // Indicates that tdata is valid
  logic tready;  // If tvalid (master) and tready (slave) are asserted, tdata is consumed 

  modport in(input tdata, tvalid, output tready);
  modport out(output tdata, tvalid, input tready);
  modport monitor(input tdata, tvalid, tready);

endinterface

interface Axis_no_tready #(
    parameter type data_type = logic [7:0]
);
  localparam DATA_WIDTH = $bits(data_type);

  data_type tdata;
  logic tvalid;  // Indicates that tdata is valid

  modport in(input tdata, tvalid);
  modport out(output tdata, tvalid);

endinterface

interface Axis_tlast #(
    parameter type data_type = logic [7:0]
);
  localparam DATA_WIDTH = $bits(data_type);

  data_type tdata;
  logic tvalid;  // Indicates that tdata is valid
  logic tready;  // If tvalid (master) and tready (slave) are asserted, tdata is consumed 
  logic tlast;  // Indicates the end of a data stream

  modport in(input tdata, tvalid, tlast, output tready);
  modport out(output tdata, tvalid, tlast, input tready);

endinterface


interface Axis_tlast_tkeep #(
    parameter type data_type = logic [7:0]
);
  localparam DATA_WIDTH = $bits(data_type);

  data_type tdata;
  logic [DATA_WIDTH/8-1:0] tkeep;
  logic tvalid;  // Indicates that tdata is valid
  logic tready;  // If tvalid (master) and tready (slave) are asserted, tdata is consumed 
  logic tlast;  // Indicates the end of a data stream

  modport in(input tdata, tvalid, tlast, tkeep, output tready);
  modport out(output tdata, tvalid, tlast, tkeep, input tready);

endinterface

interface Axis_tlast_user #(
    parameter type data_type = logic [7:0]
);
  localparam DATA_WIDTH = $bits(data_type);

  data_type tdata;
  logic tvalid;  // Indicates that tdata is valid
  logic tready;  // If tvalid (master) and tready (slave) are asserted, tdata is consumed 
  logic tlast;  // Indicates the end of a data stream
  logic axi_user;  // User defined signal. Often used as a start of a data stream

  modport in(input tdata, tvalid, tlast, axi_user, output tready);
  modport out(output tdata, tvalid, tlast, axi_user, input tready);

endinterface

interface Axis_tlast_no_tready #(
    parameter type data_type = logic [7:0]
);
  localparam DATA_WIDTH = $bits(data_type);

  data_type tdata;
  logic tvalid;  // Indicates that tdata is valid
  logic tlast;  // Indicates the end of a data stream

  modport in(input tdata, tvalid, tlast);
  modport out(output tdata, tvalid, tlast);

endinterface

interface Axis_tlast_no_tready_user #(
    parameter type data_type = logic [7:0]
);
  localparam DATA_WIDTH = $bits(data_type);

  data_type tdata;
  logic tvalid;  // Indicates that tdata is valid
  logic tlast;  // Indicates the end of a data stream
  logic axi_user;  // User defined signal

  modport in(input tdata, tvalid, tlast, axi_user);
  modport out(output tdata, tvalid, tlast, axi_user);

endinterface

