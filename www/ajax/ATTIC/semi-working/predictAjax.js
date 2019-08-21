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
   } catch (trywindow) {
      try {
         req = window.createRequest();
      } catch (trymicrosoft) {
         try {
            req = new ActiveXObject("Msxml2.XMLHTTP");
         }  catch (othermicrosoft) {
            try {
               req = new ActiveXObject("Microsoft.XMLHTTP");
            } catch (failed) {
               req = null;
            }
         }
      }
   }

   return(req);
}

function SubmitPredict(dir, jsonFile, urlPath)
{
//   alert("DIR: " + dir + "| JSONFILE: " + jsonFile + "| URLPATH: " + urlPath);
   
   gRequest = createRequest();
   if (gRequest==null)
   {
      alert ("Browser does not support HTTP Request");
      return;
   } 

   var throbberElement = document.getElementById("throbber");
   throbberElement.style.display = 'inline';
   var predictButton = document.getElementById("PredictButton");
   predictButton.disabled = true;

   var url=urlPath + "/predictSubmit.cgi?dir="+dir+"&amp;json="+jsonFile;
//   alert(url);
   gRequest.open("GET",url,true);

   gRequest.onreadystatechange=updatePage;
   gRequest.send(null);
}


function updatePage() 
{ 
   if (gRequest.readyState==4 || gRequest.readyState=="complete")
   { 
      var resultElement   = document.getElementById("result");
      var throbberElement = document.getElementById("throbber");

      var content = gRequest.responseText;

      throbberElement.style.display = 'none';

//      resultElement.innerHTML = "<pre>"+content+"</pre>";
      resultElement.innerHTML = content;

   }
} 

