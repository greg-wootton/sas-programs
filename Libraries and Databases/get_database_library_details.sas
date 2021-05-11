/******************************************************************************/
/* This program pulls information on Database libraries defined in Metadata.  */
/* Author: Greg Wootton Date: 22DEC2016                                       */
/******************************************************************************/

/* Define Metadata Server connection. */
options
  metaserver="<hostname>"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="<password>"
  metarepository=Foundation
  metaprotocol=bridge;

data work.libinfo;

/*declare and initialize variables */
  length
    type user schema $ 20
    lib_uri lib_name app_uri app_name schema_uri login_uri
    dbms_uri dbms_name conn_uri prop_uri datasrc $ 50
    id $ 17;
  keep lib_name app_name user schema dbms_name datasrc;
  call missing(of _character_);

  obj="omsobj:SASLibrary?@IsDBMSLibname = '1'";

  /* Search Metadata for libraries */

  libcount=metadata_resolve(obj,type,id);
  put "INFO: Found " libcount "database libraries.";
  /* for each library found, extract name and associated properties */
  /*
  default login,
  first associated application server,
  schema,
  database server
  */
  if libcount > 0 then do n=1 to libcount;

  rc=metadata_getnobj(obj,n,lib_uri);
  rc=metadata_getattr(lib_uri,"Name",lib_name);
  rc=metadata_getnasn(lib_uri,"DefaultLogin",1,login_uri);
  rc=metadata_getattr(login_uri,"UserID",user);
  rc=metadata_getnasn(lib_uri,"DeployedComponents",1,app_uri);
  rc=metadata_getattr(app_uri,"Name",app_name);
  rc=metadata_getnasn(lib_uri,"UsingPackages",1,schema_uri);
  rc=metadata_getattr(schema_uri,"SchemaName",schema);
  rc=metadata_getnasn(schema_uri,"DeployedComponents",1,dbms_uri);
  rc=metadata_getattr(dbms_uri,"Name",dbms_name);
  rc=metadata_getnasn(dbms_uri,"SourceConnections",1,conn_uri);
  rc=metadata_getnasn(conn_uri,"Properties",1,prop_uri);
  rc=metadata_getattr(prop_uri,"DefaultValue",datasrc);
  output; /* Push results to table  */

  end;
  else put "INFO: No libraries to resolve.";
run;
