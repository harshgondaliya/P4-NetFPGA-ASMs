## P4/NetFPGA-based Implementation of IP Address Anti-Spoofing Mechanisms

### Introduction
This repository contains the source code files required to realize the following six IP address anti-spoofing mechanisms (ASMs) on NetFPGA SUME using [P4->NetFPGA Workflow](https://github.com/NetFPGA/P4-NetFPGA-public/wiki/Workflow-Overview):
1. Network Ingress Filtering ([NIF](https://tools.ietf.org/html/rfc2827))
2. Loose Reverse Path Forwarding ([RPF-Loose](https://tools.ietf.org/html/rfc3704))
3. Strict Reverse Path Forwarding ([RPF-Strict](https://tools.ietf.org/html/rfc3704))
4. Feasible Path Reverse Path Forwarding ([RPF-Feasible](https://tools.ietf.org/html/rfc3704))
5. Spoofing Prevention Method ([SPM](https://ieeexplore.ieee.org/document/1497921))  
6. Source Address Validation Improvement Solution for DHCP ([SAVI-DHCP](https://tools.ietf.org/html/rfc7513))

`l2-baseline` implements Layer 2 forwarding functionality, whereas `l3-baseline` implements Layer 3 forwarding functionality.

### Source Code Files
[P4->NetFPGA Workflow steps](https://github.com/NetFPGA/P4-NetFPGA-public/wiki/Workflow-Overview#workflow-steps) use the following three source code files to generate a bitstream that can be loaded into NetFPGA SUME:

`<program_name>.p4` - P4 source code that defines the packet processing behavior of P4/NetFPGA-based switch.

`commands.txt` - Lists the entries that are to be filled in P4 match-action tables.

`gen_testdata.py` - Specifies test cases to verify the packet processing behavior of P4/NetFPGA-based switch. 

### Citation Details
This work is presented at [EuroP4'20: 3rd P4 Workshop in Europe](https://p4.org/events/2020-12-01-euro-p4-workshop/). When referencing this work, please use the following citation:

Harsh Gondaliya, Ganesh C. Sankaran, Krishna M. Sivalingam, "Comparative Evaluation of IP Address Anti-Spoofing Mechanisms using a P4/NetFPGA-based Switch", EuroP4'20: 3rd P4 Workshop in Europe.
[https://doi.org/10.1145/3426744.3431320](https://doi.org/10.1145/3426744.3431320)

### Acknowledgements
This work was supported by a DST-FIST grant (SR/FST/ETI-423/2016) from
Government of India (2017-2022) and Mid-Career Institute Research and
Development Award (IRDA) from IIT Madras (2017-2020).
The authors (Harsh Gondaliya, Ganesh C. Sankaran, Krishna M. Sivalingam) are happy to acknowledge the support and discussions of Prof. B. Amutha, Head of CSE Department, SRMIST, Kattankulathur Campus, Chennai.
