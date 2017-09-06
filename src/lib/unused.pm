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


