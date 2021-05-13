/******************************************************************************/
/* This program runs bhist -l against a supplied job ID and parses the output */
/* into a SAS data set.                                                       */
/* Note: XCMD must be enabled to allow for execution of the bhist command.    */
/* Author: Greg Wootton Date: 02JAN2019                                       */
/******************************************************************************/

/* Specify the job ID you would like to read in. */
%let job_id = 101;

/* Execute the bhist command to get the output */
/* to read in. Note:XCMD must be enabled. */
filename bhist pipe "bhist -l &job_id";

/* Create a temp file to edit the output. */
filename bhist2 temp;

/* Remove formatting from output. */
data _null_;
  infile bhist;
  file bhist2;
  input;
  if  _infile_ ne: "                     " and _N_ > 1 then put ;
  line=strip(_infile_);
  put line +(-1) @@ ;
run;

/* Write unformatted output to log. */
data _null_;
  infile bhist2;
  input;
  put _infile_;
run;

data jobinf;

/* Specify unformatted command output as the source.*/
infile bhist2 dlm=',';

/* Initialize varaibles. */
length blank $ 1 Job $ 50 Job_Name $ 50 User $ 50
Project $ 50 Command $ 255 line $ 512 job_num 8 prefix $ 50 ;

/* Read in line 1, which contains the job details. */
input blank $ Job $  Job_Name $  User $  Project $  Command $ ;
line=strip(_infile_);
if _n_=1 then do;
  rc=length(Job);
  Job=substr(Job,6,rc-6);
  rc=length(Job_Name);
  Job_Name=substr(Job_Name,11,rc-11);
  rc=length(User);
  User=substr(User,7,rc-7);
  rc=length(Project);
  Project=substr(Project,10,rc-10);
  rc=length(Command);
  Command=substr(Command,9,rc-9);
  job_num=input(Job,6.);
  output;
end;
/* drop unneeded variables */
drop blank line rc Job prefix;
run;

/* Extract memory usage information from the */
/* output, only reading the memory line. */
data meminfo;
length line $ 512 max_mem avg_mem $ 20;
infile bhist2;
input;
line=strip(_infile_);
if scan(line,1)="MAX" then do;
  max_mem=cat(scan(line,3),scan(line,4));
  avg_mem=cat(scan(line,7),scan(line,8));
  output;
end;
drop line;
run;

/* Read in the table of state times from the output. */
data times;
  length line $ 512 pend psusp run ususp ssusp unknwn total 8;
  infile bhist2;
  input @;
  line=strip(_infile_);
  prefix=scan(line,1);
  put prefix=;
  if prefix="PEND" then do;
    input;
    input pend psusp run ususp ssusp unknwn total;
    output;
  end;
  drop line prefix;
run;

/* Combine the details into a single data set. */

data jobinfo;
set meminfo;
set jobinf;
set times;
run;

/* Print it.*/

proc print data=jobinfo; run;

/* Read in the history lines, separating out the time value. */

data history;
length line $ 512;
infile bhist2 dlm=',';
input;
if _n_ ne 1 and _n_ ne 2 then do;
  line=strip(_infile_);
  if line="" then;
  else if line="MEMORY USAGE:" then;
  else if scan(line,1)="Summary" then;
  else if scan(line,1)="MAX" then;
  else if scan(line,1)="PEND" then;
  else if prxmatch(prxparse('/\d/'),scan(line,1)) then ;
  else do;
    time=input(substr(line,12,8),time8.);
    format  time time8.;
    line_length=length(line);
    line=substr(line,21,line_length-21);
    output;
    end;
end;
drop line_length;
run;

/* Print it. */

proc print data=history; run;