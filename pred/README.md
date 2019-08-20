cd bin
./saapPred.pl Q92838 I 360 N >out
./saapPred.pl -v -printjson Q92838 I 360 N >out

./saapPred.pl -v -json=jsonFile Q92838 I 360 N >out
./saapPred.pl -v -printpdb Q92838 I 360 N >out
./saapPred.pl -v -printall Q92838 I 360 N >out
./saapPred.pl -v -printall -printjson Q92838 I 360 N >out

# First of all you want to run your sorting script to move the
# JSON files that have no analysis done into a separate folder.

# Next get everything set up as before to be able to run the
# SAAP scripts - I've made this a bit easier:
source ~martin/SAAP/server/setup.sh

# The basic way of running the prediction script is as follows - 
# all you NEED to do is specify the mutation on the command line:
$PBIN/saapPred.pl Q9Y6Y9 Arg 56 Gly
# This will do everything including running the structural analysis
# that you have done already

# However, since you have already run the structural analysis, you
# can avoid running it all again by telling the script the name of
# the JSON file that had the structural analysis:
$PBIN/saapPred.pl -json=Q9Y6Y9_Arg_56_Gly.json Q9Y6Y9 Arg 56 Gly

# Of course you have to specify the full path to the JSON file, so, if
# you aren't in the right directory (mutations4 in this case), you
# would need to do something like
$PBIN/saapPred.pl -json=/home/bsm/zcbtg74/mutations4/Q9Y6Y9_Arg_56_Gly.json Q9Y6Y9 Arg 56 Gly

# Clearly you don't want to type a command like that for every file,
# so I have create a little Perl script in $PBIN which will take the
# name of a JSON file and run this command for you. Hence all you have
# to do is something like
$PBIN/saapJSONPred.pl Q9Y6Y9_Arg_56_Gly.json
# or
$PBIN/saapJSONPred.pl /home/bsm/zcbtg74/mutations4/Q9Y6Y9_Arg_56_Gly.json

# To save the results in a file, rather than them going to the screen,
# you would use the standard Unix redirection with a > sign:
$PBIN/saapJSONPred.pl Q9Y6Y9_Arg_56_Gly.json > Q9Y6Y9_Arg_56_Gly.json.out

# Now you still have the problem that you don't want to type this in
# however many hundred times for each of your files.
# You can get around this quite easily by using a small "shell
# script". For example, to analyze all the files in the mutations4
# directory, you can change to that directory:
cd ~/mutations4/
# and then process all the files by doing:
for file in *.json
do
   $PBIN/saapJSONPred.pl $file >$file.out
done

# If you put those 4 lines in a file called predAll.sh in your home
# directory, and made that script executable:
chmod a+x ~/predAll.sh
# then you could run that script in each of your results directories: 
cd ~/mutations3/
~/predAll.sh

# Since it will take some time to run, you probably want to do it in
# the background as with the structural analysis:
cd ~/mutations3/
nohup nice -10 ~/predAll.sh &>predAll.log &

# As before, use the command
top
# to see what programs are running (and press 'q' to quit)








