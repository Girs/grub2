#! /bin/sh
#
# Copyright (C) 2005,2009  Free Software Foundation, Inc.
#
# This gensymlist.sh is free software; the author
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, to the extent permitted by law; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.

# Read source code from stdin and detect command names.

module=$1

grep -v "^#" | sed -n \
 -e "/grub_register_command *( *\"/{s/.*( *\"\([^\"]*\)\".*/\1: $module/;p;}" \
 -e "/grub_register_extcmd *( *\"/{s/.*( *\"\([^\"]*\)\".*/*\1: $module/;p;}" \
 -e "/grub_register_command_p1 *( *\"/{s/.*( *\"\([^\"]*\)\".*/*\1: $module/;p;}"

