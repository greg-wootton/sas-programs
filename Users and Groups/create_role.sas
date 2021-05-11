/******************************************************************************/
/* This program demonstrates how to create a role using Metadata DATA step    */
/* functions, including adding a capability to the role and assigning it to a */
/* group.                                                                     */
/* Author: Greg Wootton Date: 09OCT2020                                       */
/******************************************************************************/

data _null_;
  /**** Initialize Variables ****/
  length uri $ 38 cap_uri $ 43;
  call missing (of _character_);

  /**** Create the object. ****/
  rc=metadata_newobj("IdentityGroup",uri,"New Role Name");

  /* Add some required attributes. */
  rc=metadata_setattr(uri,"PublicType","Role");
  rc=metadata_setattr(uri,"GroupType","ROLE");
  rc=metadata_setattr(uri,"UsageVersion","1000000.0");
  rc=metadata_setattr(uri,"IsHidden","0");

  /* Add some optional attributes. */
  rc=metadata_setattr(uri,"Desc","This is the description of the new role");
  rc=metadata_setattr(uri,"DisplayName","This is the display name of the role");

  /**** Add a capability. ****/

  /* Define the search for the access control entry for the cability */
  cap_obj="omsobj:AccessControlEntry?AccessControlEntry[Objects/ApplicationAction[@Name='Server Manager']]";

  /* Pull it's URI into the variable cap_uri */
  rc=metadata_getnobj(cap_obj,1,cap_uri);

  /* Add the capability association to the role. */
  rc=metadata_setassn(uri,"AccessControlEntries","APPEND",cap_uri);

  /**** Add the Role to a Group ****/
  rc=metadata_setassn(uri,"MemberIdentities","APPEND","omsobj:IdentityGroup?@Name='group1'");
run;