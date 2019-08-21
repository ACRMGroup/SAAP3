#-------------------------------------------------------------------------
sub WriteFASTAAsPIR
{
    my ($filename, $data) = @_;

    my $firstEntry = 1;

    my @records = split(/\n/, $data);

    if(open(my $FILE, ">$filename"))
    {
        foreach my $record (@records)
        {
            if($record =~ /^\>/)
            {
                if($firstEntry)
                {
                    $firstEntry = 0;
                }
                else
                {
                    print $FILE "*\n";
                }
                my @fields = split(/\|/, $record);
                printf $FILE ">P1;%s\n", $fields[1];
                print $FILE $fields[2];
            }
            else
            {
                print $FILE "\n$record";
            }
        }
        if(!$firstEntry)
        {
            print $FILE "*\n";
        }
        close $FILE;
    }
}




#-------------------------------------------------------------------------
# (\@sequences, \@sequenceIDs) = ReadPIR($pirFile);
sub ReadPIR
{
    my($pirFile) = @_;
    my $seq_counter = 0;
    my @sequences;
    my @sequenceIDs;
    my $seqLength = (-1);
    my $sequence = "";

    if(open( my $PIR, $pirFile ))
    {
        while( my $record = <$PIR> )
        {
            if($record =~ /^\>/)
            {
                my @fields = split(/\;/, $record);
                my $ac = $fields[1]; # We don't use this
                $record = <$PIR>; # The comment line
                @fields = split(/\s+/, $record);
                my $id = $fields[0];
                push @sequenceIDs, $id;

                if($sequence ne "")
                {
                    if(!($sequence =~ /\*/))
                    {
                        die "Illegal PIR format - missing *";
                    }
                    $sequence =~ s/[\s\*]//g;
                    push @sequences, $sequence;
                    $sequence = "";
                }
            }
            else
            {
                $sequence .= $record;
            }
        }

        if($sequence ne "")
        {
            if(!($sequence =~ /\*/))
            {
                die "Illegal PIR format - missing *";
            }
            $sequence =~ s/[\s\*]//g;
            push @sequences, $sequence;
        }

        close $PIR;
    }    
    return(\@sequences, \@sequenceIDs);
}    


#*************************************************************************
sub GetResidueAccessXXX
{
    my($pdbfile, $residueIn) = @_;
    my $xmasFile;

    $xmasFile = SAAP::GetXmasFile($pdbfile);

    # Grab the data
    my ($pResults, $pFields, $status) = XMAS::GetXMASData($xmasFile, "atoms");
    if($status)
    {
        return(0,0,$status);
    }

    # Find which field contains the residue accessibility
    my $resaccessField    = XMAS::FindField("residue.resaccess", $pFields);
    my $resaccessMolField = XMAS::FindField("residue.resaccess_mol", $pFields);
    my $chainField        = XMAS::FindField("chain.chain", $pFields);
    my $resnumField       = XMAS::FindField("residue.resnum", $pFields);
    # Extract what we need
    foreach my $record (@$pResults)
    {
        my $resaccess    = XMAS::GetField($record, $resaccessField);
        my $resaccessMol = XMAS::GetField($record, $resaccessMolField);
        my $chain        = XMAS::GetField($record, $chainField);
        my $resnum       = XMAS::GetField($record, $resnumField);

        my $residueNoDot = $chain . $resnum;
        $residueNoDot =~ s/\s+//g;
        my $residueDot = "$chain.$resnum";
        $residueDot =~ s/\s+//g;
        if(($residueNoDot eq $residueIn)||($residueDot eq $residueIn))
        {
            return($resaccess, $resaccessMol, 0);
        }
    }
    
    return(0,0,-1);
}


#*************************************************************************
sub GetXmasFileXXX
{
    my($pdbfile) = @_;
    my $xmasFile;

    # Work out the XMAS filename, creating the file if needed
    $pdbfile =~ /(.*\/)?(.*)\..*/;
    my $filestem = $2;
    if(-e "$config::xmasDir/$filestem.xmas")
    {
        $xmasFile = "$config::xmasDir/$filestem.xmas";
    }
    else
    {
        my $filename = $pdbfile;
        # Replace all / and . with _
        $filename =~ s/[\/\.]/_/g;

        $xmasFile = "$config::xmasCacheDir/$filename.xmas";
        if(! -e $xmasFile)
        {
            CreateXmasFile($pdbfile, $xmasFile);
        }
    }
    return($xmasFile);
}

#*************************************************************************
sub CreateXmasFile
{
    my($pdbfile, $xmasFile) = @_;

    my $tmpfile="/tmp/xmas_$$";

    # Convert PDB to XMAS
    `$config::xmasbindir/pdb2xmas                                        $pdbfile   $tmpfile.1 2>  $xmasFile.log`;
    # Solvent accessibility
    `$config::xmasbindir/solv     -r $config::pluginDataDir/radii.dat    $tmpfile.1 $tmpfile.2 2>> $xmasFile.log`;
    # Secondary structure
    `$config::xmasbindir/ss                                              $tmpfile.2 $tmpfile.3 2>> $xmasFile.log`;
    # HBonds
    `$config::xmasbindir/hb       -d $config::pluginDataDir/Explicit.pgp $tmpfile.3 $xmasFile  2>> $xmasFile.log`;

    # Cleanup
    unlink("$tmpfile.1");
    unlink("$tmpfile.2");
    unlink("$tmpfile.3");
}

