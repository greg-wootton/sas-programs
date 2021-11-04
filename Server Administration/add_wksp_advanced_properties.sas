/******************************************************************************/
/* This program sets the Allow XCMD options for a given workspace server to   */
/* true, and sets the file navigation to system.                              */
/*                                                                            */
/* WARNING: This program writes to Metadata. Be sure to take a Metadata       */
/*          Backup prior to running the program.                              */
/* Author: Greg Wootton Date: 04NOV2021                                       */
/******************************************************************************/

/* Specify Metadata connection information: */

options metaserver="meta.demo.sas.com"
        metaport=8561
        metauser="sasadm@saspw"
        metapass="password";

/* Tell the program which server you would like to update. */
%let servername=SASApp - Workspace Server;

data _null_;

    /* Initialize variables. */
  length type id $ 50 suri $ 40 puri fnpuri axpuri tpuri $ 33 pturi $ 37 pname $ 255;
  call missing (of _character_);

    /* Define the query to find the workspace server defined above. */
  obj="omsobj:ServerComponent?@Name = '&servername' and @PublicType = 'Server.Workspace'";
  rc=metadata_resolve(obj,type,id);

    /* If the server is found, check the associated properties. */
  if rc = 1 then do;
    put "NOTE: Found exactly 1 Workspace Server named &servername..";
    put "NOTE: Checking if File Navigation or Allow XCMD properties are present.";
    rc=metadata_getnobj(obj,1,suri);
    rc=metadata_getnasn(suri,"Properties",1,puri);
    put "NOTE: Found " rc "associated properties for the server.";

        /* If any associated properties are found, check each one for one named "File Navigation" or "Allow XCMD" */
    if rc ge 1 then do i = 1 to rc;
      rc=metadata_getnasn(suri,"Properties",i,puri);
      rc=metadata_getattr(puri,"Name",pname);

      /* If the file navigation property is found, set its URI to a different variable. */
      if pname = "File Navigation" then do;
        put "NOTE: File Navigation property is present.";
        fnpuri=puri;
      end;

            /* If the Allow XCMD property is found, set its URI to a different variable. */
      if pname = "Allow XCMD" then do;
        put "NOTE: Allow XCMD property is present.";
        axpuri=puri;
      end;
    end;

        /* If we found a File Navigation property, just update it. */
    if length(fnpuri) = 33 then do;
      put "NOTE: Found existing File Navigation property. Setting to System ($).";
      rc=metadata_setattr(fnpuri,"DefaultValue","$");
      if rc ne 0 then do;
        put "ERROR: Failed to set attribute." rc=;
      end;
      else do;
        put "NOTE: Attribute set successfully.";
      end;
      put fnpuri=;
    end;
        /* If not, create a new property type "String" to associate with the new property. */
    else do;
      put "NOTE: No existing File Navigation property found. Creating one and setting to System.";
      put "NOTE: Creating new property type String for the new property.";
      rc=metadata_newobj("PropertyType",pturi,"String");

            /* If that is successful, create the property and associate it with that property type. */
      if rc = 0 then do;
        put "NOTE: PropertyType created successfully. Attempting to create property.";
        put pturi=;
        rc=metadata_setattr(pturi,"SQLType","12");
        rc=metadata_setattr(pturi,"UsageVersion","0");
        rc=metadata_newobj("Property",fnpuri,"File Navigation","Foundation",pturi,"TypedProperties");

                /* If we successfully created the property, create its expected attributes as well as setting the desired DefaultValue ($ = System) */
        if rc = 0 then do;
          put "NOTE: Property created successfully. Adding necessary attributes and associations.";
          rc=metadata_setattr(fnpuri,"DefaultValue","$");
          rc=metadata_setattr(fnpuri,"IsExpert","0");
          rc=metadata_setattr(fnpuri,"IsLinked","0");
          rc=metadata_setattr(fnpuri,"IsRequired","0");
          rc=metadata_setattr(fnpuri,"IsUpdateable","0");
          rc=metadata_setattr(fnpuri,"IsVisible","0");
          rc=metadata_setattr(fnpuri,"PropertyName","FileNavigation");
          rc=metadata_setattr(fnpuri,"SQLType","12");
          rc=metadata_setattr(fnpuri,"UsageVersion","0");
          rc=metadata_setattr(fnpuri,"UseValueOnly","0");
          rc=metadata_setassn(suri,"Properties","APPEND",fnpuri);
        end;
        else do;
          put "ERROR: Failed to create property." rc=;
        end;
      end;
      else do;
        put "ERROR: Failed to create PropertyType String." rc=;
      end;

    end;

        /* If we found a allow xcmd property, set it's value to true. */
    if length(axpuri) = 33 then do;
      put "NOTE: Found existing Allow XCMD property. Setting to True.";
      rc=metadata_setattr(axpuri,"DefaultValue","True");
      if rc ne 0 then do;
        put "ERROR: Failed to set attribute." rc=;
      end;
      else do;
        put "NOTE: Attribute set successfully.";
      end;
      put axpuri=;
    end;

        /* If not, create a "boolean" property type to associate with the allow xcmd property. */
    else do;
      put "NOTE: No existing Allow XCMD property found. Creating one and setting to true.";
      put "NOTE: Creating new property type Boolean for the new property.";
      rc=metadata_newobj("PropertyType",pturi,"Boolean");
            /* If creating the property type is successful, create the property. */
      if rc = 0 then do;
        put "NOTE: PropertyType created successfully. Attempting to create property.";
        put pturi=;
        rc=metadata_setattr(pturi,"SQLType","-7");
        rc=metadata_setattr(pturi,"UsageVersion","0");
        rc=metadata_newobj("Property",axpuri,"Allow XCMD","Foundation",pturi,"TypedProperties");
                /* If creating the property is successful, add its expected attributes including setting its DefaultValue to True to enable XCMD. */
        if rc = 0 then do;
          put "NOTE: Property created successfully. Adding necessary attributes and associations.";
          rc=metadata_setattr(axpuri,"DefaultValue","True");
          rc=metadata_setattr(axpuri,"IsExpert","1");
          rc=metadata_setattr(axpuri,"IsLinked","0");
          rc=metadata_setattr(axpuri,"IsRequired","0");
          rc=metadata_setattr(axpuri,"IsUpdateable","1");
          rc=metadata_setattr(axpuri,"IsVisible","1");
          rc=metadata_setattr(axpuri,"PropertyName","AllowXCMD");
          rc=metadata_setattr(axpuri,"SQLType","12");
          rc=metadata_setattr(axpuri,"UsageVersion","0");
          rc=metadata_setattr(axpuri,"UseValueOnly","0");
          rc=metadata_setassn(suri,"Properties","APPEND",axpuri);
        end;
        else do;
          put "ERROR: Failed to create property." rc=;
        end;
      end;
      else do;
        put "ERROR: Failed to create PropertyType String." rc=;
      end;
    end;

  end;
  else do;
    put "ERROR: No Workspace Server named &servername found.";
  end;
run;