/******************************************************************************/
/* This program uses the Platform Web Services REST API to get a list of      */
/* hosts and jobs and their status.                                           */
/* Author: Greg Wootton Date: 08FEB2019                                       */
/******************************************************************************/

/* Define macro variables for the username, */
/* password and the associated REST service. */

%let username=<lsf_admin_user>;
%let pwd=<lsf_admin_password>;
%let baseurl=http://<web_server>:<web_port>;
%let hostsurl=&baseurl/PlatformWebServices/ws/hosts;
%let jobsurl=&baseurl/PlatformWebServices/ws/jobs;


/* Establish files for the input to and output from PROC HTTP. */
filename resp temp;
filename headout temp;
filename input temp;

/* Define the "input" payload as the username and password */
/* in the format username=<username>&password=<password> */
data _null_;
  file input recfm=f lrecl=1;
  put "username=&username.%nrstr(&password)=&pwd";
run;

/* Call SASLogon to acquire a ticket granting ticket (TGT) URL for the user. */
proc http URL="&baseurl/SASLogon/v1/tickets" method="POST"
in=input out=resp headerout=headout HEADEROUT_OVERWRITE;
run;

/* Dump the response (header) from SASLogon to the SAS log. */
data _null_;
  infile headout;
  input;
  put _infile_;
run;

/* Establish variables for the response. */
%global hcode;
%global hmessage;
%global location;

/* Read the response (header) into those variables. */
/* The "location" is the TGT URL and is really the only one we need for this. */
data _null_;
  infile headout termstr=CRLF length=c scanover truncover;
  input @'HTTP/1.1' code 4. message $255.
  @'Location:' loc $255.;
  call symputx('hcode',code);
  call symput('hmessage',trim(message));
  call symput('location',trim(loc));
run;

/* Send the URL of the REST API we wish to call to the TGT URL. */
/* SASLogon should respond with a service ticket used to */
/* communicate with that service directly. */
proc http method="POST" URL="&location"
in="service=&hostsurl." headerout=headout out=resp HEADEROUT_OVERWRITE;
run;

/* Establish a variable to store that ticket. */
%global ticket;

/* Read in the response (body) from SASLogon TGT URL */
/* to the ticket variable we created. */
data _null_;
  infile resp;
  input @;
  call symput('ticket', trim(_infile_));
run;

/* Call the service URL directly, providing the ticket value in */
/* the URL as part of the request. Our request header also */
/* indicates we would like the response in JSON. */
proc http url="&hostsurl.?ticket=&ticket." out=resp headerout=headout;
headers "Accept"="application/json";
run;

/* Clear any existing library called hosts.*/
libname hosts;

/* Define the response using the JSON libname engine as the library "hosts". */
libname hosts JSON fileref=resp;

/* Create a data set hoststat in WORK with only server hosts */
/* from the response and their status. */
data hoststat;
  set hosts.pseudohosts_pseudohost;
  if serverType = 1 then output;
  drop ordinal_pseudoHosts ordinal_pseudoHost;
run;

/* Print the contents of the new "hoststat" data set. */

proc print data=hoststat; run;

/* Send the URL of the REST API we wish to call to the TGT URL. */
/* SASLogon should respond with a service ticket used to */
/* communicate with that service directly. */
proc http method="POST" URL="&location"
in="service=&jobsurl." headerout=headout out=resp HEADEROUT_OVERWRITE;
run;

/* Read in the response (body) from SASLogon TGT URL */
/* to the ticket variable we created. */
data _null_;
  infile resp;
  input @;
  call symput('ticket', trim(_infile_));
run;

proc http url="&jobsurl.?ticket=&ticket.%nrstr(&username=all)"
out=resp headerout=headout;
headers "Accept"="application/json";
run;
/* Clear any existing library called jobs. */
libname jobs;
/* Define the response using the JSON libname engine as the library "jobs". */
libname jobs JSON fileref=resp;

data jobstat;
  set jobs.Pseudojobs_pseudojob;
  drop ordinal_pseudoJobs ordinal_pseudoJob command
  submitTime startTime endTime jobName;
run;

proc print data=jobstat; run;