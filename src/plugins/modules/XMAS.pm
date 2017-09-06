package XMAS;
#*************************************************************************
#
#   Program:    
#   File:       XMAS.pm
#   
#   Version:    V1.0
#   Date:       18.07.11
#   Function:   Simplified XMAS parser
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin 2011
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   EMail:      andrew@bioinf.org.uk
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
# use XMAS;
# my ($pResults, $pFields, $status) = XMAS::GetXMASData("p3hfl.xmas", "atoms");
#
# foreach my $result (@$pResults)
# {
#     print "$result\n";
# }
#
# foreach my $field (@$pFields)
# {
#     print "$field ";
# }
# print "\n";
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   18.07.11 Original   By: ACRM
#
#*************************************************************************
@ErrorMessage = 
(
 "OK",
 "Cannot open XMAS file",
 "Failed to find XMAS data type",
 "No XMAS data found for specified file and data type"
);

#*************************************************************************
# GetXmasData($file, $type)
# -------------------------
# Input:   $file     File to read
#          $type     Data type to be read from the file
# Returns: $pData    Data lines (reference to...)
#          $pFields  Data field names (reference to...)
#          $status   Status can be: 1 - Can't open file
#                                   2 - Failed to find data type
#                                   3 - No data found
#                                   0 - Success
# Access status text with XMAS::ErrorMessage[$status]
#
sub GetXMASData
{
    my($file,$type) = @_;

    my @fields;
    my @results;
    open(my $fh, $file) || return(undef, undef, 1);

    @fields = doReadXMASHeader($fh, $type);
    if(!@fields)
    {
        return(undef, undef, 2);
    }

    @results = doReadXMASData($fh, $type, @fields);
    if(!@results)
    {
        return(undef, \@fields, 3);
    }

    close $fh;

    return(\@results, \@fields, 0);
}


#*************************************************************************
sub doReadXMASData
{
    my($fh, $type, @fields) = @_;
    my $inData = 0;

    my %appends = ();
    my @results = ();
    my $line;
    my $gotData = 0;

    while($line = <$fh>)
    {
        chomp $line;

        if($line =~ /<DATA TYPE=(.*)>/)
        {
            if($1 eq $type)
            {
                $inData = 1;
            }
        }
        elsif($line =~ /<\/DATA>/)
        {
            if($gotData)
            {
                last;
            }
            $inData = 0;
        }
        elsif($inData)
        {
            $gotData = 1;
            # If in an append line, store the information in the appends hash
            if($line =~ /<(.*)>(.*)<\/.*>/)
            {
                my $append = $1;
                my $tmp    = $2;
                $tmp =~ s/^\s+//;
                $tmp =~ s/\s+$//;
                my (@data) = split(/\s+/, $tmp);
                my $fieldCount = 0;

                foreach my $field (@fields)
                {
                    if($field =~ /^${append}\./)
                    {
                        $appends{$field} = $data[$fieldCount++];
                    }
                }
            }
            else # Normal data line
            {
                # Add the append data onto the end of the line
                foreach my $field (@fields)
                {
                    if($field =~ /\./)
                    {
                        $line .= " $appends{$field}";
                    }
                }
                push @results, $line;
            }
        }
    }
    return(@results);
}


#*************************************************************************
sub doReadXMASHeader
{
    my($fh, $type) = @_;

    my $inHeader = 0;
    my $inType = 0;
    my $thisType;
    my @fields;
    my $append = "";
    my $gotData = 0;

    while(my $line=<$fh>)
    {
        if($line =~ /<HEADER>/)
        {
            $inHeader = 1;
        }
        elsif($line =~ /<\/HEADER>/)
        {
            last;
        }
        elsif($inHeader)
        {
            if($line =~ /<FORMAT\s+TYPE=(.*)>/)
            {
                $thisType = $1;
                if($thisType eq $type)
                {
                    $inType = 1;
                    $append = "";
                }
            }
            elsif($line =~ /<\/FORMAT/)
            {
                $inType = 0;
            }
            elsif($inType)
            {
                if($line =~ /<.*>(.*)<\/.*>/)
                {
                    my $field = $1;
                    push @fields, "$append$field";
                }
                elsif($line =~ /<APPEND\s+TYPE=(.*)>/)
                {
                    $append = "$1.";
                }
            }
        }
    }

    return(@fields);
}

sub FindField
{
    my($fieldName, $pFields) = @_;

    my $fieldNum = 0;
    foreach my $field (@$pFields)
    {
        return($fieldNum) if($field eq $fieldName);
        $fieldNum++;
    }
    return(-1);
}

sub GetField
{
    my($record, $fieldNum) = @_;

    if($fieldNum < 0)
    {
        return(undef);
    }

    $record =~ s/^\s+//;
    $record =~ s/\s+$//;
    my @fields = split(/\s+/, $record);
    my $data = $fields[$fieldNum];
    # Replace dots from start of string
    for(my $i=0; $i<length($data); $i++)
    {
        if(substr($data,$i,1) eq ".")
        {
            substr($data,$i,1) = " ";
        }
        else
        {
            last;
        }
    }
    # Replace dots from end of string
    for(my $i=length($data)-1; $i>=0; $i--)
    {
        if(substr($data,$i,1) eq ".")
        {
            substr($data,$i,1) = " ";
        }
        else
        {
            last;
        }
    }

    $data =~ s/\|SP\|/ /g;
    return($data);
}



1;
