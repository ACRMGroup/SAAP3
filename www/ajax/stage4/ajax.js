var gRequest   = null;   // HTTPRequest passed between main 
                         // call and async routines
var gProcessID = null;   // ProcessID for the analysis - also 
                         // used for temp directory containing results
var gRedirect  = "index.html";    // Filename in URL /tmp/gProcessID to which 
                                  // we redirect on completion
var gServer    = "http://www.bioinf.org.uk"; // Server name - NO TRAILING /

function createRequest() {
   var req = null;
   
   try {
      req = new XMLHttpRequest();
   } catch (trymicrosoft) {
      try {
         req = new ActiveXObject("Msxml2.XMLHTTP");
      } catch (othermicrosoft) {
         try {
            req = new ActiveXObject("Microsoft.XMLHTTP");
         } catch (failed) {
            req = null;
         }
      }
   }

   return(req);
}

function DisplayPage()
{
   gRequest = createRequest();
   if (gRequest==null)
   {
      alert ("Browser does not support HTTP Request");
      return;
   } 
   var sprotid = document.getElementById("sprotID").value;
   var native  = document.getElementById("native").value;
   var resnum  = document.getElementById("resnum").value;
   var mutant  = document.getElementById("mutant").value;

   var throbberElement = document.getElementById("throbber");
   throbberElement.style.display = 'inline';
   var submitElement = document.getElementById("submit");
   submitElement.style.display = 'none';

   var url="./analyze.cgi?sprotid="+sprotid+"&amp;native="+native+"&amp;resnum="+resnum+"&amp;mutant="+mutant;
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
      var url = gServer+"/tmp/"+gProcessID+"/";

      sequenceElement.innerHTML = "<p>The process ID for your analysis is: "+gProcessID+"</p><p>If you do not wish to wait for the results now, you will be able to access them at<br /><b>"+url+"</b><br />when the run is complete.</p><p>Note that the analysis can take several minutes - especially on larger proteins.</p><div id='progress'><pre>Progress on the analysis will appear here...</pre></div>";

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
         var newURL = "/tmp/"+gProcessID+"/"+gRedirect;
//         location.replace(newURL); // This doesn't put the query page in the history
         window.location=newURL;
      }
      else
      {
         WaitForUpdateResults();
      }
   } 
} 
