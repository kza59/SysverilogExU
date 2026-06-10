// Getting familiar with sysverilog...
// Kinda like library ieee; use ieee.std_logic_1164.all;
import uvm_pkg::*;
`include "uvm_macros.svh"

// Interface: details DUT signals
interface fa_if;
    logic a;
    logic b;
    logic cin;
    logic s;
    logic cout;
endinterface

// Sequence item: one transaction
class fa_item extends uvm_sequence_item;

    rand bit a;
    rand bit b;
    rand bit cin;
    
    bit s;
    bit cout;
    // Registers this component with the UVM factory so we can easily construct an item of this class via fa_item::type_id::create("ITEM_NAME")
    `uvm_object_utils(fa_item)
    // Initialization just uses name because uvm_sequence derived from uvm_object. Those that use parent as well are derived from uvm_component
    function new(string name = "fa_item");
        super.new(name);
    endfunction
endclass

// Sequence: generates transactions (producer in the consumer-producer problem)
class fa_sequence extends uvm_sequence #(fa_item);
    `uvm_object_utils(fa_sequence)
    function new(string name = "fa_item");
        super.new(name);
    endfunction
    task body();
        fa_item item;
        // repeat(100) begin
        //     item = fa_item::type_id::create("item");
        //     start_item(item);
        //     assert(item.randomize());
        //     finish_item(item);
        // end
        for (int i = 0; i < 8; i++) begin
            item = fa_item::type_id::create("item");
            start_item(item);
            item.a = i[2];
            item.b = i[1];
            item.cin = i[0];
            finish_item(item);
        end        
    endtask
endclass

// Sequencer: passes items from sequence to driver
class fa_sequencer extends uvm_sequencer #(fa_item);
    `uvm_component_utils(fa_sequencer)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

// Driver: go through sequence items one by one, asserting the inputs of the vif (virtual interface) using their inputs. 
// seq_item_port is inherited from uvm_driver 
class fa_driver extends uvm_driver #(fa_item);
    virtual fa_if vif;
    `uvm_component_utils(fa_driver)
    uvm_analysis_port #(fa_item) ap;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Initialize my own ap to use later
        ap  = new("ap", this);
        // Grabbing the actual vif
        if(!uvm_config_db #(virtual fa_if)::get(this,"","vif",vif))`uvm_fatal("NOVIF", "vif not set")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            vif.a = req.a;
            vif.b = req.b;
            vif.cin = req.cin;
            #1ns;
            seq_item_port.item_done();
        end
    endtask
endclass

// Monitor: tracks the inputs and outputs observed for each sequence item
class fa_monitor extends uvm_monitor;
    virtual fa_if vif;
    // Declare analysis port 
    uvm_analysis_port #(fa_item) ap;
    `uvm_component_utils(fa_monitor)
    function new(string name, uvm_component parent);
        super.new(name,parent);
        // Like C++, "this" just means the object in which this function is currently executing 
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Initialize my own ap to use later
        ap  = new("ap", this);
        // Grabbing the actual vif
        if(!uvm_config_db #(virtual fa_if)::get(this,"","vif",vif))`uvm_fatal("NOVIF", "vif not set")
    endfunction

    task run_phase(uvm_phase phase);
        fa_item item;
        forever begin
            #1ns
            item = fa_item::type_id::create("item");
            item.a = vif.a;
            item.b = vif.b;
            item.cin = vif.cin;
            item.s = vif.s;
            item.cout = vif.cout;
            ap.write(item);
        end
    endtask
endclass

// Scoreboard: the thing that actually tracks errors/pass rate
class fa_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fa_scoreboard)
    uvm_analysis_imp #(fa_item, fa_scoreboard) imp;
    function new(string name, uvm_component parent);
        super.new(name,parent);
        imp = new("imp", this);
    endfunction
    function void write(fa_item item);
        bit exp_s;
        bit exp_cout;
        exp_s = item.a ^ item.b ^ item.cin;
        exp_cout = (item.a & item.b) | (item.a & item.cin) | (item.b & item.cin);
        // Debug statement needs to be here since statements need to be after declarations. In VHDL, "begin" keyword avoids this confusion 
        $display("SCOREBOARD HIT: a=%0b b=%0b cin=%0b s=%0b cout=%0b", item.a, item.b, item.cin, item.s, item.cout);        
        if ((item.s !== exp_s) || (item.cout !== exp_cout)) 
        begin
            `uvm_error("FA", 
                        $sformatf("Mismatch a=%0b b=%0b cin=%0b exp=(%0b,%0b) got=(%0b,%0b)",
                        item.a, item.b, item.cin,
                        exp_s, exp_cout,
                        item.s, item.cout))
        end
    endfunction
endclass

// Agent: binds monitor, driver, sequencer together
class fa_agent extends uvm_agent;
    `uvm_component_utils(fa_agent)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    fa_sequencer seqr;
    fa_monitor monr;
    fa_driver driv;
    // This creates the driver, monitor, and sequencer in the agent
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seqr = fa_sequencer::type_id::create("seqr", this);
        monr = fa_monitor::type_id::create("monr", this);
        driv = fa_driver::type_id::create("driv", this);
    endfunction

    // Connects the sequencer to the driver
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driv.seq_item_port.connect(seqr.seq_item_export);
    endfunction

endclass

// Environment: binds the agents and scoreboards together
class fa_env extends uvm_env;
    `uvm_component_utils(fa_env)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    fa_agent agent;
    fa_scoreboard scbd;
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = fa_agent::type_id::create("agent", this);
        scbd = fa_scoreboard::type_id::create("scbd", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // connect scoreboard implementation to analysis with parent monitor with parent agent
        agent.monr.ap.connect(scbd.imp);
    endfunction

endclass

// Test: starts the sequences
class fa_test extends uvm_test;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    `uvm_component_utils(fa_test)

    fa_env env;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fa_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        fa_sequence seq;
        // increase # of objections. Phase ends with objection # is zero, ie drop_objection called on this
        phase.raise_objection(this);

        seq = fa_sequence::type_id::create("seq");
        // Start sequence with the sequencer contained in the agent in the env
        seq.start(env.agent.seqr);
        phase.drop_objection(this);
    endtask


endclass

// Top Level: so we can actually run the testbench because the entrypoint needs to be through a module
// Parameter/Ports left blank like VHDL TB entity dec
module fa_tb_top;
    
    // kinda like use namespace std in C++
    import uvm_pkg::*;
    
    // For util functions like uvm_object_utils
    `include "uvm_macros.svh"
    
    // Interface instance
    fa_if vif();
    
    // Dut instance
    fa dut (
        .a(vif.a),
        .b(vif.b),
        .cin(vif.cin),
        .s(vif.s),
        .cout(vif.cout)
    );

    // Little confusing
    initial begin 
        // Store the fa_if vif handle in the global dictionary uvm_config_db (UVM config database) for later retrieval
        uvm_config_db#(virtual fa_if)::set(
            null, // Start from root
            "*", // Visible everywhere
            "vif", // Config name
            vif // Actual value
        );
        run_test("fa_test");
    end
endmodule