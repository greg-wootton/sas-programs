/******************************************************************************/
/* This program demonstrates how to write SAS code to run in parallel on the  */
/* grid. In this exmaple we have two RSUBMIT calls that each run a 10 second  */
/* sleep before returning. We capture the start and end time and calculate    */
/* the elapsed time to demonstrate less than 20 seconds elapses and therefore */
/* parallel execution has occurred.                                           */
/* Author: Greg Wootton Date: 04DEC2018                                       */
/******************************************************************************/

/* Define Metadata connection information. */
options
  metaserver='meta.demo.sas.com'
  metaport=8561
  metaprotocol='bridge'
  metauser='sasdemo'
  metapass='password'
  metarepository='Foundation'
  metaconnect='NONE';

/* Call GRDSVC_ENABLE so SAS/CONNECT SIGNON statements will start grid jobs. */
%let rc=%sysfunc(grdsvc_enable(_all_, server=SASApp));

/* Set the current time as the start time. */
%let st_tm=%SYSFUNC(time(),time.);
/* Start the first session. */
SIGNON sess1;
/* Submit code to the first session, but do not wait */
/* for it to complete before proceeding. (wait=no) */
  rsubmit sess1 wait=no;
    data _null_;
      rc=sleep(10,1); /* Wait 10 seconds then end. */
    run;
    %put Note: Sess1 waited 10 seconds; /* Write out to the log. */
  endrsubmit;

SIGNON sess2; /* Start a second session, and submit the same sleep code. */
  rsubmit sess2 wait=no;
    data _null_;
      rc=sleep(10,1);
    run;
    %put Note: Sess2 waited 10 seconds;
  endrsubmit;

waitfor _all_; /* Wait for both RSUBMITs to complete. */
SIGNOFF _all_; /* End both SAS sessions. */
%let en_tm=%SYSFUNC(time(),time.) ; /* Set the complete time. */
data _null_; /* Calculate the delay and write it to the log. */
  st_tm="&st_tm"t;
  en_tm="&en_tm"t;
  int=intck('seconds',st_tm,en_tm);
  put "Interval is " int "seconds.";
run;