var gRequest = null;
var gProcessID = null;
var gWaitType = null;


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
   var url="./analyze.cgi?sprotid="+sprotid+"&amp;native="+native+"&amp;resnum="+resnum+"&amp;mutant="+mutant;
   var throbberElement = document.getElementById("throbber");
   throbberElement.style.display = 'inline';
   gRequest.open("GET",url,true);
   gRequest.onreadystatechange=getProcessID;
   gRequest.send(null);
}

function getProcessID() 
{ 
   if (gRequest.readyState==4 || gRequest.readyState=="complete")
   { 
      var sequenceElement = document.getElementById("absequence");
      gProcessID = gRequest.responseText;

      sequenceElement.innerHTML = "<pre>ProcessID: "+gProcessID+"</pre><div id='progress'></div>";

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

      if(content.indexOf("END") >= 0) // Come to end of updates
      {
         var throbberElement = document.getElementById("throbber");
         throbberElement.style.display = 'none';
      }
      else
      {
         WaitForUpdateResults();
      }
   } 
} 
