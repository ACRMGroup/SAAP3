#!/usr/bin/python3
import re

#------------------------------------------------------------------------
def read(key,configfile):
    """ Simple code to read from a Perl .pm config file. Rather limited
    at the moment! It will only work with lines of the form
    $x = 'xxxx';
    $x = "$y/xxxx';
    $x = "$y/$z/xxxx';
    $x = "$y$z/xxxx';
    (etc.)
    Double and inverted single inverted commas are treated identically

    Input:   key        - the name of the variable you want to obtain 
                          (no leading $)
             configfile - the Perl .pm module config file
    Returns: the expanded value of the variable

    19.01.22 Original   By: ACRM
    """
    configdata = []
    value      = ''
    with open(configfile, 'r') as configfp:
        for line in configfp:
            configdata.append(line)
        value = expand(key, configdata)

    return(value)

#------------------------------------------------------------------------
def expand(key, configdata):
    """ Recursive routine to obtain the value of the key from the configdata
        Called by read()

    Input:   key        - the name of the variable you want to obtain 
                          (no leading $)
             configfile - the Perl .pm module config file
    Returns: the expanded value of the variable

    19.01.22 Original   By: ACRM
    """
    regex = re.compile("\$" + key + "\s*=(.*)")
    for line in configdata:
        match = regex.search(line)
        if(match):
            value = match.group(1)
            value = clean(value)
            while('$' in value):
                variablePart = findvariable(value)
                valuePart    = expand(variablePart, configdata)
                value        = value.replace('$'+variablePart, valuePart)
            return(value)

    return('')
    
    
#------------------------------------------------------------------------
def findvariable(string):
    """ Finds the name of the first scalar variable introduced by a $
        from a string. The variable must be followed by a / or a $ for
        another variable.

    Input:   string    The string to search for a variable
    Returns:           The name of the variable (no leading $)

    19.01.22 Original   By: ACRM
    """
    regex = re.compile("\$(.+?)[/\$]")
    match = regex.search(string)
    if(match):
        value = match.group(1)
        return(value)

    regex = re.compile("\$(.+?)$")
    match = regex.search(string)
    if(match):
        value = match.group(1)
        return(value)

    return('')
    
#------------------------------------------------------------------------
def clean(value):
    """ Cleans up a value by stripping all spaces, inverted commas and 
        colons

    Input:   value     The value to clean up
    Returns:           The cleaned value

    19.01.22 Original   By: ACRM
    """
    for char in " \"';":
        value = value.replace(char, "")
    return(value)
            

#------------------------------------------------------------------------
""" Test code """

if __name__ == '__main__':
    value = read('sprotCacheDir','config.pm')
    print(value)

    
