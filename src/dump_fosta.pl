#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    dump_fosta
#   File:       dump_fosta.pl
#   
#   Version:    V3.2
#   Date:       20.08.20
#   Function:   Dumps species similarity information from Lisa's FOSTA 
#               database into a flat file for use in ImPACT calculations
#   
#   Copyright:  (c) UCL / Prof. Andrew C. R. Martin 2011-2020
#   Author:     Prof. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   EMail:      andrew@bioinf.org.uk
#               andrew.martin@ucl.ac.uk
#   Web:        http://www.bioinf.org.uk/
#               
#               
#*************************************************************************
#
#   This program is not in the public domain, but it may be copied
#   according to the conditions laid out in the accompanying file
#   COPYING.DOC
#
#   The code may be modified as required, but any modifications must be
#   documented so that the person responsible can be identified. If 
#   someone else breaks this code, I don't want to be blamed for code 
#   that does not work! 
#
#   The code may not be sold commercially or included as part of a 
#   commercial product except as described in the file COPYING.DOC.
#
#*************************************************************************
#
#   Description:
#   ============
#
#*************************************************************************
#
#   Usage:
#   ======
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0  05.09.11 Original   By: ACRM
#   V1.1  05.10.18 Updated for reorganization of code
#   V3.2  20.08.20 Bumped for second official release
#
#*************************************************************************
my $dbname="mcmillan";
my $sql="select * from specsim";
my $host="acrm8";
my $tmp="./plugins/data/specsim.tmp";
my $dump="./plugins/data/specsim.dump";

`psql -d $dbname -c "$sql" -h $host >$dump`;
`\mv -f $tmp $dump`;
