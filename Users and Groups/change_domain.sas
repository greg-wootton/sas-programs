/******************************************************************************/
/* This program finds logins that contain a given Windows domain and replaces */
/* the domain with a new one.                                                 */
/* Author: Greg Wootton Date: 24MAY2019                                       */
/******************************************************************************/

/* Define Metadata connection information. */
options
  metaserver="meta.demo.sas.com"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="password"
  metarepository=Foundation
  metaprotocol=BRIDGE;

data _null_;
/* Define the old and replacement domains. */
  %let old_domain = domain;
  %let new_domain = newdomain;
/* End edit. */

/* Define and initialize variables. */
  length type id login_uri user stripped_user new_user $ 60;
  call missing(type,id,login_uri,user);

/* This is the query to local the Logins with the old domain. */
  obj="omsobj:Login?@UserID contains '&old_domain\'";

  /* Count the number of logins found by the query above. */
  count=metadata_resolve(obj,type,id);

  /* If logins were found, proceed. */
  if count > 0 then do n = 1 to count;
    /* Get the Metadata URI for the nth login. */
    login_rc=metadata_getnobj(obj,n,login_uri);
    /* Pull the full user ID for the login. */
    rc=metadata_getattr(login_uri,"UserID",user);
    /* Strip the domain from the user ID. */
    stripped_user=trim(scan(user,2,'\'));
    /* Define a new variable with the new domain and the user ID. */
    new_user=cats("&new_domain\",stripped_user);
    /* Set this new variable as the UserID attribute. */
    rc=metadata_setattr(login_uri,"UserID",new_user);
    end;
  /* If no logins are found with that domain, write that to the SAS log. */
  else put "No users match query";
run;