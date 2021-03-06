//
// Copyright (c) 2017 Stephen Ibanez
// All rights reserved.
//
// This software was developed by Stanford University and the University of Cambridge Computer Laboratory 
// under National Science Foundation under Grant No. CNS-0855268,
// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
// as part of the DARPA MRC research programme.
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
// license agreements.  See the NOTICE file distributed with this work for
// additional information regarding copyright ownership.  NetFPGA licenses this
// file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
// "License"); you may not use this file except in compliance with the
// License.  You may obtain a copy of the License at:
//
//   http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@
//


#include <core.p4>
#include <sume_switch.p4>

#define IPV4_TYPE 0x0800

const bit<8> SPM_PORT = 0b0000001;

// standard Ethernet header
header Ethernet_h { 
    bit<48> dstAddr; 
    bit<48> srcAddr; 
    bit<16> etherType;
}

// IPv4 header without options
header IPv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> tos; 
    bit<16> totalLen; 
    bit<16> id; 
    bit<3> flags;
    bit<13> fragOffset; 
    bit<8> ttl;
    bit<8> protocol; 
    bit<16> hdrChecksum; 
    bit<32> srcAddr; 
    bit<32> dstAddr;
}

// List of all recognized headers
struct Parsed_packet { 
    Ethernet_h ethernet; 
    IPv4_h ip; 
}

// user defined metadata: can be used to shared information between
// TopParser, TopPipe, and TopDeparser 
struct user_metadata_t {
    bit<16> spm_key;
}

// digest data to be sent to CPU if desired. MUST be 256 bits!
struct digest_data_t {
    bit<256>  unused;
}

// Parser Implementation
@Xilinx_MaxPacketRegion(16384)
parser TopParser(packet_in b, 
                 out Parsed_packet p, 
                 out user_metadata_t user_metadata,
                 out digest_data_t digest_data,
                 inout sume_metadata_t sume_metadata) {
    state start {
        b.extract(p.ethernet);
	    user_metadata.spm_key = 0;
        digest_data.unused = 0;
        transition select(p.ethernet.etherType) {
            IPV4_TYPE: parse_ipv4;
            default: reject;
        }
    }
    state parse_ipv4 {
        b.extract(p.ip);
        transition accept;
    }
}    

// match-action pipeline
control TopPipe(inout Parsed_packet p,
                inout user_metadata_t user_metadata, 
                inout digest_data_t digest_data, 
                inout sume_metadata_t sume_metadata) { 
    
    action mark_spm_key(bit<16> key) {
        p.ip.id = key;
    }

    action get_spm_key(bit<16> key) {
        user_metadata.spm_key = key;
    }

    action ipv4_forward(bit<48> dstAddr, bit<8> port) {
        sume_metadata.dst_port = port;
        p.ethernet.srcAddr = p.ethernet.dstAddr;
        p.ethernet.dstAddr = dstAddr;
        p.ip.ttl = p.ip.ttl - 1;
    }

    action drop(){
    	sume_metadata.drop = 1;
    }

    table nw_out_ternary {
        key = { p.ip.srcAddr: ternary;
		        p.ip.dstAddr: ternary; }
        actions = {
	        mark_spm_key;	
            NoAction;
        }
        size = 64;
        default_action = NoAction;
    }
    
    table nw_in_ternary {
        key = { p.ip.srcAddr: ternary;
        		p.ip.dstAddr: ternary; }
        actions = {
    	    get_spm_key;	
            NoAction;
        }
        size = 64;
        default_action = NoAction;
    }

    table ipv4_ternary {
        key = { p.ip.dstAddr: ternary; }
        actions = {
            ipv4_forward;
            drop;
        }
        size = 64;
        default_action = drop;
    }
    apply {
        if(p.ip.isValid()){ // Packet is entering an AS
            if((sume_metadata.src_port == SPM_PORT) && (nw_in_ternary.apply().hit) && (p.ip.id != user_metadata.spm_key)){
                sume_metadata.drop = 1; // if source-destination ASes are SPM members and incoming packet is spoofed
            }
		else {  			
			ipv4_ternary.apply(); // if source-destination ASes are not SPM members, BUT we need to perform Layer 3 forwarding
		}                         // if source-destination ASes are SPM members and the packet is non-spoofed, then need to perform Layer 3 forwarding  
		
        // Packet is leaving/exiting an AS
        if((sume_metadata.dst_port == SPM_PORT)) {
 			nw_out_ternary.apply(); // if source-destination AS are SPM members, then mark outgoing packets with SPM key 		
 		}
	}
  }
}

// Deparser Implementation
@Xilinx_MaxPacketRegion(16384)
control TopDeparser(packet_out b,
                    in Parsed_packet p,
                    in user_metadata_t user_metadata,
                    inout digest_data_t digest_data, 
                    inout sume_metadata_t sume_metadata) { 
    apply {
        b.emit(p.ethernet); 
        b.emit(p.ip);
    }
}


// Instantiate the switch
SimpleSumeSwitch(TopParser(), TopPipe(), TopDeparser()) main;

