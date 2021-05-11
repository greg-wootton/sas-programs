/******************************************************************************/
/* This program pulls all grid server options from Metadata.                 */
/* Author: Greg Wootton Date: 08NOV2016                                       */
/******************************************************************************/

/* Define connection to Metadata. */
options
  metaserver="meta.demo.sas.com"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="password"
  metarepository=Foundation
  metaprotocol=BRIDGE;

data work.gridprops; /* Define dataset. */

    /* Define variables sizes and types */

    length 
    server_uri $ 40
    server_id $ 17
    server_name $ 50
    propset_name $ 50
    prop_uri $ 33
    prop_id $ 17
    prop_name $ 50
    prop_value $ 256
    propset_uri $ 36
    propset_id $ 17
    trans_uri $ 50
    trans_id $ 17
    trans_name $ 30
    transprop_uri $ 50
    transprop_id $ 17
    transprop_name $ 50
    transprop_value $ 50;

  /* Define initial values */

  call missing(of _character_);

  n=1;

  /* Get Servers */

  server_rc=metadata_getnobj("omsobj:ServerComponent?@PublicType = 'Server.Grid'",n,server_uri);

  put "Number of Grid Servers = " server_rc; put;
  put "First Grid Server URI = " server_uri;
  put;

    do while(server_rc>0); /*For each server, get associated properties */
      o=1;
      p=1;
      rc=metadata_getattr(server_uri,"Id",server_id);
      rc=metadata_getattr(server_uri,"Name",server_name);
      put "Server ID = " server_id "Server Name = " server_name;
      prop_rc=metadata_getnobj("omsobj:Property?Property[AssociatedObject/ServerComponent[@Id='"||server_id||"']]",o,prop_uri);
      put "Number of Properties = " prop_rc "First URI = " prop_uri;
      put;
      do while(prop_rc>0); /* For each property, get associated values. */
        rc=metadata_getattr(prop_uri,"Id",prop_id);
        rc=metadata_getattr(prop_uri,"Name",prop_name);
        rc=metadata_getattr(prop_uri,"DefaultValue",prop_value);
        put "Property ID = " prop_id "Property Name = " prop_name;
        put "Value = " prop_value; put; 
        if (prop_value = "") then; else output; /* If a value has been set, output the value. */
        call missing(prop_name,prop_value);
        o+1;
        prop_rc=metadata_getnobj("omsobj:Property?Property[AssociatedObject/ServerComponent[@Id='"||server_id||"']]",o,prop_uri);
      end;
      propset_rc=metadata_getnobj("omsobj:PropertySet?PropertySet[OwningObject/ServerComponent[@Id='"||server_id||"']]",p,propset_uri);
      put "Number of Property Sets = " propset_rc "First URI = " propset_uri; put;
      do while(propset_rc>0); /* For each server, get associated property sets. */
        q=1;
        rc=metadata_getattr(propset_uri,"Id",propset_id);
        rc=metadata_getattr(propset_uri,"Name",propset_name);
        put "Property Set ID = " propset_id "Name = " propset_name;
        prop_rc=metadata_getnobj("omsobj:Property?Property[AssociatedPropertySet/PropertySet[@Id='"||propset_id||"']]",q,prop_uri);
        put "Number of Associated Properties = " prop_rc "First URI = " prop_uri;
        do while(prop_rc>0); /* For each property set, get associated properties. */
          r=1;
          rc=metadata_getattr(prop_uri,"Id",prop_id);
          rc=metadata_getattr(prop_uri,"Name",prop_name);
          put "Property ID = " prop_id "Property Name = " prop_name;
          trans_rc=metadata_getnasn(prop_uri,"SourceTransformations",1,trans_uri); /* Get transformation for property. */
          put "Transformation URI =" trans_uri;
          rc=metadata_getattr(trans_uri,"Id",trans_id);
          rc=metadata_getattr(trans_uri,"Name",trans_name);
          put "Transformation ID = " trans_id "Transformation Name = " trans_name;
          transprop_rc=metadata_getnasn(trans_uri,"Properties",r,transprop_uri);
          do while(transprop_rc>0); /* For transformation, get associated properties. */ 
            rc=metadata_getattr(transprop_uri,"Name",transprop_name);
            rc=metadata_getattr(transprop_uri,"DefaultValue",transprop_value);
            put "Transformation Property Name = " transprop_name "Transformation Property Value = " transprop_value;
            if transprop_value="" then; else output; /* If set, output. */
            r+1;
            transprop_rc=metadata_getnasn(trans_uri,"Properties",r,transprop_uri);
          end;
          q+1;
          prop_rc=metadata_getnobj("omsobj:Property?Property[AssociatedPropertySet/PropertySet[@Id='"||propset_id||"']]",q,prop_uri);
        end;
        p+1;
        propset_rc=metadata_getnobj("omsobj:PropertySet?PropertySet[OwningObject/ServerComponent[@Id='"||server_id||"']]",p,propset_uri);
      end;
      n+1;
      server_rc=metadata_getnobj("omsobj:ServerComponent?@PublicType = 'Server.Grid'",n,server_uri);
    end;
label /* label fields */
  server_name = "Grid Server Name"
  prop_name = "Property"
  prop_value = "Property Setting"
  propset_name = "Grid Option Set Application Name"
  trans_name = "Grid Option Set Name"
  transprop_name = "Grid Option Set Option"
  transprop_value = "Grid Option Set Option Value";

keep server_name prop_name prop_value propset_name trans_name transprop_name transprop_value; /* drop unneeded fields */
run;
