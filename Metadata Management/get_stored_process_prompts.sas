/******************************************************************************/
/* This program pulls each prompt associated with a stored process.           */
/* Author: Greg Wootton Date: 10JAN2017                                       */
/******************************************************************************/

/* Specify connection information  */

options
  metaserver="<hostname>"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="<password>"
  metarepository=Foundation
  metaprotocol=BRIDGE;

/* -- end edit -- */

data work.prompts;

  /* define and initialize variables */

  length
  type $ 13
  id $ 17
  stp_uri $ 39
  stp_name $ 255
  pge_uri $ 37
  p_uri $ 50
  p_name $ 50
  ;

  call missing(type,id,stp_uri,stp_name,pge_uri,p_uri,p_name);

  /* Query definition: ClassifierMap of type "StoredProcess" */

  stp_obj="omsobj:ClassifierMap?ClassifierMap[@PublicType='StoredProcess']";

  /* Count the number of stored processes defined in Metadata. */

  stp_count=metadata_resolve(stp_obj,type,id);

  put "Found " stp_count "Stored Processes.";

  if stp_count > 0 then do n=1 to stp_count;

    rc1=metadata_getnobj(stp_obj,n,stp_uri);
    /* Get the name of the stored process. */
    rc2=metadata_getattr(stp_uri,"Name",stp_name);
    /* Get the stored process' associated embedded prompt group. */
    rc3=metadata_getnasn(stp_uri,"Prompts",1,pge_uri);
    /* Count the number of prompts in that prompt group. */
    prompt_count=metadata_getnasn(pge_uri,"ReferencedPrompts",1,p_uri);
    /* If any prompts are in the group, pull the name of them. */
    if prompt_count > 0 then do m=1 to prompt_count;
      rc4=metadata_getnasn(pge_uri,"ReferencedPrompts",m,p_uri);
      rc5=metadata_getattr(p_uri,"Name",p_name);
      output;
    end;
    else put "No prompts found, nothing to do.";
  end;
  else put "No stored processes found, nothing to do.";
  keep stp_name p_name;
run;