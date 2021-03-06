/*
 *  GRUB  --  GRand Unified Bootloader
 *  Copyright (C) 2003,2004,2005,2007  Free Software Foundation, Inc.
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

#ifndef KERNEL_MACHINE_TIME_HEADER
#define KERNEL_MACHINE_TIME_HEADER	1

#include <grub/symbol.h>

#define GRUB_TICKS_PER_SECOND	18

/* Return the real time in ticks.  */
grub_uint32_t EXPORT_FUNC (grub_get_rtc) (void);

#endif /* ! KERNEL_MACHINE_TIME_HEADER */
