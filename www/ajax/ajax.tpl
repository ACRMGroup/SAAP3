var gRequest   = null;   // HTTPRequest passed between main 
                         // call and async routines
var gProcessID = null;   // ProcessID for the analysis - also 
                         // used for temp directory containing results
var gRedirect  = "index.html";    // Filename in URL /tmp/gProcessID to which 
                                  // we redirect on completion
var gServer    = "$[SERVER]"; // Server name - NO TRAILING /
var gTmpURL    = "$[TMPURL]"; // Temp URL, must start and end with /

function createRequest() {
   var req = null;
   
   try 
   {
       req = new XMLHttpRequest();
   } 
   catch (trywindow) 
   {
      try
      {
         req = window.createRequest();
      }
      catch (trymicrosoft) 
      {
         try 
         {
            req = new ActiveXObject("Msxml2.XMLHTTP");
         }
         catch (othermicrosoft) 
         {
            try 
            {
               req = new ActiveXObject("Microsoft.XMLHTTP");
            } 
            catch (failed) 
            {
               req = null;
            }
         }
      }
   }

   return(req);
}

function GetUPPDBRadioButton()
{
   for(var i=0; i<document.inputform.uppdb.length; i++)
   {
      if (document.inputform.uppdb[i].checked)
      {
         return(document.inputform.uppdb[i].value);
      }
   }
}

// return the value of the radio button that is checked
// return an empty string if none are checked, or
// there are no radio buttons
function getCheckedValue(radioObj) 
{
   if(!radioObj)
   {
      return "";
   }
   var radioLength = radioObj.length;
   if(radioLength == undefined)
   {
      if(radioObj.checked)
      {
         return radioObj.value;
      }
      else
      {
         return "";
      }
   }
   for(var i = 0; i < radioLength; i++) 
   {
      if(radioObj[i].checked) 
      {
         return radioObj[i].value;
      }
   }
   return "";
}

function SubmitRequest()
{
   gRequest = createRequest();
   if (gRequest==null)
   {
      alert ("Browser does not support HTTP Request");
      return;
   } 

   var ac      = document.getElementById("ac").value;
   // We have to call this nat rather than native to get Chrome to work - native confuses the URL :-S
   var nat     = document.getElementById("native").value;
   var resnum  = document.getElementById("resnum").value;
   var mutant  = document.getElementById("mutant").value;
   var uppdb   = GetUPPDBRadioButton();

   var throbberElement = document.getElementById("throbber");
   throbberElement.style.display = 'inline';
   var submitElement = document.getElementById("submit");
   submitElement.style.display = 'none';

   var url="./submit.cgi?uppdb="+uppdb+"&amp;ac="+ac+"&amp;native="+nat+"&amp;resnum="+resnum+"&amp;mutant="+mutant;
//   alert(url);
   gRequest.open("GET",url,true);
   gRequest.onreadystatechange=getProcessID;

   gRequest.send(null);
}

function getProcessID() 
{ 
   if (gRequest.readyState==4 || gRequest.readyState=="complete")
   { 
      var sequenceElement = document.getElementById("results");
      gProcessID = gRequest.responseText;
      var url = gServer+gTmpURL+gProcessID+"/";

      sequenceElement.innerHTML = "<p>The process ID for your analysis is: "+gProcessID+"</p><p>If you do not wish to wait for the results now, you will be able to access them at<br /><b>"+url+"</b><br />when the run is complete.</p><div id='progress'><pre>Progress on the analysis will appear here...</pre></div>";

      WaitForUpdateResults();
   } 
} 

function WaitForUpdateResults()
{
   gRequest = createRequest();
   if (gRequest==null)
   {
      alert ("Browser does not support HTTP Request");
      return;
   } 
   var url="./monitor.cgi?processid="+gProcessID;
   gRequest.open("GET",url,true);
   gRequest.onreadystatechange=updatePage;
   gRequest.send(null);
}

function updatePage() 
{ 
   if (gRequest.readyState==4 || gRequest.readyState=="complete")
   { 
      var progressElement = document.getElementById("progress");
      var content = gRequest.responseText;

      progressElement.innerHTML = "<pre>"+content+"</pre>";

      if(content.indexOf("__EOF__") >= 0) // Come to end of updates
      {
//         Don't need to remove the throbber as we redirect to a new page
//         var throbberElement = document.getElementById("throbber");
//         throbberElement.style.display = 'none';
         var newURL = gTmpURL+gProcessID+"/"+gRedirect;
//         location.replace(newURL); // This doesn't put the query page in the history
         window.location=newURL;
      }
      else
      {
         WaitForUpdateResults();
      }
   } 
} 

