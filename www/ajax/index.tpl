[% INCLUDE "$[WWW]/header.tt"
   localcss = 1
   bodyattrib = " onload='refresh();'"
%]
[% INCLUDE "$[WWW]/main_menu.tt"
   mutations = " id='mcurrent'"
%]
[% INCLUDE "$[WWW]/mutations/mutations_menu.tt"
   saap = " id='current'"
%]

<script type='text/javascript' src='ajax.js'></script>
<script type='text/javascript'>
function refresh()
{
   if(document.inputform.uppdbup.checked)
   {
      ActivateUP();
   }
   else
   {
      ActivatePDB();
   }
}
function ActivateUP()
{
   var upElement1  = document.getElementById("up1");
   var upElement2  = document.getElementById("up2");
   var upElement3  = document.getElementById("up3");
   var upElement4  = document.getElementById("up4");
   var pdbElement1 = document.getElementById("pdb1");
   var pdbElement2 = document.getElementById("pdb2");
   var pdbElement3 = document.getElementById("pdb3");
   var pdbElement4 = document.getElementById("pdb4");

   upElement1.style.display='inline';
   upElement2.style.display='inline';
   upElement3.style.display='inline';
   upElement4.style.display='inline';
   pdbElement1.style.display='none';
   pdbElement2.style.display='none';
   pdbElement3.style.display='none';
   pdbElement4.style.display='none';
}
function ActivatePDB()
{
   var upElement1  = document.getElementById("up1");
   var upElement2  = document.getElementById("up2");
   var upElement3  = document.getElementById("up3");
   var upElement4  = document.getElementById("up4");
   var pdbElement1 = document.getElementById("pdb1");
   var pdbElement2 = document.getElementById("pdb2");
   var pdbElement3 = document.getElementById("pdb3");
   var pdbElement4 = document.getElementById("pdb4");

   upElement1.style.display='none';
   upElement2.style.display='none';
   upElement3.style.display='none';
   upElement4.style.display='none';
   pdbElement1.style.display='inline';
   pdbElement2.style.display='inline';
   pdbElement3.style.display='inline';
   pdbElement4.style.display='inline';
}
</script>

<h1>SAAPdap/SAAPpred - Single Amino Acid Polymorphism data analysis
  pipeline and prediction</h1>

<p>SAAPdap allows you to run the SAAP mutation analysis pipeline to
examine the likely local structural effects of a mutation.
Consequently it can only be used where a structure is known for the
protein of interest.</p>

<p>You have the choice of entering a mutation for a UniProt sequence
(in which case the server will find the appropriate PDB protein
structures) or analyzing a mutation in a specified PDB file.
</p>

<p><b>Note</b> that if you specify a mutation in a UniProt sequence,
the web server will only analyze a maximum of <b>three structures</b>
that represent your sequence. In future we will allow users to
register to analyze all structures.</p>

<p><b>To run SAAPpred, you must run SAAPdap first!</b></p>

<form name='inputform' action='' style='background: #cccccc; padding: 10px 10px 1px 10px;'>

   <p style='display: none;'>
      <input type='radio' name='uppdb' id='uppdbup'  value='up' checked='checked' onclick='ActivateUP();'/>UniProt
      <input type='radio' name='uppdb' id='uppdbpdb' value='pdb' onclick='ActivatePDB();'/>PDB
   </p>

   <table>
      <colgroup>
         <col class='formlabel' />
         <col class='formbox' />
      </colgroup>

      <tr><td><span id='up3'>UniProt Accession</span>
              <span id='pdb3' style='display:none;'>PDB Code</span></td>
          <td><input name='ac' id='ac' type='text' /></td>
          <td class='exampleinput'>e.g. <span id='up1'>P12883</span>
                                        <span id='pdb1' style='display:none;'>4db1</span></td>
      </tr>
      <tr><td>Native Residue</td>
          <td><input name='native' id='native' type='text' /></td>
          <td class='exampleinput'>e.g. ser</td></tr>
      <tr><td><span id='up4'>Residue Number</span>
              <span id='pdb4' style='display:none'>Chain label and residue number</span></td>
          <td><input name='resnum' id='resnum' type='text' /></td>
          <td class='exampleinput'>e.g. <span id='up2'>242</span>
                                        <span id='pdb2' style='display:none;'>A242</span></td>
      </tr>
      <tr><td>Mutant Residue</td>
          <td><input name='mutant' id='mutant' type='text' /></td>
          <td class='exampleinput'>e.g. glu</td>
      </tr>
   </table>

   <div id='submit' style='display:inline;'>
      <p><input type='button' value='Submit' onclick='SubmitRequest()' />
         <input type='reset' value='Clear' />
      </p>
   </div>
</form>

<p><i>Please note that the structural analysis of your mutation will be cached to speed
up future access. These results may be shared with third parties.</i></p>

<p><b>The analysis (particularly of voids in large proteins) is
<i>slow</i> and can take several minutes! Please be patient!</b></p>

<div id='throbber' style='display:none;'><p><img src='throbber.gif' alt='WAIT'/>Please wait...</p></div>

<div id='results' style='background: #eeeeee; padding: 10px 10px 1px 10px;'>
    <p>Progress on the analysis will appear here...</p>
    <p><b>Note</b> Some mobile browsers (such as the default Android
       browser) will not submit this page. If this progress box 
       does not update, switch to a browser such as Opera-Mini.
    </p>
</div>

[% INCLUDE "$[WWW]/footer.tt" %]
