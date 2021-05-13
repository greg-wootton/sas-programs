/******************************************************************************/
/* This program queries job information from SAS Workload Orchestrator using  */
/* PROC HTTP and Basic Authentication.                                        */
/* DEPRECATED - the authentication process changed slightly with hotfix E3Y001*/
/* Author: Greg Wootton Date: 02JAN2019                                       */
/******************************************************************************/

/* Provide connection information. */
%let username = sas;
%let pw = password;
%let baseURL = http://wlo-master.demo.sas.com:8901;

/* Initialize files to capture HTTP response body and headers. */

filename body temp;
filename headout temp;

/* Submit an authenticated query against the jobs API */
/* requesting jobs with a state of "ALL" e.g. any non-archived jobs. */

proc http URL="&baseURL/sasgrid/api/jobs?state=ALL" out=body
headerout=headout headerout_overwrite webusername="&username" webpassword="&pw";
headers "Accept"="application/vnd.sas.sasgrid.jobs;version=1;charset=utf-8";
run;

/* Deassign the jobinfo libname. */
libname jobinfo;

/* Read in the job info. */
libname jobinfo json fileref=body;

/* Create a single table with items of interest. */
proc sql;
create table jobs as
  select
    a.id,
    b.state, b.queue, b.submitTime, b.startTime, b.endTime,
    b.processId, b.executionHost, b.exitCode,
    c.name, c.user, c.cmd from
    jobinfo.jobs a,
    jobinfo.jobs_processinginfo b,
    jobinfo.jobs_request c
    where a.ordinal_jobs = b.ordinal_jobs and
    b.ordinal_jobs = c.ordinal_jobs
    order by a.id;
quit;

/* Print it. */
proc print data=work.jobs; run;

