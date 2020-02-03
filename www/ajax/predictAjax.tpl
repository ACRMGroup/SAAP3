// CONFIGURATION
// -------------
// Filename in URL /tmp/gProcessID to which we redirect on completion.
// Set this to a blank string if you don't want a redirect
//var gRedirect  = "index.html";   
var gRedirect  = "";   
// Server name, just used to report a URL (NO TRAILING / !!!)
// Set to blank if you aren't doing a redirect
var gServer    = "$[SERVER]"; // Server name - NO TRAILING /
var gTmpURL    = "$[TMPURL]"; // Temp URL, must start and end with /

// The submission CGI script
var gSubmitCGI = "predictSubmit.cgi";  
// The monitor CGI script
var gMonitorCGI = "predictMonitor.cgi"; 
// A piece of text used to indicate the end of the long-running program
var gEOF = "\n__EOF__\n";


// ---------------------------------------------------------------------------------
// YOU DON'T NEED TO TOUCH THESE
var gRequest   = null;   // HTTPRequest passed between main 
                         // call and async routines
var gProcessID = null;   // ProcessID for the analysis - also 
                         // used for temp directory containing results
var gURLPath   = null;

// ---------------------------------------------------------------------------------
// YOU WILL NEED TO CHANGE THIS!
function SubmitPredict(dir, jsonFile, urlPath)
{
//    alert("DIR: " + dir + "| JSONFILE: " + jsonFile + "| URLPATH: " + urlPath);

    gURLPath = urlPath;

    gRequest = createRequest();
    if (gRequest==null)
    {
        alert ("Browser does not support HTTP Request");
        return;
    } 
    
    var throbberElement = document.getElementById("throbber");
    throbberElement.style.display = 'inline';
    
    var resultsElement = document.getElementById("results");
    resultsElement.style.display = 'inline';
    
    // *** Disable the submit button
    var submitElement = document.getElementById("submit");
    submitElement.disabled = true;
    
    // *** NOW RUN THE SUBMIT SCRIPT
    var url=gURLPath + "/" + gSubmitCGI + "?dir="+dir+"&amp;json="+jsonFile;
//    alert(url);

    gRequest.open("GET",url,true);
    gRequest.onreadystatechange=getProcessID;
    gRequest.send(null);
}

// ---------------------------------------------------------------------------------
// NOTHING MUCH OF INTEREST BEYOND HERE
function createRequest() {
    var req = null;
    try {
        req = new XMLHttpRequest();
    } catch (trywindow) {
        try {
            req = window.createRequest();
        } catch (trymicrosoft)  {
            try {
                req = new ActiveXObject("Msxml2.XMLHTTP");
            }  catch (othermicrosoft)   {
                try  {
                    req = new ActiveXObject("Microsoft.XMLHTTP");
                }  catch (failed) {
                    req = null;
                }
            }
        }
    }
    
    return(req);
}

function getProcessID() 
{ 
    if (gRequest.readyState==4 || gRequest.readyState=="complete")
    { 
        var resultsElement = document.getElementById("results");
        gProcessID = gRequest.responseText;

        if(gServer == "")
        {
            resultsElement.innerHTML = "<p>The process ID for your analysis is: "+gProcessID+". Please report this if you receive any errors.</p><div id='progress'><pre>Progress on the analysis will appear here...</pre></div>";
        }
        else
        {
            var url = gServer+gTmpURL+gProcessID+"/log";

            resultsElement.innerHTML = "<p>The process ID for your analysis is: "+gProcessID+"</p><p>If you do not wish to wait for the results now, you will be able to access them at<br /><b>"+url+"</b><br />when the run is complete.</p><div id='progress'><pre>Progress on the analysis will appear here...</pre></div>";
        }

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
    var url=gURLPath + "/" + gMonitorCGI + "?processid="+gProcessID;
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
        
        // *** THE SLOW RUNNING PROGRAM MUST INCLUDE THIS TEXT AT THE END OF ITS STATUS UPDATES
        if(content.indexOf(gEOF) >= 0) // Come to end of updates
        {
            content = content.replace(gEOF, "");
            progressElement.innerHTML = "<pre>"+content+"</pre>";

            if(gRedirect == '')
            {
                // We are just displaying new information
                // Remove the throbber and enable the submit button
                var throbberElement = document.getElementById("throbber");
                throbberElement.style.display = 'none';

                var submitElement = document.getElementById("submit");
                submitElement.disabled = false;
            }
            else  // We are replacing the page
            {
                var newURL = gTmpURL+gProcessID+"/"+gRedirect;
                window.location=newURL;
            }
        }
        else
        {
            progressElement.innerHTML = "<pre>"+content+"</pre>";
            WaitForUpdateResults();
        }
    } 
} 

