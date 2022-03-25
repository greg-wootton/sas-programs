/******************************************************************************/
/* This program pulls all users from Metadata and any associated user IDs.    */
/******************************************************************************/

/* Provide connection information and credentials to Metadata Server. */

options metaserver="meta.demo.sas.com"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="password"
  metarepository=Foundation
  metaprotocol=bridge;

data users;
/* Declare and initialize variables. */
length id type per_uri per_dname per_name user_id log_uri $ 50;
call missing(of _character_);

/* Specify user query. */

obj="omsobj:Person?Person[@Id contains '.']";

/* Count objects that match that query. */
user_count=metadata_resolve(obj,type,id);
if user_count > 0 then do n=1 to user_count;
  rc=metadata_getnobj(obj,n,per_uri);

  /* For each, get the "name" and "display name" */
  /* attributes for the user object. */
  rc=metadata_getattr(per_uri,"Name",per_name);
  rc=metadata_getattr(per_uri,"DisplayName",per_dname);

  /* Count how many associated logins exist for the user. */
  login_count=metadata_getnasn(per_uri,"Logins",1,log_uri);
  if login_count > 0 then do m=1 to login_count;

    /* If there are any, extract the userid defined, */
    /* and output an observation for each user ID. */
    rc=metadata_getnasn(per_uri,"Logins",m,log_uri);
    rc=metadata_getattr(log_uri,"userid",user_id);
    output;
  end;
  /* if no logins are found, output an observation */
  /* of only the user defined in Metadata. */
  else do;
    call missing(user_id);
    output;
  end;
end;

/* Drop all the variables not needed. */
keep per_dname per_name user_id;
run;

/* Print a report of the data. */
proc print data=users; run;
