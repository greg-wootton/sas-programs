/******************************************************************************/
/* This program pulls the defined groups and creation date from Metadata.     */
/* Author: Greg Wootton Date: 03APR2019                                       */
/******************************************************************************/

/* Define metadata connection information. */
options
  metaserver="meta.demo.sas.com"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="password"
  metarepository=Foundation
  metaprotocol=BRIDGE;
/* End edit. */

data groups;
/* Initialize variables. */
  length
  group_uri $ 38
    group_obj $ 47
    group_count 8
    group_created 8
    type $ 50
    id $ 47
    group_name $ 50;

  call missing(group_uri,group_obj,group_name,type,id,group_created);

  format group_create_date datetime7.;

/* This query finds "UserGroup" type IdentityGroup objects (i.e. not roles) */
  group_obj="omsobj:IdentityGroup?@PublicType='UserGroup'";

  /* Count the objects that match the query. */
  group_count=metadata_resolve(group_obj,type,id);

  /* Proceed if any exist. */
  if group_count > 0 then do n=1 to group_count;
    /* Get the n'th group object's URI */
    rc=metadata_getnobj(group_obj,n,group_uri);
    /* Use this to pull the name and create date. */
    rc=metadata_getattr(group_uri,"Name",group_name);
    rc=metadata_getattr(group_uri,"MetadataCreated",group_created);
    /* Read the create date in to the numeric date representation. */
    group_create_date=input(group_created,DATETIME.);
    output;
  end;
  /* Only keep the name and numeric creation value. */
  keep group_name group_create_date;

run;
