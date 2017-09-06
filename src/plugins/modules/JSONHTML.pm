package JSONHTML;

#*************************************************************************
%explain = (
   'cispro' => 'Native was a cis-proline.',
   'glycine' => 'Native was a glycine which was adopting backbone torsions not allowed for other amino acids.',
   'surfacephobic' => 'Mutation introduces a hydrophobic amino acid on the surface.',
   'clash' => 'Mutation introduces an amino acid which clashes with its surroundings.',
   'hbonds' => 'Mutation disrupts hydrogen bonding.',
   'proline' => 'Mutation introduces a proline when native residue was in a conformation not accessible to proline.',
   'voids' => 'Mutation introduces a void in the protein core.',
   'binding' => 'Native residue was involved in a specific HBond or packing interaction with another protein chain or ligand.',
   'corephilic' => 'Mutation introduced a hydrophilic residue into the protein core.',
   'impact' => 'The site of the mutation is significantly conserved.',
   'sprotft' => 'The site of the mutation is annotated as a feature in UniProtKB/SwissProt.',
   'buriedcharge' => 'Mutation introduced a charged residue into the protein core.',
   'interface' => 'Native residue was in an interface.',
   'ssgeom' => 'Native residue was a cysteine involved in a disulphide bond.'
);

#*************************************************************************
sub ParseHBonds
{
    my(%results) = @_;
    my $para1 = "No problems identified";
    my $para2 = "The native residue was not involved in a hydrogen bond";

    if($results{'HBonds-BOOL'} eq "BAD")
    {
        $para1 = "The mutation disrupts a hydrogen bond.";
        $para2 = "The $results{'HBonds-ATOM'} of the native residue \
was forming a hydrogen bond with $results{'HBonds-PARTNER-ATOM'} of \
residue $results{'HBonds-PARTNER-RES'}. The replacement sidechain is \
unable to maintain this hydrogen bond.";
    }

    return($para1, $para2);
}

#*************************************************************************
sub ParseBinding
{
    my(%results) = @_;
    my $para1 = "No problems identified";
    my $para2 = "The residue was not involved in a specific binding interaction";
    if($results{'Binding-BOOL'} eq "BAD")
    {
        $para1 = "The native residue was involved in binding";
        $para2 = "A specific HBond or van der Waals interaction occurred with another protein or ligand";
    }

    return($para1, $para2);
}

#*************************************************************************
sub ParseBuriedCharge
{
    my(%results) = @_;
    my $para1 = "No problems identified";

    if($results{'BuriedCharge-BOOL'} eq "BAD")
    {
        $para1 = "The mutation resulted in introducing or removing a buried charge.";
    }

    my $para2 = "<b>Native residue charge: $results{'BuriedCharge-NATIVE-CHARGE'}</b><br />
               <b>Mutant residue charge: $results{'BuriedCharge-MUTANT-CHARGE'}</b><br />
               Relative accessibility of native residue: $results{'BuriedCharge-RELACCESS'}\%";

    return($para1, $para2);
}

#*************************************************************************
sub ParseVoids
{
    my(%results) = @_;

    my $para1 = "No problems identified";

    if($results{'Voids-BOOL'} eq "BAD")
    {
        $para1 = "The mutation introduced a large void.";
    }

    my $para2 = sprintf("After the mutation <b>the largest void was of size %.2f</b>.<br /> \
The largest void in the native was %.2f.<br /> \
90%% of proteins have no voids &gt;275, but we do not consider a large \
void to be damaging if the native structure had large voids.",$results{'Voids-MUTANT-LARGEST'},$results{'Voids-NATIVE-LARGEST'});

    return($para1, $para2);
}

#*************************************************************************
sub ParseSProtFT
{
    my(%results) = @_;
    my $para1 = "No problems identified";
    my $para2 = "The residue was not annotated as a \'feature\' in UniProtKB/SwissProt";
    if($results{'SProtFT-BOOL'} eq "BAD")
    {
        $para1 = "The residue is a UniprotKB/SwissProt \'feature\'.";
        $para2 = "This site was annotated as $results{'SProtFT-NAMES'}.";
    }

    return($para1, $para2);
}

