/******************************************************************************/
/* This program will run a configuration refresh on all Object Spawners       */
/* defined in Metadata. Note: If not all object spawners defined are running  */
/* an error will be returned.                                                 */
/* Author: Greg Wootton Date: 02JUN2020                                       */
/******************************************************************************/

/* Metadata connection information: */

%let metaserve=meta.demo.sas.com;
%let metaport=8561;
%let userid=sasadm@saspw;
%let pass=password;

/* End edit. */

/* Connect to Metadata Server */

options
  metaserver="&metaserve"
  metaport=&metaport
  metauser="&userid"
  metapass="&pass"
  metarepository=Foundation
  metaprotocol=BRIDGE;


data work.objspawn;

  keep host_name port; /* Only keep hosts and port for Object Spawners. */
  retain port; /* Keep port for all iterations. */

  /* Declare and initialize variables. */

  length type id objspwn_uri tree_uri mach_uri host_name conn_uri port $ 50;
  call missing(of _character_);

  /* This is the XML Select query to locate Object Spawners. */
  obj="omsobj:ServerComponent?@PublicType='Spawner.IOM'";

  /* Test for definition of Object Spawner(s) in Metadata. */

  objspwn_cnt=metadata_resolve(obj,type,id);
  if objspwn_cnt > 0 then do n=1 to objspwn_cnt;

  /* Get URI for each Object Spawner found. */

    rc=metadata_getnobj(obj,n,objspwn_uri);

    /* Get associated attributes for the */
    /* object spawner (connection port and hosts) */

    rc=metadata_getnasn(objspwn_uri,"SoftwareTrees",1,tree_uri);
    rc=metadata_getnasn(objspwn_uri,"SourceConnections",1,conn_uri);
    rc=metadata_getattr(conn_uri,"Port",port);
    mach_cnt=metadata_getnasn(tree_uri,"Members",1,mach_uri);

    /* For each host found, get the host name and output */
    /* it along with the port number to the dataset. */

    do m=1 to mach_cnt;
      rc=metadata_getnasn(tree_uri,"Members",m,mach_uri);
      rc=metadata_getattr(mach_uri,"Name",host_name);
      output;
    end;
  end;
  else put "No Object Spawners defined in Metadata.";
run;

/* WORK.OBJSPAWN now contains a list of hosts running Object Spawners. */

%macro refreshspawn();

/* Count how many Object Spawners are defined */
/* in WORK.OBJSPAWN as a Macro variable. */

proc sql noprint;
  select count(*) into :nobjs from work.objspawn;
quit;
/* If hosts were found, extract them as macro variables. */
%if &nobjs > 0 %then %do;

proc sql noprint;
  select host_name into:host1-:host%left(&nobjs) from work.objspawn;
  select port into:port1-:port%left(&nobjs) from work.objspawn;
quit;

%end;
%else;

/* Connect to each object spawner and perform a refresh configuration. */

%do i=1 %to &nobjs;
  proc iomoperate;
    connect host="&&host&i"
        port=&&port&i
        user="&userid"
        pass="&pass"
        servertype=OBJECTSPAWNER;
    REFRESH CONFIGURATION;
  quit;
%end;
%mend refreshspawn;

%refreshspawn;