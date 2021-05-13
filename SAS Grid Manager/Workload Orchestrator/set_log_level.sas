/* This program will set the default trace loggers */
/* on the master server using negotiate authentication. */

/* Provide connection information. */
%let username = username;
%let pw = password;
%let baseURL = https://grid-master.demo.sas.com:8901;

/* Define the loggers we want to set and at what level into a dataset. */
/* "NULL" instructs to inherit from the parent. */

data work.loglevel;
length logger $ 255 level $ 10;
call missing (of _character_);
input logger $ level $;
datalines;
  App.Grid.SGMG.Log trace
  App.Grid.SGMG.Log.Util.Lock info
  Audit.Authentication trace
  App.tk.http.server trace
  App.tk.HTTPC trace
  App.tk.HTTPC.wire trace
  App.tk.tkels trace
  App.tk.tkjwt trace
  App.tk.tcp info
  App.tk.eam debug
  App.tk.eam.rsa.pbe info
;;
run;

/* Use these log levels to set to default trace
  App.Grid.SGMG.Log trace
  App.Grid.SGMG.Log.Util.Lock info
  Audit.Authentication trace
  App.tk.http.server trace
  App.tk.HTTPC trace
  App.tk.HTTPC.wire trace
  App.tk.tkels trace
  App.tk.tkjwt trace
  App.tk.tcp info
  App.tk.eam debug
  App.tk.eam.rsa.pbe info
*/

/* Use these log levels to set back to normal
  App.Grid.SGMG.Log null
  App.Grid.SGMG.Log.Util.Lock null
  Audit.Authentication warn
  App.tk.http.server warn
  App.tk.HTTPC null
  App.tk.HTTPC.wire fatal
  App.tk.tkels null
  App.tk.tkjwt null
  App.tk.tcp null
  App.tk.eam null
  App.tk.eam.rsa.pbe null
*/

/* Initialize files to capture HTTP response body and headers. */

filename body temp;
filename headout temp;
filename input temp;
filename payload temp;

/* Authenticate and get an auth cookie. */

proc http URL="&baseURL/sasgrid/index.html" method="post"
out=body headerout=headout headerout_overwrite
in="username=&username%nrstr(&password)=&pw";
headers "ContentType"="application/x-www-form-urlencoded";
run;

/* Call the "hosts" endpoint to get all */
/* the hosts defined for the grid. */

proc http URL="&baseURL/sasgrid/api/hosts"
out=body headerout=headout headerout_overwrite;
headers "Accept"="application/vnd.sas.sasgrid.hosts;version=1;charset=utf-8";
run;

/* Deassign the hostinfo libname */

libname hostinfo;

/* Read in the host info JSON output from PROC HTTP. */
libname hostinfo json fileref=body;

/* Copy the hostinfo.hosts JSON into a SAS data set. */
data hosts;
  set hostinfo.hosts;
run;

/* Build a PROC JSON of what we want from the loglevel */
/* and hostinfo datasets, writing it into the file "input". */

data _null_;
  file input;
  set work.hosts nobs=last;
  if _n_=1 then do;
    put 'proc json out=payload;';
    put 'write open object;';
    put 'write values "version" 1;';
    put 'write values "hosts";';
    put 'write open array;';
  end;
  put 'write values "' name + (-1) '";';
  if _n_=last then do;
    put 'write close;';
  end;
run;

data _null_;
  file input mod;
  set work.loglevel nobs=last;
  if _n_=1 then do;
    put 'write values "loggers";';
    put 'write open array;';
  end;
    put 'write open object;';
    put 'write values "name" "' logger + (-1) '";';
    put 'write values "level" "' level + (-1) '";';
    put 'write close;';
  if _n_=last then do;
    put 'write close;';
    put 'write close;';
    put 'run;';
  end;
run;
/* Run the PROC JSON "input" file we just built. */
%include input;

/* Submit the logger update request JSON to the REST endpoint. */
proc http URL="&baseURL/sasgrid/api/loggers" method="PUT"
in=payload headerout=headout headerout_overwrite
ct="application/vnd.sas.sasgrid.loggers.request;version=1;charset=utf-8";
  headers "Accept"="*/*";
run;
