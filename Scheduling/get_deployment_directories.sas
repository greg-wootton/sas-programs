/******************************************************************************/
/* This program pulls a list of Deployment Directories to Metadata.           */
/* Author: Greg Wootton Date: 09DEC2016                                       */
/******************************************************************************/

/* Define connection to Metadata. */
options
  metaserver="meta.demo.sas.com"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="password"
  metarepository=Foundation
  metaprotocol=BRIDGE;

data work.deployfiles;

  /* declare and initialize variables */
  length app_name type dir_uri app_uri dir_name file_uri file_name owner
  trans_uri resp_uri job_name $ 50 id $ 17 dir_path $ 255;
  call missing(of _character_);

  /* variables to store to table */
  keep app_name dir_name dir_path file_name owner job_name;

  /* Define a query to find deployment directories (directory objects with an */
  /* associated server context). */
  dir_obj="omsobj:Directory?Directory[@Id contains '.'][DeployedComponents/ServerContext]";
  /* Count number of directories with an associated server context. */
  dir_rc=metadata_resolve(dir_obj,type,id);

  /* if directories exist, pull data from them. */
  if dir_rc > 0 then do n=1 to dir_rc;

  rc=metadata_getnobj(dir_obj,n,dir_uri);
  rc=metadata_getnasn(dir_uri,"DeployedComponents",1,app_uri);
  rc=metadata_getattr(app_uri,"Name",app_name);
  rc=metadata_getattr(dir_uri,"Name",dir_name);
  rc=metadata_getattr(dir_uri,"DirectoryName",dir_path);

  file_rc=metadata_getnasn(dir_uri,"Files",1,file_uri);

    /* if files are associated with the directory, pull data on them. */
    if file_rc > 0 then do m=1 to file_rc;

    rc=metadata_getnasn(dir_uri,"Files",m,file_uri);
    rc=metadata_getattr(file_uri,"FileName",file_name);
    trans_rc=metadata_getnasn(file_uri,"AssociatedTransformation",1,trans_uri);

      /* if jobs are associated with the files, pull the responsible */
      /* party of that job. */
      if trans_rc > 0 then do o=1 to trans_rc;

      rc=metadata_getnasn(file_uri,"AssociatedTransformation",o,trans_uri);
      rc=metadata_getattr(trans_uri,"Name",job_name);
      rc=metadata_getnasn(trans_uri,"ResponsibleParties",1,resp_uri);
      rc=metadata_getattr(resp_uri,"Name",owner);
      output;
      end;
      else put "INFO: No Associations Found";
    end;
    else put "INFO: No Associated Files Found";

  end;
  else put "INFO: No Deployment Directories Found";
run;

proc print data=deployfiles; run;
