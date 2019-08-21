AJAX Slow Program Framework
===========================

This is a simple demonstration framework for creating very long
running programs that report their progress.

index.html
----------

A demonstration index page with a form. This may be modified as
required. The key points are:

- it includes the `ajax.js` JavaScript file 
  **[MUST BE ALTERED IF YOU RENAME THE SCRIPT!]**
- it has a form with a button that runs the `Submit()` method from the
  AJAX file
- the submit button must have `id='submit`
- it has a div called `throbber` with `display:none`
- it has a div called `results` where the progress will be displayed

ajax.js
-------

This handles the AJAX requests. Key points are:

- `gRedirect` - is set to the final web page with the results to be
   displayed when the long-running program completes. You set it to
   a blank string if you don't want to redirect
- `gServer` - the name of the server on which you are running. Only
   used to display a URL for the log information and a direct link
   to the final results. Set it to a blank string if you don't want
   this information or don't have a redirect.
- `Submit()` - this is the submission function called by from the
   form. It grabs the values from the form and passes them to the
   submission CGI script (specified with `gSubmitCGI`)
   **[MUST BE ALTERED TO OBTAIN THE VALUES FROM THE FORM]**

You may also need to alter these

- `gSubmitCGI` - this is the URL of the submission script (see below)
   **[MUST BE ALTERED IF YOU RENAME THE SCRIPT!]**
- `gMonitorCGI` - this is the URL of the monitoring script (see below)
   **[MUST BE ALTERED IF YOU RENAME THE SCRIPT!]**
- `gEOF` - end of file marker used to indicate that the long-running 
   program has finished. It must match that specified in `config.pm`

config.pm
---------

Configuration module used by the Perl scripts.

- `$webTmpDir` - the physical address of the web temporary directory
- `$EOF`       - End-of-file marker - must match that specified in
                 ajax.js

submit.cgi
----------

The CGI script is called by the `ajax.js/Submit()` function and takes
the parameters from the form. It writes a temporary index file for the
results and spawns the actual long running program in the background.

**If this script is renamed, you must alter ajax.js**

Key points are:

- This is a CGI script
- It obtains the parameters collected from the form by
  `ajax.js/Submit()` 
  **[MUST BE ALTERED TO OBTAIN THE REQUIRED VALUES]**
- The name of the slow-running program is specified with `$slowProgram`
- It calls `$slowProgram` and passes parameters to it
  **[MUST BE ALTERED TO PASS THE REQUIRED PARAMETERS]**
- The standard output and error from the slow running program must go 
  to `$outDir/log2`
- `WriteIndexFile()` may be altered as required, but it only contains
  temporary information and will be replaced

slowprog.pl
-----------

This is the actual slow running program (though it may well call other
programs of scripts. 

**If this script is renamed, you must alter `$slowProgram` in `submit.cgi`**

Key points are:

- It must receive the `$processID` and any other parameters on the
  command line
- It must write progress information to
  `$config::webTmpDir/$processID/log` (a subroutine, `WriteMessage()`
  is provided for this purpose). 
- When things have finished, if a redirect for results is required,
  these must be written to `$config::webTmpDir/$processID/index.html`
  (a subroutine, `WriteNewIndexFile()` is provided for this purpose).
- Also, when things have finished, `$config::EOF` must be written as
  a progress message to indicate that it has finished.

monitor.cgi
-----------

**If this script is renamed, you must alter ajax.js**

This CGI script is called by the `ajax.js/WaitForUpdateResults()`
function. In general there is nothing that needs changing in here.





