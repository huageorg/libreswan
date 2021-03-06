#!/usr/bin/perl
#
# Generates oid.h and oid.c out of oid.txt
#
# Copyright (C) 2003-2004 Andreas Steffen, Zuercher Hochschule Winterthur
# Copyright (C) 2014 Tuomo Soini <tis@foobar.fi>
# Copyright (C) 2014 D. Hugh Redelmeier <hugh@mimosa.com>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.  See <http://www.fsf.org/copyleft/gpl.txt>.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
$fswancopy="Copyright (C) 2003-2004 Andreas Steffen, Zuercher Hochschule Winterthur";
$copyright="Copyright (C) 2014 Tuomo Soini <tis\@foobar.fi>";
$automatic="This file has been generated by the script lib/libswan/oid.pl";
$warning="Do not edit manually!";

print "oid.pl generating ../../include/oid.h and oid.c\n";

# Generate oid.h

open(OID_H,  ">../../include/oid.h")
    or die "could not open '../../include/oid.h': $!";

print OID_H "/*\n",
	    " * Object identifiers (OIDs) used by Libreswan\n",
	    " *\n",
	    " * ", $fswancopy, "\n",
	    " * ", $copyright, "\n",
	    " *\n",
	    " * ", $automatic, "\n",
	    " * ", $warning, "\n",
	    " */\n\n",
	    "typedef struct {\n",
	    "\tunsigned char octet;\n",
	    "\tunsigned char down;\t/* bool */\n",
	    "\tunsigned short next;\n",
	    "\tconst char *name;\n",
	    "} oid_t;\n",
	    "\n",
            "extern const oid_t oid_names[];\n",
	    "\n",
	    "#define OID_UNKNOWN\t\t\t(-1)\n";

# parse oid.txt

open(SRC,  "<oid.txt")
    or die "could not open 'oid.txt': $!";

$counter = 0;
$max_name = 0;
$max_order = 0;

while ($line = <SRC>)
{
    next if ($line =~ m/^\h*$/);	# ignore empty line
    next if ($line =~ m/^#/);	# ignore comment line

    $line =~ m/^( *?)(0x[0-9a-fA-F]{2})\s+(".*?")[ \t]*?([\w_]*?)\Z/
    	or die "malformed line: $line";

    @order[$counter] = length($1);
    @octet[$counter] = $2;
    @name[$counter] = $3;

    if (length($1) > $max_order)
    {
	$max_order = length($1);
    }
    if (length($3) > $max_name)
    {
	$max_name = length($3);
    }
    if (length($4) > 0)
    {
	printf OID_H "#define %s%s%d\n", $4, "\t" x ((39-length($4))/8), $counter;
    }
    $counter++;
}

close SRC;
close OID_H;

# Generate oid.c

open(OID_C, ">oid.c")
    or die "could not open 'oid.c': $!";

print OID_C "/*\n",
	    " * List of some useful object identifiers (OIDs)\n",
	    " *\n",
	    " * ", $fswancopy, "\n",
            " * ", $copyright, "\n",
	    " *\n",
	    " * ", $automatic, "\n",
	    " * ", $warning, "\n",
	    " */\n",
	    "#include \"oid.h\"\n",
	    "\n",
            "const oid_t oid_names[] = {\n",
	    "\t/* octet, down, next, name */\n";

for ($c = 0; $c < $counter; $c++)
{
    $next = 0;

    for ($d = $c+1; $d < $counter && @order[$d] >= @order[$c]; $d++)
    {
	if (@order[$d] == @order[$c])
	{
	    @next[$c] = $d;
	    last;
	}
    }

    printf OID_C "\t{ %s%s,%s%d, %3d, %s%s }%s  /* %3d */\n"
	,' '  x @order[$c]
	, @octet[$c]
	, ' ' x (1 + $max_order - @order[$c])
	, @order[$c+1] > @order[$c]
	, @next[$c]
	, @name[$c]
	, ' ' x ($max_name - length(@name[$c]))
	, $c != $counter-1 ? "," : " "
	, $c;
}

print OID_C "};\n" ;
close OID_C;
