OUTPUT_ARCH( "riscv" )
ENTRY(rvtest_init)

SECTIONS
{
  . = 0x00000000;
  .text : { *(.text.init) *(.text) }
  
  . = 0x00200000;
  .data : { *(.data) }
  .bss : { *(.bss) }
  
  . = 0x80001000;
  .tohost : { *(.tohost) }
  
  _end = .;
}
