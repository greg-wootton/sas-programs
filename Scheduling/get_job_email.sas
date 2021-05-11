/******************************************************************************/
/* This program extracts the email address defined in Metadata for jobs       */
/* and flows.                                                                 */
/* Author: Greg Wootton Date: 06MAR2019                                       */
/******************************************************************************/

/* Define connection to Metadata. */
options
  metaserver="meta.demo.sas.com"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="password"
  metarepository=Foundation
  metaprotocol=BRIDGE;

/* Get flow notification email addresses. */
data flow_email;
  length type id prop_uri email job_uri jobname $ 50;
  call missing (of _character_);

  /* Define query to find the properties named "EmailNotificationAddress"  */
  obj="omsobj:Property?@Name='EmailNotificationAddress'";
  /* obj="omsobj:Property?@Name='JobDefaultEmailNotificationAddress'"; */
  prop_count=metadata_resolve(obj,type,id);
  if prop_count > 0 then do i=1 to prop_count;
    rc=metadata_getnobj(obj,i,prop_uri);
    rc=metadata_getattr(prop_uri,"DefaultValue",email);
    rc=metadata_getnasn(prop_uri,"AssociatedObject",1,job_uri);
    rc=metadata_getattr(job_uri,"Name",jobname);
    if email ne "" then output;
  end;
  keep email jobname;
run;

/* Get job notification email addresses. */
data job_email;
  length type id prop_uri job_uri jobname maildef email $ 50 jobdefxml $ 32767;
  call missing (of _character_);
  /* Query for property objects named "SCHEDULINGDETAILS" */
  obj="omsobj:Property?@Name='SCHEDULINGDETAILS'";
  /* Count the objects that match the query. */
  prop_count=metadata_resolve(obj,type,id);
  /* Define the regular expressions to find the mail property and */
  /* email address objects. */
  pattern=prxparse('/\<MailDestination.*>/');
  emailpattern=prxparse('/([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})/');

  /* If any properties were found, pull the associated job name */
  /* and the job definition XML which contains the email address. */
  if prop_count > 0 then do i=1 to prop_count;
    rc=metadata_getnobj(obj,i,prop_uri);
    rc=metadata_getattr(prop_uri,"DefaultValue",jobdefxml);
    rc=metadata_getnasn(prop_uri,"AssociatedObject",1,job_uri);
    rc=metadata_getattr(job_uri,"Name",jobname);
    /* Find the mail destination XML in the job definition. */
    call prxsubstr(pattern,jobdefxml,mailset,length);
    if mailset > 0 then do;
    /* extract the mail definition from the job definition xml. */
    maildef=substr(jobdefxml,mailset,length);
    /* Find the email address in the mail definition. */
    call prxsubstr(emailpattern,maildef,position,length);
    /* Store the email address. */
    email=substr(maildef,position,length);
    output;
    end;
  end;
  keep email jobname;
run;

