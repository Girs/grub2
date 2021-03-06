/* -*-Asm-*- */
/*
 *  GRUB  --  GRand Unified Bootloader
 *  Copyright (C) 2009  Free Software Foundation, Inc.
 *
 *  GRUB is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  GRUB is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with GRUB.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <grub/boot.h>
#include <grub/machine/boot.h>

	.text
	.align	4
	.globl	_start
_start:
	/* OF CIF entry point arrives in %o4 */
pic_base:
	call	boot_continue
	 mov	%o4, CIF_REG

	. = _start + GRUB_BOOT_MACHINE_VER_MAJ
boot_version:		.byte	GRUB_BOOT_VERSION_MAJOR, GRUB_BOOT_VERSION_MINOR

	/* The offsets to these locations are defined by the
	 * GRUB_BOOT_MACHINE_foo macros in include/grub/sparc/ieee1275/boot.h,
	 * and grub-setup uses this to patch these next three values as needed.
	 *
	 * The boot_path will be the OF device path of the partition where the
	 * rest of the GRUB kernel image resides.  kernel_sector will be set to
	 * the location of the first block of the GRUB kernel, and
	 * kernel_address is the location where we should load that first block.
	 *
	 * After loading in that block we will execute it by jumping to the
	 * load address plus the size of the prepended A.OUT header (32 bytes).
	 */
boot_path:
	. = _start + GRUB_BOOT_MACHINE_KERNEL_SECTOR
kernel_sector:		.xword 2
kernel_address:		.word  GRUB_BOOT_MACHINE_KERNEL_ADDR

prom_finddev_name:	.asciz "finddevice"
prom_chosen_path:	.asciz "/chosen"
prom_getprop_name:	.asciz "getprop"
prom_stdout_name:	.asciz "stdout"
prom_write_name:	.asciz "write"
prom_bootpath_name:	.asciz "bootpath"
prom_open_name:		.asciz "open"
prom_seek_name:		.asciz "seek"
prom_read_name:		.asciz "read"
prom_exit_name:		.asciz "exit"
grub_name:		.asciz "GRUB "
#define GRUB_NAME_LEN	5

	.align	4

prom_open_error:
	GET_ABS(prom_open_name, %o2)
	call	console_write
	 mov	4, %o3
	/* fallthru */

prom_error:
	GET_ABS(prom_exit_name, %o0)
	/* fallthru */

	/* %o0: OF call name
	 * %o1: input arg 1
	 */
prom_call_1_1:
	mov	1, %g1
	ba	prom_call
	 mov	1, %o5

	/* %o2: message string
	 * %o3: message length
	 */
console_write:
	GET_ABS(prom_write_name, %o0)
	mov	STDOUT_NODE_REG, %o1
	/* fallthru */

	/* %o0: OF call name
	 * %o1: input arg 1
	 * %o2: input arg 2
	 * %o3: input arg 3
	 */
prom_call_3_1:
	mov	3, %g1
	mov	1, %o5
	/* fallthru */

	/* %o0: OF call name
	 * %g1: num inputs
	 * %o5: num outputs
	 * %o1-%o4: inputs
	 */
prom_call:
	stx	%o0, [%l1 + 0x00]
	stx	%g1, [%l1 + 0x08]
	stx	%o5, [%l1 + 0x10]
	stx	%o1, [%l1 + 0x18]
	stx	%o2, [%l1 + 0x20]
	stx	%o3, [%l1 + 0x28]
	stx	%o4, [%l1 + 0x30]
	jmpl	CIF_REG, %g0
	 mov	%l1, %o0

boot_continue:
	mov	%o7, PIC_REG		/* PIC base */
	sethi	%hi(SCRATCH_PAD), %l1	/* OF argument slots */

	/* Find the /chosen node so we can fetch the stdout handle,
	 * and thus perform console output.
	 *
	 * chosen_node = prom_finddevice("/chosen")
	 */
	GET_ABS(prom_finddev_name, %o0)
	GET_ABS(prom_chosen_path, %o1)
	call	prom_call_1_1
	 clr	%o2

	ldx	[%l1 + 0x20], CHOSEN_NODE_REG
	brz	CHOSEN_NODE_REG, prom_error

	/* getprop(chosen_node, "stdout", &buffer, buffer_size) */
	 GET_ABS(prom_getprop_name, %o0)
	mov	4, %g1
	mov	1, %o5
	mov	CHOSEN_NODE_REG, %o1
	GET_ABS(prom_stdout_name, %o2)
	add	%l1, 256, %o3
	mov	1024, %o4
	call	prom_call
	 stx	%g1, [%l1 + 256]

	lduw	[%l1 + 256], STDOUT_NODE_REG
	brz,pn	STDOUT_NODE_REG, prom_error

	/* write(stdout_node, "GRUB ", strlen("GRUB ")) */
	 GET_ABS(grub_name, %o2)
	call	console_write
	 mov	GRUB_NAME_LEN, %o3

	/* Open up the boot_path, and use that handle to read the
	 * first block of the GRUB kernel image.
	 *
	 * bootdev_handle = open(boot_path)
	 */
	GET_ABS(prom_open_name, %o0)
	GET_ABS(boot_path, %o1)
	call	prom_call_1_1
	 clr	%o2

	ldx	[%l1 + 0x20], BOOTDEV_REG
	brz,pn	BOOTDEV_REG, prom_open_error

	/* Since we have 64-bit cells, the high cell of the seek offset
	 * is zero and the low cell is the entire value.
	 *
	 * seek(bootdev, 0, *kernel_sector << 9)
	 */
	 GET_ABS(prom_seek_name, %o0)
	mov	BOOTDEV_REG, %o1
	clr	%o2
	LDX_ABS(kernel_sector, 0x00, %o3)
	call	prom_call_3_1
	 sllx	%o3, 9, %o3

	/* read(bootdev, *kernel_address, 512) */
	GET_ABS(prom_read_name, %o0)
	mov	BOOTDEV_REG, %o1
	LDUW_ABS(kernel_address, 0x00, %o2)
	call	prom_call_3_1
	 mov	512, %o3

	LDUW_ABS(kernel_address, 0x00, %o2)
	jmpl	%o2, %o7
	 nop

1:	ba,a	1b

	. = _start + GRUB_BOOT_MACHINE_CODE_END

/* the last 4 bytes in the sector 0 contain the signature */
	.word	GRUB_BOOT_MACHINE_SIGNATURE
