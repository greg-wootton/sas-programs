/******************************************************************************/
/* This program creates a dataset WORK.EMAILS of all the email addresses from */
/* each email object defined in metadata.                                     */
/* Author: Greg Wootton Date: 09FEB2017                                       */
/******************************************************************************/

/* Define metadata connection information. */
options
  metaserver="meta.demo.sas.com"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="password"
  metarepository=Foundation
  metaprotocol=BRIDGE;

data work.emails; /* Create a dataset, work.emails. */

/* define and initialize variables. */
length type id email_add email_uri user_uri user_name $ 50;
call missing (type,id,email_add,email_uri,user_uri,user_name);

/* Count the email objects defined in Metadata. */
email_count=metadata_resolve("omsobj:Email?@Id contains '.'",type,id);

/* If any are present, for each one gather their attributes. */
if email_count > 0 then do n=1 to email_count;
    rc=metadata_getnobj("omsobj:Email?@Id contains '.'",1,email_uri);
    rc=metadata_getattr(email_uri,"Address",email_add);
    rc=metadata_getnasn(email_uri,"Persons",1,user_uri);
    rc=metadata_getattr(user_uri,"Name",user_name);
    output; /* Write the attributes gathered to the dataset. */
end;
run;
