/******************************************************************************/
/* This program reports all users creation date.                              */
/* Author: Greg Wootton Date: 06NOV2017                                       */
/******************************************************************************/

/* Establish a connection to the Metadata server. */
/* This must be edited to provide the appropriate connection information. */

options metaserver="meta.demo.sas.com"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="<password>"
  metaprotocol=bridge
  metarepository=foundation;

/* End edit. */

data users; /* Create a data set work.users. */

/* Initialize variables. */
length
type
id $ 17
user_name
user_dn
user_mc
user_uri $ 50
user_created 8;

call missing(of _character);

label   user_name="User Name"
  user_dn="User Display Name"
  user_created="User Created";

format user_created datetime.;

/* Define search parameters. */

obj="omsobj:Person?@Id contains '.'";

/* Test if any users exist. */

user_count=metadata_resolve(obj,type,id);

/* If so, for each extract the name, */
/* display name, and metadata created attributes. */

if user_count > 0 then do i=0 to user_count;
  rc=metadata_getnobj(obj,i,user_uri);
  rc=metadata_getattr(user_uri,"Name",user_name);
  rc=metadata_getattr(user_uri,"DisplayName",user_dn);
  rc=metadata_getattr(user_uri,"MetadataCreated",user_mc);
  user_created=input(user_mc,datetime.);

/* Output if a user name is defined. */
  if user_name = '' then continue; else output;
end;

/* Drop unwanted variables.*/

keep user_name user_created user_dn;
run;

/* Sort the data set by date. */

proc sort data=users;
by user_created;
run;

/* Produce a report. */

proc report data=users; run;