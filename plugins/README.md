SAAP Plugins
============

All plugins run by taking a PDB file and a mutation as input and
produce JSON as output.

Plugins need to adhere to the following requirements:

Inputs / Running
----------------

- Plugins **must** be executable (i.e. have a valid shebang line and be
  made executable using `chmod +x plugin`).
- Plugins **must** take inputs on the command line in the form
  `[chain]resnum[insert] newaa pdbfile` i.e. a residue identifier in
  the PDB file, the mutant amino acid (in one or three-letter code)
  and the PDB file to be analyzed.
- Plugins **should** cache their results to speed up future analysis of
  the same mutation.
- Plugins that cache their results **must** have a `-force` command line
  flag to force calculation even if the cached result is available.
- Plugins **should** take a `-info` command line flag to print a 1-line
  summary of what they are doing written in the present
  continuous. e.g. '*Checking whether the new sidechain clashes with
  its surroundings*'.
- Plugins **should** take a `-h` command line flag to print version,
  copyright, usage and function information.
- Plugins **can** take a `-nocache` command line flag to prevent
  cacheing (mostly for debugging)

The location of files and directories (e.g. where the cache is) should
be read from the config file (`config.pm` in the directory above).

Output
------

Output is a snippet of JSON.

- Each tag **must** start with the plugin name and a dash (e.g. `Voids-`)
- The actual property **must** be in capitals (e.g. `"SProtFT-FEATURES"`)
- Every plugin **must** generate a `"xxx-BOOL"` tag with a value of `"OK"`
  or `"BAD"`. (e.g. `"SProtFT-BOOL": "OK"` or `"Impact-BOOL": "BAD"`)

If you need verbose output from a plugin for debugging purposes, it
should be switched on using a command line flag of `-vv`, not `-v`
since this would be passed from `pipeline.pl` and the resulting output
would interrupt the verbose output from `pipeline.pl`

Examples
--------

### impact.pl

```
[amartin@home plugins]$ ./impact.pl -h

impact.pl V1.1 (c) 2011-2014, UCL, Dr. Andrew C.R. Martin
Usage: impact.pl [-vv] [-nocache] [-force] [chain]resnum[insert] newaa pdbfile
       (newaa maybe 3-letter or 1-letter code)
       -vv      Verbose
       -force   Force calculation even if results are cached
       -nocache Do not cache results

Does ImPACT conservation calculations for the SAAP server.
```

```
[amartin@home plugins]$ ./impact.pl -info

Analyzing conservation at this position in the sequence
```

Output:

```
{"Impact-BOOL": "OK", "Impact-NSEQ": "247", "Impact-THRESHOLD": "0.98", "Impact-CONSSCORE": "0.949619230358117"}
```

### voids.pl

```
[amartin@home plugins]$ ./voids.pl -h

voids.pl V3.2 (c) 2011-2020, UCL, Prof. Andrew C.R. Martin

Usage: voids.pl [-force] [chain]resnum[insert] newaa pdbfile
       -force   Force calculation even if results are cached
       (newaa maybe 3-letter or 1-letter code)

Does void calculations for the SAAP server.
```

```
[amartin@home plugins]$ ./voids.pl -info

Analyzing voids - this will take some time! (Ignore any sort/broken pipe errors!!!)
```

Output:

```
{"Voids-MUTANT": [340.499,163.114,147.921,138.011,91.629,89.946,42.776,39.299,34.790,34.440], "Voids-MUTANT-LARGEST": "340.499000", "Voids-BOOL": "OK", "Voids-NATIVE": [340.499,163.114,147.921,138.011,91.629,89.946,42.776,39.299,34.790,34.440], "Voids-NATIVE-LARGEST": "340.499000"}
```

Notes
-----

- mmdb.py  - Not worth doing as it's not updated
- pqs.py
