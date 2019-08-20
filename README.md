SAAPdap/SAAPpred
================

Installation
============

Compiling and installing the code
---------------------------------
1. Ensure you have the following packages installed system wide:

- R
- perl LWP and LWP::Protocol::https modules
- glibc-static

You can do this by running `./preinstall.sh`

2. Ensure you have an uncompressed mirror of the PDB installed; you
can use `ftpmirror` from http://github.com/AndrewCRMartin/bioscripts
for this purpose.

3. Modify `config.pm` as required - see the example `config.pm.*`
files as examples.

4. Run `./install.pl` to compile and install the software

Interface install
-----------------

1. In addition to the standard code install, ensure you have the
following packages installed system wide:

- perl JSON module
- wkhtmltopdf

You can do this by running `./preinstall.sh`

2. Run `./install.pl interface` to install the interface

Directories and files present in the main distribution folder
=============================================================

Files
-----

- **config.pm.xxx** Example config files
- **install.pl** Install script
- **README.md** This README file
- **preinstall.sh** System install script
- **util.pm** Utilities used by the install script

Directories
-----------

- **data/** Data files
- **lib/** Perl and R library files
- **packages/** C program packages
- **plugins/** The analysis plugins
- **pred/** The prediction code
- **src/** The analysis programs
- **www/** The web interface


-----------------------------------------------------------------

Programs and scripts
--------------------

### init.sh

Initiation script - sets paths etc. - Must be run from current
directory. See also `setup.sh`

### setup.sh

Preferred way of setting up all paths etc. As `init.sh` but can be
called from anywhere


### pipeline.pl

Basic SAAPdap pipeline program. You would run this on an individual
mutation on an individual PDB file.

Use `pipeline.pl -h` for help

### uniprotPipeline.pl

Run SAAPdap pipeline when you have just a UniProt code - it will find
all matching PDB files. Calls `pipeline.pl`

Use `uniprotPipeline.pl -h` for help

### multiUniprotPipeline.pl

Run SAAPdap pipeline on a set of UniProt mutations in a file. Calls
`uniprotPipeline.pl`

Use `multiUniprotPipeline.pl -h` for help

### json2html.pl

Run on a single .json file to generate an HTML file. 

No further help available

### multiJson2html.pl

Takes the name of a directory containing a set of JSON files and
converts them all to HTML and creates an HTML index file summarizing
all the mutations in the directory.

Use `multiJson2html.pl -h` for help

### makePDF.pl

Makes a PDF version of all HTML pages in a specified directory

### delVoidCache.pl


### dump_fosta.pl


----------------------------------------------------------------------


### Moving the install

    rm cache/sprot/sprot.idx*
    rm plugins/data/specsim.idx*

### Dump the fosta database

    ./dump_fosta.sh
    rm ./plugins/data/specsim.idx*

### Clean the cache

    rm -rf cache/*

*or for a specific PDB file:*

    rm cache/*/*PDBID*


-------------------------------------------------------------------------

Changes to Make
===============

TODO:

- Finish commenting

- Write PQS plugin

- Add to Interface code information on what the interacting protein/ligand is
Also to CATH and Pfam annotations

- If the SwissProt cache is out of date then make use of the web based
version automatically while rebuilding the cache in the background.

- Code needs to check native residue in the PDB file being examined and
warn if it isn't what is expected. e.g. G6PD 1qki has the Arg459->Leu
mutation

- Main pipeline code needs to do 1->3 conversion of amino acid names

- Prediction of interface binding energy:
   http://www.bioinf.manchester.ac.uk/intcalc/

- SAAP::CheckRes() should check that the residue is an amino acid and
that it's not CA-only (e.g. P01583 2ila A Asp 137 Asn)

- Uniprot Code should check that the specified native residue is correct

- Need to check for mutant structures and display in interface

- Plugin to find sites adjacent to active and binding sites. Use
SwissProt annotation, CSA and Benoit's ligsite.

- Modify SwissProt indexing so that it is not done automatically in the
code. If the index is out of date, or if it returns nothing
automatically use the web service.

- Check that code relying on the SwissProt index fails correctly if it
can't update the index.

- CorePhilic and SurfacePhobic should probably use the same cutoffs for
defining hydrophobicity and these should be moved into a config file.

- `./pipeline.pl -u=O00238 -c 6 S 3mdy`
gives:
`{"SAAP-ERROR": "UniProt accession code (O00238) not known in PDBSWS"}`
In fact residues 174-500 of the UniProt entry map to PDB so this
should say: "Residue 6 of UniProt accession code (O00236) not found in
PDBSWS"

- `./clashes.pl A680 ILE /acrm/data/pdb/pdb2wl1.ent`
gives:
`Error: (mutmodel) Missing atoms. No search
{"Clash-ENERGY": "", "Clash-BOOL": "OK"}`
Residue has multiple occupancies throughout (including
backbone). Selection of the best atoms then seems to mess up atom
order and finding the atoms

- Hopefully can drop FixIE() from json2html.pl and multiJson2html.pl

- Some plugins (e.g. clashes.pl) don't work properly with blank chain names and just freeze.

- On local PDB file, rather than PDB code, Impact gives a 'BAD' result rather than error.

------------------------------------------------------------------------

Changes Done
============

- 23.09.11 Make all plugins accept -v and get the pipeliner to pass it into 
         the plugins
- 23.09.11 Split FOSTA.pm into FOSTA.pm and UNIPROT.pm
- 23.09.11 sprotft should use the REST interface to PDBSWS with common modules
- 23.09.11 sprotft.pl should use the UNIPROT module to get sequence
         data. This should also be modified to deal with the date
         checking issues currently only done in sprotft.pl
- 23.09.11 Split stuff from config that shouldn't be in there
- 02.11.11 Pipeline program checks to ensure that the residue is found
- 02.11.11 Pipeline program takes an option that the residue number is as
         specified in UniProt so it looks up the PDB number from PDBSWS
- 04.11.11 Top level pipeline program should do some wrapping of the JSON 
         into a single JSON record
- 29.11.11 Improve main index page from multiJson2html.pl
- 07.12.11 json2html.pl is giving an error HTML page even if only one of
         the analyses in the contained PDB file has an error
- 09.12.11 BuriedCharge, Interface and SurfacePhobic don't deal 
         correctly with numeric chain names of the form 1.518 e.g. Run
         ./uniprotPipeline.pl Q13153 L 514 V >People/frances/batch1/data/Q13153_L_514_V.json
         (or ./pipeline 1.514 V /acrm/data/pdb/pdb2hy8.ent)
- 09.12.11 Summary page from multiJson2html.pl should generate a colour
         based on the number of structures with a 'bad' analysis
         rather than being red for any bad.
- 13.12.11 improve the getresol program to get non-crystallography
         method information more accurately
- 16.12.11 CorePhillic is doing accessibility on the complex not the 
         single protein! (Also SurfacePhobic)
- 23.01.12 specsim lookup is now a web service
- 24.01.12 Write config::CreateXmasFile()
- 07.03.12 CorePhilic should give relative accessibility in the same way that
         SurfacePhobic does
- 07.03.12 AVP can return <10 voids, so code should pad top 10 voids with zeros
         e.g.

         1c26 - 4voids
         1sfc,1soh ---- 3 voids
         3bua,1zbq  ----0 voids
         1c25---4 voids
         1sal --- 7 voids
         1iie -- 6 voids
         1p0t -- 8 Voids
         1z6w -- 9 voids

- 26.03.12 When plugins create cache directories they need to set 
         permissions for anyone to write to that directory
- 20.06.12 Fixed Internet Explorer compatibility problem with
         getElementsByClassName()



