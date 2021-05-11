/******************************************************************************/
/* This program pulls a list of all user IDs defined in Metadata for          */
/* the DefaultAuth authentication domain.                                     */
/* Author: Greg Wootton Date: 08FEB2017                                       */
/******************************************************************************/

/* Provide Metadata hostname and credentials. */
options
  metaserver="<hostname>"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="<password>"
  metarepository=Foundation
  metaprotocol=BRIDGE;

data work.users; /* Create work.users library to house data. */

/* declare variables */

length
  ad_uri $ 256
  ad_id $ 256
  login_uri $ 256
  user_id $ 256;

/* initialize variables. */

call missing(ad_uri,ad_id,login_uri,user_id);
keep user_id; /* only keep the user ids in the table. */

n=1;
/* Get the URI for the DefaultAuth Authentication Domain. */
adrc=metadata_getnobj("omsobj:AuthenticationDomain?@Name = 'DefaultAuth'",1,ad_uri);
rc=metadata_getattr(ad_uri,"Id",ad_id);

/* Get number of login objects that have the DefaultAuth authentication */
/* domain associated with them, as well as the URI of the first login. */
loginrc=metadata_getnobj("omsobj:Login?Login[Domain/AuthenticationDomain[@Id='"||ad_id||"']]",n,login_uri);
do while(loginrc>0);
  /* extract the user ID from login */
  rc=metadata_getattr(login_uri,"UserID",user_id);
  output;
  n+1;
  /* Get the URI of the next login. */
  loginrc=metadata_getnobj("omsobj:Login?Login[Domain/AuthenticationDomain[@Id='"||ad_id||"']]",n,login_uri);
end;
run;
