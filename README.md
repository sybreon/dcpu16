DCPU-16 Microprocessor
======================

Copyright (C) 2012 Shawn Tan <shawn.tan@sybreon.com>.
All Rights Reserved.

Released under LGPL3.

Introduction
------------

This project is a hardware implementation of the DCPU-16
microprocessor designed by Marcus Persson (@notch) for his new game
0x10c.

The core is written entirely in synthesisable Verilog RTL.

Pipeline
--------

It has an 8-stage integer pipeline, split into two parts, each with
4-stages. Each stage can run within a single clock cycle. Therefore,
the maximum effective rate for executing an instruction is 4-clock
cycles.

* Fetch (FE) - fetches instructions from memory.
* Decode (DE) - decodes the instruction.
* Calc A (EA) - calculates the effective address for A.
* Calc B (EB) - calculates it for B.
* Load A (LA) - loads operand A.
* Load B (LB) - loads operand B.
* Execute (EX) - executes the instruction.
* Store A (SA) - stores operand A.


Synthesis
---------

Currently synthesises on a Spartan 6 to about:

* 500 Slices @ 149 MHz

Status
------

It is *not* FPGA proven, yet.