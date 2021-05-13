/******************************************************************************/
/* This program creates authentication domains using PROC METADATA.           */
/* Author: Greg Wootton Date: 02MAY2017                                       */
/******************************************************************************/

/* Edit with your Metadata host name and credentials. */
options
  metaserver="meta.demo.sas.com"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="Password"
  metarepository=Foundation
  metaprotocol=BRIDGE;
/* End Edit */

PROC METADATA
in='
<AddMetadata>
  <Metadata>
    <AuthenticationDomain Name="AuthDomain1" Desc="Description for AuthDomain1" PublicType="AuthenticationDomain" UsageVersion="1000000"/>
    <AuthenticationDomain Name="AuthDomain2" Desc="Description for AuthDomain2" PublicType="AuthenticationDomain" UsageVersion="1000000"/>
    <AuthenticationDomain Name="AuthDomainn" Desc="Description for AuthDomain3" PublicType="AuthenticationDomain" UsageVersion="1000000"/>
  </Metadata>
  <Reposid>$METAREPOSITORY</Reposid>
  <NS>SAS</NS>
  <Flags>268435456</Flags>
  <Options/>
</AddMetadata>
';
RUN;
