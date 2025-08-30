/*******************************************************************/
/*                                                                 */
/* This file is a standard linker script for a Zynq-7000 device.   */
/*                                                                 */
/*******************************************************************/

MEMORY
{
   ps7_ddr_0_S_AXI_BASEADDR : ORIGIN = 0x100000, LENGTH = 0x3FF00000
   ps7_ram_0_S_AXI_BASEADDR : ORIGIN = 0x0, LENGTH = 0x30000
   ps7_ram_1_S_AXI_BASEADDR : ORIGIN = 0xFFFF0000, LENGTH = 0xFE00
}

/* Specify the default entry point to the program */

ENTRY(_boot)

/* Define the sections, and where they are mapped in memory */

SECTIONS
{
.text : {
   *(.text)
   *(.text.*)
   *(.gnu.linkonce.t.*)
} > ps7_ddr_0_S_AXI_BASEADDR

.rodata : {
   __rodata_start = .;
   *(.rodata)
   *(.rodata.*)
   *(.gnu.linkonce.r.*)
   __rodata_end = .;
} > ps7_ddr_0_S_AXI_BASEADDR

.sdata2 : {
   __sdata2_start = .;
   *(.sdata2)
   *(.sdata2.*)
   *(.gnu.linkonce.s2.*)
   __sdata2_end = .;
} > ps7_ddr_0_S_AXI_BASEADDR

.sbss2 : {
   __sbss2_start = .;
   *(.sbss2)
   *(.sbss2.*)
   *(.gnu.linkonce.sb2.*)
   __sbss2_end = .;
} > ps7_ddr_0_S_AXI_BASEADDR

.data : {
   __data_start = .;
   *(.data)
   *(.data.*)
   *(.gnu.linkonce.d.*)
   __data_end = .;
} > ps7_ddr_0_S_AXI_BASEADDR

.got : {
   *(.got)
} > ps7_ddr_0_S_AXI_BASEADDR

.got1 : {
   *(.got1)
} > ps7_ddr_0_S_AXI_BASEADDR

.got2 : {
   *(.got2)
} > ps7_ddr_0_S_AXI_BASEADDR

.ctors : {
   __CTOR_LIST__ = .;
   ___CTORS_LIST___ = .;
   KEEP (*crtbegin.o(.ctors))
   KEEP (*(EXCLUDE_FILE(*crtend.o) .ctors))
   KEEP (*(SORT(.ctors.*)))
   KEEP (*(.ctors))
   __CTOR_END__ = .;
   ___CTORS_END___ = .;
} > ps7_ddr_0_S_AXI_BASEADDR

.dtors : {
   __DTOR_LIST__ = .;
   ___DTORS_LIST___ = .;
   KEEP (*crtbegin.o(.dtors))
   KEEP (*(EXCLUDE_FILE(*crtend.o) .dtors))
   KEEP (*(SORT(.dtors.*)))
   KEEP (*(.dtors))
   __DTOR_END__ = .;
   ___DTORS_END___ = .;
} > ps7_ddr_0_S_AXI_BASEADDR

.fixup : {
   __fixup_start = .;
   *(.fixup)
   __fixup_end = .;
} > ps7_ddr_0_S_AXI_BASEADDR

.eh_frame : {
   *(.eh_frame)
} > ps7_ddr_0_S_AXI_BASEADDR

.jcr : {
   *(.jcr)
} > ps7_ddr_0_S_AXI_BASEADDR

.fini : {
   *(.fini)
} > ps7_ddr_0_S_AXI_BASEADDR

.preinit_array : {
   . = ALIGN(4);
   __preinit_array_start = .;
   KEEP (*(SORT(.preinit_array.*)))
   KEEP (*(.preinit_array))
   __preinit_array_end = .;
} > ps7_ddr_0_S_AXI_BASEADDR

.init_array : {
   . = ALIGN(4);
   __init_array_start = .;
   KEEP (*(SORT(.init_array.*)))
   KEEP (*(.init_array))
   __init_array_end = .;
} > ps7_ddr_0_S_AXI_BASEADDR

.fini_array : {
   . = ALIGN(4);
   __fini_array_start = .;
   KEEP (*(SORT(.fini_array.*)))
   KEEP (*(.fini_array))
   __fini_array_end = .;
} > ps7_ddr_0_S_AXI_BASEADDR

.bss : {
   __bss_start = .;
   *(.bss)
   *(.bss.*)
   *(COMMON)
   . = ALIGN(4);
   __bss_end = .;
} > ps7_ddr_0_S_AXI_BASEADDR

_end = .;
}

/* Stacks and heap */

_stack_end = ALIGN(4);
_stack = _stack_end + 1024;
_heap_start = _stack;
_heap_end = 0x3F000000;
_heap_size = _heap_end - _heap_start;
```