#*************************************************************************
sub ParseSurfacePhobic
{
    my(%results) = @_;
    my ($para1, $para2);

    my $para1 = "No problems identified";
    if($results{'SurfacePhobic-BOOL'} eq "BAD")
    {
        $para1 = "The mutation introduced a hydrophobic sidechain onto the surface of the protein.";
    }
    my $para2 = "Native residue hydrophobicity: $results{'SurfacePhobic-NATIVE-HPHOB'}<br />
                 <b>Mutant residue hydrophobicity: $results{'SurfacePhobic-MUTANT-HPHOB'}</b><br />
                 Relative accessibility of native residue: $results{'SurfacePhobic-RELACCESS'}\%<br /><br />
                 Hydrophobicity values &lt;0 are hydrophilic and a threshold of 20\% relative accessibility is used to define a residue as on the surface.";

    return($para1, $para2);
}


#*************************************************************************
sub ParseInterface
{
    my(%results) = @_;
    my $para1 = "No problems identified";
    if($results{'Interface-BOOL'} eq "BAD")
    {
        $para1 = "The residue was involved in an interface";
    }

    my $para2 = sprintf("Interfaces are defined by a difference in solvent
    accessibility between a complex and the individual chain in the crystal structure.<br />
    In the complex, this residue had a relative accessability of $results{'Interface-RELACCESS'}%% 
    while the individual chain had an accessibility of $results{'Interface-RELACCESS-MOL'}%%, <b>a
    difference of %.3f%%</b>.<br />
    A difference of &gt;10%% is taken as indicative of an interface residue.<br />
    Interfaces may be with another protein chain or a ligand.",
    $results{'Interface-RELACCESS-MOL'} -
    $results{'Interface-RELACCESS'});

    return($para1, $para2);
}


