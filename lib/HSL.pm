package HSL;
#*************************************************************************
#
#  Program:    
#  File:       hsl.c
#  
#  Version:    V1.0
#  Date:       23.06.94
#  Function:   Convert HSL to RGB
#  
#  Copyright:  (c) Dr. Andrew C. R. Martin 1994
#  Author:     Dr. Andrew C. R. Martin
#  Address:    Biomolecular Structure & Modelling Unit,
#              Department of Biochemistry & Molecular Biology,
#              University College,
#              Gower Street,
#              London.
#              WC1E 6BT.
#  EMail:      andrew@bioinf.org.uk
#              andrew.martin@ucl.ac.uk
#              
#*************************************************************************
#
#  This program is not in the public domain, but it may be copied
#  according to the conditions laid out in the accompanying file
#  COPYING.DOC
#
#  The code may be modified as required, but any modifications must be
#  documented so that the person responsible can be identified. If someone
#  else breaks this code, I don't want to be blamed for code that does not
#  work! 
#
#  The code may not be sold commercially or included as part of a 
#  commercial product except as described in the file COPYING.DOC.
#
#*************************************************************************
#
#  Description:
#  ============
#  Converts HSL colour model (described by values between 0.0 and 1.0)
#  to RGB colour model (also 0.0--1.0)
#
#*************************************************************************
#
#  Usage:
#  ======
#
#*************************************************************************
#
#  Revision History:
#  =================
#
#************************************************************************/


#************************************************************************/
sub hexWarningColour
{
    my ($level) = @_;

    my ($r,$g,$b) = warningColour($level);
    my $hexString = sprintf "\#%02x%02x%02x", 255*$r, 255*$g, 255*$b;
    return($hexString);
}

#************************************************************************/
# Returns a colour between green and red depending on an input value
# between 0 and 1
sub warningColour
{
    my ($level) = @_;

    $level = 1 if($level > 1);
    my $h = (1-$level)/3;

    return(hsl2rgb($h, 1.0, 1.0));
}

#************************************************************************/
#  void hsl2rgb($hue, $saturation, $luminance)
#  -------------------------------------------
#  Input:   REAL  hue            HSL hue value (0.0--1.0)
#           REAL  saturation     HSL saturation value (0.0--1.0)
#           REAL  luminance      HSL luminance value (0.0--1.0)
#  Output:  REAL  red            RGB red value (0.0--1.0)
#           REAL  green          RGB green value (0.0--1.0)
#           REAL  blue           RGB blue value (0.0--1.0)
#
#  Converts an HSL colour value to an RGB colour value
#
#  07.12.11 Original    By: ACRM
sub hsl2rgb
{
    my($hue, $saturation, $luminance) = @_;
    my($rising, $falling, $invSat, $sixth);
    my($red,$green,$blue);
   
    # Find which sixth of the hue spectrum we are in
    $sixth   = int(6.0 * $hue);

    $rising  = ($hue - ($sixth / 6.0)) * 6.0;
    $falling = 1.0 - $rising;

    $invSat  = 1.0 - $saturation;


    if(($sixth == 0)||($sixth==6))
    {
        $red   = 1.0;
        $green = $rising;
        $blue  = 0.0;
    }
    elsif($sixth == 1)
    {
        $red   = $falling;
        $green = 1.0;
        $blue  = 0.0;
    }
    elsif($sixth == 2)
    {
        $red   = 0.0;
        $green = 1.0;
        $blue  = $rising;
    }
    elsif($sixth == 3)
    {
        $red   = 0.0;
        $green = $falling;
        $blue  = 1.0;
    }
    elsif($sixth == 4)
    {
        $red   = $rising;
        $green = 0.0;
        $blue  = 1.0;
    }
    elsif($sixth == 5)
    {
        $red   = 1.0;
        $green = 0.0;
        $blue  = $falling;
    }

    $red   *= $luminance;
    $green *= $luminance;
    $blue  *= $luminance;

    $red   += (($luminance-($red))   * $invSat);
    $green += (($luminance-($green)) * $invSat);
    $blue  += (($luminance-($blue))  * $invSat);

    return($red,$green,$blue);
}

#************************************************************************/
1;
