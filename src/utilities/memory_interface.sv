
interface MemoryInterface #(
    parameter type data_type = logic [7:0],
    parameter ADDR_WIDTH = 16
);
  localparam DATA_WIDTH = $bits(data_type);

  // Signal Declarations
  data_type                    data;  // Data bus
  logic     [ADDR_WIDTH-1:0]   address;  // Address bus
  logic     [DATA_WIDTH/8-1:0] byte_enable;  // Address bus
  logic                        enable;  // Enable signal


  modport write_out(
      output data,  // Master writes data
      output address,  // Master provides address
      output enable,  // Master controls enable
      output byte_enable
  );

  modport read_out(
      input data,  // Slave reads data
      output address,  // Slave receives address
      output enable, // Slave receives enable signal
      output byte_enable
  );

  modport write_in(
      input data,  // Master writes data
      input address,  // Master provides address
      input enable,  // Master controls enable
      input byte_enable
  );

  modport read_in(
      output data,  // Slave reads data
      input address,  // Slave receives address
      input enable, // Slave receives enable signal
      input byte_enable
  );

endinterface


interface MemoryInterfaceSinglePort #(
    parameter type data_type = logic [7:0],
    parameter ADDR_WIDTH = 16
);
  localparam DATA_WIDTH = $bits(data_type);

  // Signal Declarations
  data_type                    read_data;     // Data bus
  data_type                    write_data;    // Data bus
  logic     [ADDR_WIDTH-1:0]   address;       // Address bus
  logic                        write_enable;  // Enable signal
  logic     [DATA_WIDTH/8-1:0] byte_enable;   // Address bus
  logic     [DATA_WIDTH/8-1:0] enable;   // Address bus


  modport master (
      input read_data,  // Master writes data
      output write_data,  // Master writes data
      output address,  // Master provides address
      output write_enable,  // Master controls enable
      output enable,  // Master controls enable
      output byte_enable
  );

  modport slave (
      output read_data,  // Slave reads data
      input write_data,  // Slave reads data
      input address,  // Master provides address
      input write_enable, // Slave receives enable signal
      input enable, // Slave receives enable signal
      input byte_enable
  );


endinterface


