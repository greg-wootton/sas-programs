/******************************************************************************/
/* This program pulls a list of ACTs and their associations.                  */
/* Author: Greg Wootton Date: 07NOV2018                                       */
/******************************************************************************/

/* Edit Metadata connection information. */

options
  metaserver="meta.demo.sas.com"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="password"
  metarepository=Foundation
  metaprotocol=bridge;
/* End edit. */

data _null_;
/* Initialize variables */
length type $ 21 id $ 17 act_uri objasn_uri $ 46
act_name folder_name ident_name $ 255 pubtype $ 6
partree_uri $ 29 ace_uri $ 43 ident_uri $ 38
perm_uri $ 35 perm_name perm_type $ 50;
call missing (of _character_);

label   act_name = "ACT Name"
    path = "SAS Folder Path";

/* Define query to find all Access Control Templates. */
act_obj="omsobj:AccessControlTemplate?@Id contains '.'";

/* Check for the presence of ACTs. */
act_count=metadata_resolve(act_obj,type,id);

/* Write notes to log. */
put "NOTE: Found " act_count "Access Control Templates.";
if act_count > 0 then put "NOTE: Checking for Associations.";

/* For each ACT, get their name. */
if act_count > 0 then do n=1 to act_count;
  rc=metadata_getnobj(act_obj,n,act_uri);
  rc=metadata_getattr(act_uri,"Name",act_name);

/* Check for Object assocations to the ACT. */
  objasn_count=metadata_getnasn(act_uri,"Objects",1,objasn_uri);
  if objasn_count > -1 then do;
    put;
    put "NOTE: Found " objasn_count "associated objects (may not be folders) to the ACT " act_name;
    end;

/* If any Object associations are found, */
/* get the association and check if it is a folder. */

  if objasn_count > 0 then do i=1 to objasn_count;
    rc=metadata_getnasn(act_uri,"Objects",i,objasn_uri);
    rc=metadata_getattr(objasn_uri,"PublicType",pubtype);
    if pubtype = "Folder" then do;

/* If it is a folder, get it's full path, and write a line to the data set. */

      rc=metadata_getattr(objasn_uri,"Name",folder_name);
      path=catx("\",folder_name);
      parent_rc=metadata_getnasn(objasn_uri,"ParentTree",1,partree_uri);
      /* Loop to build path from parent folder objects. */
      do while (parent_rc > 0);
        rc=metadata_getattr(partree_uri,"Name",folder_name);
        path=catx("\",folder_name,path);
        parent_rc=metadata_getnasn(partree_uri,"ParentTree",1,partree_uri);
      end;
      path=cats("\",path);
      put "NOTE: ACT assigned to path: " path;
      output;
    end;
  end;

/* Check for Access Control Entry associations to the ACT. */

  ace_count=metadata_getnasn(act_uri,"AccessControlItems",1,ace_uri);
  if ace_count > -1 then put "NOTE: Found " ace_count "Access Control Entries in the ACT " act_name;

/* For each entry, get it's identity and the assigned permissions. */
  if ace_count > 0 then do o=1 to ace_count;
    rc=metadata_getnasn(act_uri,"AccessControlItems",o,ace_uri);
    rc=metadata_getnasn(ace_uri,"Identities",1,ident_uri);
    rc=metadata_getattr(ident_uri,"DisplayName",ident_name);
    if ident_name="" then rc=metadata_getattr(ident_uri,"Name",ident_name);
    put "NOTE: For Identity " ident_name "the permissions in the ACT are:";
    perm_count=metadata_getnasn(ace_uri,"Permissions",1,perm_uri);
    if perm_count > 0 then do p=1 to perm_count;
      rc=metadata_getnasn(ace_uri,"Permissions",p,perm_uri);
      rc=metadata_getattr(perm_uri,"Name",perm_name);
      rc=metadata_getattr(perm_uri,"Type",perm_type);
      put "NOTE: " perm_name perm_type;
    end;
  end;
end;
run;

