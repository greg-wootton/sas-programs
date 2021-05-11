/******************************************************************************/
/* This program pulls a list of all users defined in Metadata.                */
/* Author: Greg Wootton Date: 26SEP2016                                       */
/******************************************************************************/

/* Provide Metadata hostname and credentials. */

options
  metaserver="hostname"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="password"
  metarepository=Foundation
  metaprotocol=BRIDGE;

/* End edit. */

/* Create temporary data set "work.users" to store user names. */
data work.users;

/* Declare variables. */

  length
    Person_uri $ 256
    Person_id $ 17
    Person_name $ 256;

/* Initialize variables. */

  call missing(Person_uri,Person_id,Person_name);

  n=1;

/* Count how many users have been defined in Metadata. */

  userrc=metadata_getnobj("omsobj:Person?@Id contains '.'",n,Person_uri);

    /* check and report negative return codes */
    if userrc= -1 then do; put "Unable to connect to the metadata server."; end;
    else if userrc = -4 then do; put "n is out of range."; end;
    else do;

  do while(userrc>0); /* For each user found, get the user's name attribute. */
    rc=metadata_getattr(Person_uri,"Name",Person_name);
    rc=metadata_getattr(Person_uri,"Id",Person_id);
    output;
    n+1;
    userrc=metadata_getnobj("omsobj:Person?@Id contains '.'",n,Person_uri);
  end;
  end;
run;
