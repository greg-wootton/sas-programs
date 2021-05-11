/******************************************************************************/
/* In an environment with multiple Object Spawners defined, you may need to   */
/* set the same loggers on all the Object Spawners dynamically for            */
/* troubleshooting purposes. Rather than connecting to each host in SMC, this */
/* program will pull a list of defined object spawners from Metatdata and set */
/* the supplied loggers and levels for each. If some of the defined spawners  */
/* are not running, an error will be returned.                                */
/* Author: Greg Wootton Date: 26MAR2019                                       */
/******************************************************************************/

/* Metadata connection information: */

%let metaserve=meta.demo.sas.com;
%let metaport=8561;
%let userid=sasadm@saspw;
%let pass=password;

/* Define logger levels to set */
/*Edit the datalines section in the format logger level. */
/* A level of "NULL" sets the logger to inherit. */

data work.loglevel;
length logger $ 255 level $ 10;
call missing (of _character_);
input logger $ level $;
datalines;
app.tk.tkels Trace
app.tk.tkegrid Trace
Audit.Authentication Trace
App.ObjectSpawner Trace
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

/* Generate proc iomoperate stanza that includes all logger */
/* settings for use by the macro and drop it in a fileref. */
filename iomtext temp;

data _null_;
  set work.loglevel nobs=nobs;
  file iomtext;
  if _n_=1 then do;
    put  "proc iomoperate;";
    put '  connect host="&&host&i"';
    put '      port=&&port&i';
    put '      user="&userid"';
    put '      pass="&pass"';
    put '    servertype=OBJECTSPAWNER;';
  end;
  put 'set attribute category="Loggers" ' 'name="' logger+(-1)'" value="' level+(-1) '";';
  if _n_=nobs then do;
    put  "quit;";
  end;
run;
quit;

data work.objspawn;

  keep host_name port; /* Only keep hosts and port for Object Spawners. */

  /* Keep port for all host iterations within an Object Spawner definition. */
  retain port;

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

/* For each host found, get the host name and */
/* output it along with the port number to the dataset. */

    do m=1 to mach_cnt;
      rc=metadata_getnasn(tree_uri,"Members",m,mach_uri);
      rc=metadata_getattr(mach_uri,"Name",host_name);
      output;
    end;
  end;
  else put "No Object Spawners defined in Metadata.";
run;


/* WORK.OBJSPAWN now contains a list of hosts running Object Spawners. */

/* Macro below will connect to each spawner and */
/* set the specified logger and level. */

%macro setloggers();

/* Count how many Object Spawners are defined in */
/* WORK.OBJSPAWN as a Macro variable. */

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

/* Connect to each object spawner and set the logging level. */

%do i=1 %to &nobjs;
  %include iomtext;
%end;

%mend setloggers;

/* Call the macro. */

%setloggers;
