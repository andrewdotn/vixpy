/* *********************************************************************
 * Copyright (c) 2007 VMware, Inc.
 * All rights not expressly granted to you by VMware, Inc. are reserved.
 * *********************************************************************/

/* This demonstrates how to open a virtual machine,
 * power it on, and power it off.
 *
 * This uses the VixJob_Wait function to block after starting each
 * asynchronous function. This effectively makes the asynchronous
 * functions synchronous, because VixJob_Wait will not return until the
 * asynchronous function has completed.
 */

#include <stdio.h>
#include <stdlib.h>

#include "vix.h"

/*
 * Certain arguments differ when using VIX with VMware Server 2.0
 * and VMware Workstation.
 *
 * Comment out this definition to use this code with VMware Server 2.0.
 */
#define USE_WORKSTATION

#ifdef USE_WORKSTATION

#define  CONNTYPE    VIX_SERVICEPROVIDER_VMWARE_WORKSTATION

#define  HOSTNAME ""
#define  HOSTPORT 0
#define  USERNAME ""
#define  PASSWORD ""

#define  VMPOWEROPTIONS   VIX_VMPOWEROP_LAUNCH_GUI   // Launches the VMware Workstaion UI
                                                     // when powering on the virtual machine.

#define VMXPATH_INFO "where vmxpath is an absolute path to the .vmx file " \
                     "for the virtual machine."

#else    // USE_WORKSTATION

/*
 * For VMware Server 2.0
 */

#define CONNTYPE VIX_SERVICEPROVIDER_VMWARE_VI_SERVER

#define HOSTNAME "https://192.2.3.4:8333/sdk"
/*
 * NOTE: HOSTPORT is ignored, so the port should be specified as part
 * of the URL.
 */
#define HOSTPORT 0
#define USERNAME "root"
#define PASSWORD "hideme"

#define  VMPOWEROPTIONS VIX_VMPOWEROP_NORMAL

#define VMXPATH_INFO "where vmxpath is a datastore-relative path to the " \
                     ".vmx file for the virtual machine, such as "        \
                     "\"[standard] ubuntu/ubuntu.vmx\"."

#endif    // USE_WORKSTATION


/*
 * Global variables.
 */

static char *progName;


/*
 * Local functions.
 */

////////////////////////////////////////////////////////////////////////////////
static void
usage()
{
   fprintf(stderr, "Usage: %s <vmxpath>\n", progName);
   fprintf(stderr, "%s\n", VMXPATH_INFO);
}


////////////////////////////////////////////////////////////////////////////////
int
main(int argc, char **argv)
{
    VixError err;
    char *vmxPath;
    VixHandle hostHandle = VIX_INVALID_HANDLE;
    VixHandle jobHandle = VIX_INVALID_HANDLE;
    VixHandle vmHandle = VIX_INVALID_HANDLE;

    progName = argv[0];
    if (argc > 1) {
        vmxPath = argv[1];
    } else {
        usage();
        exit(EXIT_FAILURE);
    }

    printf("CONNTYPE = %d\n", CONNTYPE);
    printf("HOSTNAME = %s\n", HOSTNAME);
    printf("HOSTPORT = %d\n", HOSTPORT);
    printf("user = %s\npass = %s\n", USERNAME, PASSWORD);
    printf("INVALID = %d\n", VIX_INVALID_HANDLE);

    jobHandle = VixHost_Connect(VIX_API_VERSION,
                                CONNTYPE,
                                HOSTNAME, // *hostName,
                                HOSTPORT, // hostPort,
                                USERNAME, // *userName,
                                PASSWORD, // *password,
                                0, // options,
                                VIX_INVALID_HANDLE, // propertyListHandle,
                                NULL, // *callbackProc,
                                NULL); // *clientData);
    err = VixJob_Wait(jobHandle, 
                      VIX_PROPERTY_JOB_RESULT_HANDLE, 
                      &hostHandle,
                      VIX_PROPERTY_NONE);
    if (VIX_FAILED(err)) {
        printf("fail 1\n");
        goto abort;
    }

    Vix_ReleaseHandle(jobHandle);
    jobHandle = VixVM_Open(hostHandle,
                           vmxPath,
                           NULL, // VixEventProc *callbackProc,
                           NULL); // void *clientData);
    err = VixJob_Wait(jobHandle, 
                      VIX_PROPERTY_JOB_RESULT_HANDLE, 
                      &vmHandle,
                      VIX_PROPERTY_NONE);
    if (VIX_FAILED(err)) {
        printf("fail 2\n");
        goto abort;
    }

    Vix_ReleaseHandle(jobHandle);
    jobHandle = VixVM_PowerOn(vmHandle,
                              VMPOWEROPTIONS,
                              VIX_INVALID_HANDLE,
                              NULL, // *callbackProc,
                              NULL); // *clientData);
    err = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    if (VIX_FAILED(err)) {
        printf("fail 3\n");
        goto abort;
    }

    // Vix_ReleaseHandle(jobHandle);
    // jobHandle = VixVM_PowerOff(vmHandle,
    //                            VIX_VMPOWEROP_NORMAL,
    //                            NULL, // *callbackProc,
    //                            NULL); // *clientData);
    // err = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    // if (VIX_FAILED(err)) {
    //     printf("fail 4\n");
    //     goto abort;
    // }
    // sleep(2);

    printf("Success!?!\n");

abort:
    Vix_ReleaseHandle(jobHandle);
    Vix_ReleaseHandle(vmHandle);

    VixHost_Disconnect(hostHandle);

    return 0;
}
