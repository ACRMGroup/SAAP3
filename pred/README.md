SAAPPred
========

Individual full prediction
--------------------------

The basic way of running the prediction script is as follows - 
all you need to do is specify the mutation on the command line:

```
saapPred Q9Y6Y9 Arg 56 Gly
```
This will do everything including running the structural analysis.

Individual prediction after having done structural analysis
-----------------------------------------------------------

If you have already run the structural analysis, and have the JSON
file, you can avoid running the structural analysis again by telling
the script the name of the JSON file that had the structural analysis:

```
saapPred -json=Q9Y6Y9_Arg_56_Gly.json Q9Y6Y9 Arg 56 Gly
```
(of course you have to specify the full path to the JSON file, so, if
you aren't in the right directory, you would need to do something like:

```
saapPred -json=$(HOME)/mutations/Q9Y6Y9_Arg_56_Gly.json Q9Y6Y9 Arg 56 Gly
```

Since this is a little long-winded, there is a simpler way of doing
this which extracts the mutation information from the name of the JSON
file. (Clearly files must be named in this standard format):

```
saapJSONPred Q9Y6Y9_Arg_56_Gly.json
```

Prediction on lots of JSON files
--------------------------------

You can simply run the script on multiple files using a BASH script:

```
for file in *.json
do
   saapJSONPred $file >$file.out
done
```

Examples
--------
Here are some other examples:

```
cd bin
saapPred Q92838 I 360 N >out
saapPred -v -printjson Q92838 I 360 N >out

saapPred -v -json=jsonFile Q92838 I 360 N >out
saapPred -v -printpdb Q92838 I 360 N >out
saapPred -v -printall Q92838 I 360 N >out
saapPred -v -printall -printjson Q92838 I 360 N >out