#*************************************************************************
sub ParseGlycine
{
    my(%results) = @_;

    my $para1 = "No problems identified";
    if($results{'Glycine-BOOL'} eq "BAD")
    {
        $para1 = "The native residue was a glycine and was adopting a backbone conformation not accessible to the other amino acids.";
    }

    my $para2 = "The native residue was a $results{'Glycine-NATIVE'} not a Glycine";

    if($results{'Glycine-NATIVE'} eq "GLY")
    {
        $para2 = "The native residue was a Glycine<br />
                  Native phi angle: $results{'Glycine-PHI'}<br />
                  Native psi angle: $results{'Glycine-PSI'}<br />";

        if($results{'Glycine-NATIVE-BOOL'} eq "BAD")
        {
            $para2 = "The native residue was in an unfavourable conformation so the effect of the mutation has not been considered.<br /> ";
        }

        $para2 .= "Native pseudo-energy: $results{'Glycine-NATIVE-ENERGY'}<br />
                   ($results{'Glycine-NATIVE-THRESHOLD'} is a threshold above which the energy is considered \'bad\')<br />
                   <b>Mutant pseudo-energy: $results{'Glycine-MUTANT-ENERGY'}</b><br />
                   ($results{'Glycine-MUTANT-THRESHOLD'} is a threshold above which the energy is considered \'bad\')";
    }
    return($para1, $para2);
}


#*************************************************************************
sub ParseClash
{
    my(%results) = @_;
    my $para1 = "No problems identified";
    if($results{'Clash-BOOL'} eq "BAD")
    {
        $para1 = "The replacement sidechain leads to a clash with surrounding residues.";
    }
    my $para2 = "<b>The clash energy was $results{'Clash-ENERGY'}&nbsp;kcal/mol.</b><br /> 99\% of sidechains 
in real proteins have an energy less than 34.33&nbsp;kcal/mol.<br />Consequently energies 
&gt;34.33&nbsp;kcal/mol and &lt;50&nbsp;kcal/mol can be considered mild clashes, 
50-100&nbsp;kcal/mol medium clashes, &gt;100&nbsp;kcal/mol severe clashes. Note 
that clash energies can be extremely high (&gt;&gt;100000&nbsp;kcal/mol)";

    return($para1, $para2);
}


#*************************************************************************
sub ParseCisPro
{
    my(%results) = @_;
    my $para1 = "No problems identified";
    my $para2 = "The native residue was not a cis-proline";

    if($results{'CisPro-BOOL'} eq "BAD")
    {
        $para1 = "The native residue was a proline with a cis-peptide bond.";
        $para2 = "Normally only proline residues are observed with a cis-peptide bond before the amino acid. Consequently a mutation to another amino acid will be destabilizing";
    }

    return($para1, $para2);
}


#*************************************************************************
sub ParseProline
{
    my(%results) = @_;
    my $para1 = "No problems identified";

    if($results{'Proline-BOOL'} eq "BAD")
    {
        $para1 = "The mutation introduced a proline at a site where the backbone torsion angles could not accomodate a proline";
    }

    my $para2 = "The mutant residue was a $results{'Proline-MUTANT'} not a Proline";

    if($results{'Proline-MUTANT'} eq "PRO")
    {
        $para2 = "The mutant residue was a Proline<br />
                  Native phi angle: $results{'Proline-PHI'}<br />
                  Native psi angle: $results{'Proline-PSI'}<br />";

        if($results{'Proline-NATIVE-BOOL'} eq "BAD")
        {
            $para2 = "The native residue was in an unfavourable conformation so the effect of the mutation has not been considered.<br /> ";
        }

        $para2 .= "Native pseudo-energy: $results{'Proline-NATIVE-ENERGY'}<br />
                   ($results{'Proline-NATIVE-THRESHOLD'} is a threshold above which the energy is considered \'bad\')<br />
                   <b>Mutant pseudo-energy: $results{'Proline-MUTANT-ENERGY'}</b><br />
                   ($results{'Proline-MUTANT-THRESHOLD'} is a threshold above which the energy is considered \'bad\')";
    }


    return($para1, $para2);
}


#*************************************************************************
sub ParseCorePhilic
{
    my(%results) = @_;
    my $para1 = "No problems identified";

    if($results{'CorePhilic-BOOL'} eq "BAD")
    {
        $para1 = "The mutation introduces a hydrophilic residue into the core of the protein.";
    }
    my  $para2 = "Native residue hydrophobicity: $results{'CorePhilic-NATIVE-HPHOB'}<br />
                  Mutant residue hydrophobicity: $results{'CorePhilic-MUTANT-HPHOB'}<br />
                  Relative accessibility of native residue: $results{'CorePhilic-RELACCESS'}\%<br /><br />
                  Hydrophobicity values &lt;0 are hydrophilic.";

    return($para1, $para2);
}


#*************************************************************************
sub ParseImpact
{
    my(%results) = @_;

    my $para1 = "No problems identified";

    if($results{'Impact-BOOL'} eq "BAD")
    {
        $para1 = "The mutation was at a site flagged as \'highly conserved\'.";
    }
    my $para2 = sprintf("In an alignment of $results{'Impact-NSEQ'} functionally equivalent protein sequences,
                         <b>the conservation score at this position was %.2d%%.</b><br />
                         Analysis of the sequences in this alignment defined a threshold of %.2d%% as 
                         being significantly conserved.", 
                        $results{'Impact-CONSSCORE'} * 100,
                        $results{'Impact-THRESHOLD'} * 100);
    if($results{'Impact-NSEQ'} < 10)
    {
        $para2 .= "<br />Note that since there are &lt;10 sequences in the alignment, this result should be treated with caution!";
    }

    return($para1, $para2);
}


#*************************************************************************
sub ParseSSGeom
{
    my(%results) = @_;
    my $para1 = "No problems identified.";
    my $para2 = "The native residue was not a cysteine in a disulphide bond.";

    if($results{'SSGeom-BOOL'} eq "BAD")
    {
        $para1 = "The mutation disrupted a disulphide bond.";
        $para2 = "The native residue was involved in a disulphide bond.";
    }

    return($para1, $para2);
}




1;
