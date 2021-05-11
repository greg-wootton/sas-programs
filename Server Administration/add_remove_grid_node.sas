/******************************************************************************/
/* This program will add or remove a machine in Metadata and if adding, add   */
/* assocation to a supplied list of server objects.                           */
/* The original purpose was to automate adding compute nodes.                 */
/*                                                                            */
/* WARNING: This program writes to Metadata. Be sure to take a Metadata       */
/*          Backup prior to running the program.                              */
/* Author: Greg Wootton Date: 17SEP2020                                       */
/******************************************************************************/

/* Specify Metadata connection information: */

%let metaserve=meta.demo.sas.com;
%let metaport=8561;
%let userid=sasadm@saspw;
%let pass=password;

/* The hostname of the machine you wish to add/remove. */
/* Set the action accordingly.*/

/* Setting remove will delete the machine object entirely. */
%let machine=grid.demo.sas.com;
%let action=add;
/* %let action=remove; */

/* Define a data set with the list of servers you want to add the host. */
data work.servers;
    length name $ 255;
    call missing (of _character_);
    input;
    name=_infile_;
    datalines;
Object Spawner - grid
SASApp - Pooled Workspace Server
SASApp - Stored Process Server
SASApp - Workspace Server
    ;;
run;
/* End edit. */

/* Connect to Metadata Server */

options
  metaserver="&metaserve"
  metaport=&metaport
  metauser="&userid"
  metapass="&pass"
  metarepository=Foundation
  metaprotocol=BRIDGE;

/* Check if the machine is already defined. If not, create it. */

data _null_;
  length type id muri $ 50;
  call missing (of _character_);
  obj="omsobj:Machine?@Name='&machine'";
  rc=metadata_resolve(obj,type,id);

  if rc=0 then do;
    put "NOTE: Machine &machine is not defined in Metadata. Creating machine object.";
    rc=metadata_newobj("Machine",muri,"&machine");
    rc=metadata_setattr(muri,"IsHidden","0");
    rc=metadata_setattr(muri,"UsageVersion","0");
  end;
  else if rc=1 then put "NOTE: Machine &machine is already in Metadata";
  else if rc<0 then put "ERROR: Negative return code searching for machine.";
  else if rc>1 then put "ERROR: Found more than one machine with the name &machine.";
run;

/* Step through the defined Server Contexts, assigning the association. */

data _null_;
  length type id tree $ 50;
  call missing (of _character_);
  set work.servers;
  obj="omsobj:ServerComponent?@Name='"||trim(name)||"'";
  rc=metadata_resolve(obj,type,id);
  if rc ne 1 then put "ERROR: " name "is not the name of a ServerComponent in Metadata";
  else do;
      rc=metadata_getnasn(obj,"SoftwareTrees",1,tree);
      if "&action" = "add" then do;
          rc=metadata_setassn(tree,"Members","Append","omsobj:Machine?@Name='&machine'");
      end;
      else if "&action" = "remove" then do;
          rc=metadata_delobj("omsobj:Machine?@Name='&machine'");
          stop;
      end;
  end;
run;

/* Pull a list of hosts/ports defined in Metadata for Object Spawners */

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

    /* Get associated attributes for the object spawner (connection port and hosts) */

    rc=metadata_getnasn(objspwn_uri,"SoftwareTrees",1,tree_uri);
    rc=metadata_getnasn(objspwn_uri,"SourceConnections",1,conn_uri);
    rc=metadata_getattr(conn_uri,"Port",port);
    mach_cnt=metadata_getnasn(tree_uri,"Members",1,mach_uri);

    /* For each host found, get the host name and output it along with the port number to the dataset. */

    do m=1 to mach_cnt;
      rc=metadata_getnasn(tree_uri,"Members",m,mach_uri);
      rc=metadata_getattr(mach_uri,"Name",host_name);
      output;
    end;
  end;
  else put "No Object Spawners defined in Metadata.";
run;

/* WORK.OBJSPAWN now contains a list of hosts running Object Spawners. */

/* Create a macro to run a refresh on each spawner. */

%macro refreshspawn();

/* Count how many Object Spawners are defined in WORK.OBJSPAWN as a Macro variable. */

proc sql noprint;
  select count(*) into :nobjs from work.objspawn;
quit;

%if &nobjs > 0 %then %do; /* If hosts were found, extract them as macro variables. */

proc sql noprint;
  select host_name into:host1-:host%left(&nobjs) from work.objspawn;
  select port into:port1-:port%left(&nobjs) from work.objspawn;
quit;

%end;
%else;

/* Connect to each object spawner and perform a refresh configuration. */
/* Unless the host is the new one, which has not yet been started. */

%do i=1 %to &nobjs;
%if &&host&i=&machine %then;
%else %do;
  proc iomoperate;
    connect host="&&host&i"
        port=&&port&i
        user="&userid"
        pass="&pass"
        servertype=OBJECTSPAWNER;
    REFRESH CONFIGURATION;
  quit;
    %end;
%end;
%mend refreshspawn;

/* Run the macro. */

%refreshspawn;