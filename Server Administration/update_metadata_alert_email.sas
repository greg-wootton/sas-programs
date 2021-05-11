/******************************************************************************/
/* This program uses PROC IOMOPERATE to modify the Metadata Server's alert    */
/* email without requiring a restart of the Metadata Server. When the         */
/* Server is started it pulls this information from omaconfig.xml, so this    */
/* must still be updated so the new setting survives a restart.               */
/* Author: Greg Wootton Date: 05APR2017                                       */
/******************************************************************************/

/* Metadata Server Connection Settings */
/*(Metadata Server and password for unrestricted account.) */
%let metaserv=<metadata_host>;
%let metapw=<sasadm_password>;

/* New email settings. */
%let mailhost=<smtp_server_hostname>;
%let mailport=25;
%let alertemail=<email_address_to_send_alerts>;
/* End edit. */

options
  metaserver="&metaserv"
  metaport=8561
  metauser="sasadm@saspw"
  metapass="&metapw"
  metarepository=Foundation
  metaprotocol=Bridge;

/* Gather current email settings. */
PROC METADATA
  method=status
  in="<OMA ALERTEMAIL=""""
  EMAILHOST=""""
  EMAILPORT=""""
  EMAILID=""""
  SERVER_STARTED="" ""
  CURRENT_TIME="" ""
  SERVERSTARTPATH="" ""/>"
  NOREDIRECT;
RUN;

/* Send an alert email with the current settings. */
PROC METAOPERATE
  action=refresh
  options="<OMA ALERTEMAILTEST=
  ""Please disregard. This is only a test.""
  />"
  noautopause;
RUN;

/* Apply new options for the email alert. */

PROC METAOPERATE
  action=refresh
  options="<OMA
  ALERTEMAIL=""&alertemail""
  EMAILHOST=""&mailhost""
  EMAILPORT=""&mailport""
  />
  <OMA ALERTEMAILTEST=
  ""Please disregard. This is only a test (new settings).""
  />"
  noautopause noredirect;
RUN;

/* Gather current email settings again (showing the update was made). */

PROC METADATA
  method=status
  in="<OMA ALERTEMAIL=""""
  EMAILHOST=""""
  EMAILPORT=""""
  EMAILID=""""
  SERVER_STARTED="" ""
  CURRENT_TIME="" ""
  SERVERSTARTPATH="" ""/>"
  NOREDIRECT;
RUN;
