/******************************************************************************/
/* This program pulls the source path for each job defined in Metadata.       */
/* Author: Greg Wootton Date: 09JUL2018                                       */
/******************************************************************************/

/* Define connection to Metadata. */
options
  metaserver="meta.demo.sas.com"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="password"
  metarepository=Foundation
  metaprotocol=BRIDGE;

data source;

/* Retain only the job name and it's source code full path. */
  keep job_name source;

/* Initialize variables. */
  length type id job_uri job_name file_uri file_name dir_uri path $ 50;
  call missing (of _character_);

/* Define a query to search for Job objects. */
  obj="omsobj:Job?@Id contains '.'";

/* Count all jobs. Only run loop if jobs exist. */
  job_count=metadata_resolve(obj,type,id);

/* Loop: For each job found, get attributes and associations. */
  if job_count > 0 then do i=1 to job_count;
    rc=metadata_getnobj(obj,i,job_uri);
  /* Get job name. */
    rc=metadata_getattr(job_uri,"Name",job_name);
    /* Get file Metadata object id.  */
    rc=metadata_getnasn(job_uri,"SourceCode",1,file_uri);
    /* Get file name. */
    rc=metadata_getattr(file_uri,"Name",file_name);
    /* Get directory Metadata object id. */
    rc=metadata_getnasn(file_uri,"Directories",1,dir_uri);
    /* Get path to directory. */
    rc=metadata_getattr(dir_uri,"DirectoryName",path);
    /* combine directory path and file name to create full path to file.*/
    source=catx('/',path,file_name);
    output;
  end; /* End loop. */
  /* If no jobs are found, write a message to the log. */
  else put "WARN: No jobs found in Metadata.";
run;