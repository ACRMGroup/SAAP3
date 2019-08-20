var gRequest = null;

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
      var processID = gRequest.responseText;

      sequenceElement.innerHTML = "<pre>ProcessID: "+processID+"</pre>";
   } 
} 

function updatePage() 
{ 
   if (gRequest.readyState==4 || gRequest.readyState=="complete")
   { 
      var sequenceElement = document.getElementById("absequence");
      var throbberElement = document.getElementById("throbber");

      var sequence = gRequest.responseText;

      sequenceElement.innerHTML = sequence;
      throbberElement.style.display = 'none';
   } 
} 
