import os.path
import time

print "hello, world"

START_TIME = time.time()

VIX_INVALID_HANDLE   = 0

VIX_OK = 0

cdef extern from "vix.h":

    ctypedef int VixHandle

    ctypedef int VixHostOptions
    ctypedef int VixEventType

    cdef enum VixServiceProvider:
        VIX_SERVICEPROVIDER_DEFAULT                   = 1
        VIX_SERVICEPROVIDER_VMWARE_SERVER             = 2
        VIX_SERVICEPROVIDER_VMWARE_WORKSTATION        = 3
        VIX_SERVICEPROVIDER_VMWARE_PLAYER             = 4
        VIX_SERVICEPROVIDER_VMWARE_VI_SERVER          = 10
        VIX_SERVICEPROVIDER_VMWARE_WORKSTATION_SHARED = 11

    cdef enum VixPropertyID:
        VIX_PROPERTY_JOB_RESULT_HANDLE                     = 3010
        VIX_PROPERTY_NONE                                  = 0

    cdef enum VixVMPowerOpOptions:
        VIX_VMPOWEROP_NORMAL                      = 0
        VIX_VMPOWEROP_FROM_GUEST                  = 0x0004
        VIX_VMPOWEROP_SUPPRESS_SNAPSHOT_POWERON   = 0x0080
        VIX_VMPOWEROP_LAUNCH_GUI                  = 0x0200
        VIX_VMPOWEROP_START_VM_PAUSED             = 0x1000

    cdef enum VixCloneType:
       VIX_CLONETYPE_FULL       = 0
       VIX_CLONETYPE_LINKED     = 1

    cdef enum VixRunProgramOptions:
           VIX_RUNPROGRAM_RETURN_IMMEDIATELY   = 0x0001
           VIX_RUNPROGRAM_ACTIVATE_WINDOW      = 0x0002


    ctypedef void VixEventProc(VixHandle handle,
                                                                VixEventType
                                    eventType,
                                                                VixHandle
                                    moreEventInfo,
                                                                void
                                    *clientData)


    cdef VixHandle VixHost_Connect(int apiVersion,
                          VixServiceProvider hostType,
                          const char *hostName,
                          int hostPort,
                          const char *userName,
                          const char *password,
                          VixHostOptions options,
                          VixHandle propertyListHandle,
                          VixEventProc *callbackProc,
                          void *clientData);

    cdef VixHandle VixJob_Wait(VixHandle jobHandle,
                               VixPropertyID, ...)

    cdef void Vix_ReleaseHandle(VixHandle handle)

    cdef VixHandle VixVM_Open(VixHandle hostHandle,
                     const char *vmxFilePathName,
                     VixEventProc *callbackProc,
                     void *clientData)


    cdef VixHandle VixVM_PowerOn(VixHandle vmHandle,
                        VixVMPowerOpOptions powerOnOptions,
                        VixHandle propertyListHandle,
                        VixEventProc *callbackProc,
                        void *clientData);

    cdef VixHandle VixVM_PowerOff(VixHandle vmHandle,
                         VixVMPowerOpOptions powerOffOptions,
                         VixEventProc *callbackProc,
                         void *clientData);

    cdef VixHandle VixVM_Clone(VixHandle vmHandle,
                            VixHandle snapshotHandle,
                            VixCloneType cloneType,
                            const char *destConfigPathName,
                            int options,
                            VixHandle propertyListHandle,
                            VixEventProc *callbackProc,
                            void *clientData)

    cdef VixHandle VixVM_WaitForToolsInGuest(VixHandle vmHandle,
                                    int timeoutInSeconds,
                                    VixEventProc *callbackProc,
                                    void *clientData)

    cdef VixHandle VixVM_LoginInGuest(VixHandle vmHandle,
                   char *userName,
                   char *password,
                   int options,
                   VixEventProc *callbackProc,
                   void *clientData);

    cdef VixHandle VixVM_RunScriptInGuest(VixHandle vmHandle,
                                 const char *interpreter,
                                 const char *scriptText,
                                 int options,
                                 VixHandle propertyListHandle,
                                 VixEventProc *callbackProc,
                                 void *clientData);


def blah():
    x = VixHost_Connect(-1,
                   VIX_SERVICEPROVIDER_VMWARE_WORKSTATION,
                   "",
                   0,
                   "",
                   "",
                   0,
                   VIX_INVALID_HANDLE,
                   NULL,
                   NULL);
    print "x is %s" % x

    cdef VixHandle hostHandle
    r = VixJob_Wait(x,
                    VIX_PROPERTY_JOB_RESULT_HANDLE,
                    &hostHandle,
                    VIX_PROPERTY_NONE)

    print "VixJob_Wait return is %d" % r

    print "hostHandle is %d\n" % hostHandle

    Vix_ReleaseHandle(x)

    cdef VixHandle vmHandle

    vmxPath = os.path.expanduser(
        "~/Virtual Machines.localized/vixpy-base.vmwarevm/vixpy-base.vmx")

    jobHandle = VixVM_Open(hostHandle,
                           vmxPath.encode('UTF-8'),
                           NULL,
                           NULL)
    err = VixJob_Wait(jobHandle,
                      VIX_PROPERTY_JOB_RESULT_HANDLE,
                      &vmHandle,
                      VIX_PROPERTY_NONE)
    if err != VIX_OK:
        print "Error 0: %d" % err
        return

    Vix_ReleaseHandle(jobHandle)

    clone1path = os.path.expanduser(
        "~/Virtual Machines.localized/test.vmwarevm/vixpy-base-clone1.vmx")

    jobHandle = VixVM_Clone(vmHandle,
                            VIX_INVALID_HANDLE,
                            VIX_CLONETYPE_LINKED,
                            clone1path.encode('UTF-8'),
                            0,
                            VIX_INVALID_HANDLE,
                            NULL,
                            NULL);

    cdef VixHandle cloneVmHandle
    err = VixJob_Wait(jobHandle,
                      VIX_PROPERTY_JOB_RESULT_HANDLE,
                      &cloneVmHandle,
                      VIX_PROPERTY_NONE)
    if err != VIX_OK:
        print "Error 1: %d" % err
        return
    jobHandle = VixVM_PowerOn(cloneVmHandle,
                              VIX_VMPOWEROP_LAUNCH_GUI,
                              VIX_INVALID_HANDLE,
                              NULL,
                              NULL);
    err = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    if err != VIX_OK:
        print "Error 2: %d" % err
        return


    jobHandle = VixVM_WaitForToolsInGuest(cloneVmHandle, 30, NULL, NULL);
    err = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    if err != VIX_OK:
        print "Error 3: %d" % err
        return

    jobHandle = VixVM_LoginInGuest(cloneVmHandle,
                       "root".encode('UTF-8'),
                       "test".encode("UTF-8"),
                       0,
                       NULL, NULL)
    err = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    if err != VIX_OK:
        print "Error 4: %d" % err
        return

    jobHandle = VixVM_RunScriptInGuest(cloneVmHandle,
                                 "/bin/bash".encode("UTF-8"),
                                 "date > /tmp/foo".encode("UTF-8"),
                                 0,
                                 VIX_INVALID_HANDLE,
                                 NULL,
                                 NULL)
    err = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);
    if err != VIX_OK:
        print "Error 4: %d" % err
        return

   #  jobHandle = VixVM_PowerOn(vmHandle,
   #                            VIX_VMPOWEROP_LAUNCH_GUI,
   #                            VIX_INVALID_HANDLE,
   #                            NULL,
   #                            NULL);
   #  err = VixJob_Wait(jobHandle, VIX_PROPERTY_NONE);

   #  time.sleep(5)

   #  jobHandle = VixVM_PowerOff(vmHandle,
   #                            VIX_VMPOWEROP_NORMAL,
   #                            NULL,
   #                            NULL);

print repr(blah());

END_TIME = time.time()

print "%.3fs elapsed" % (END_TIME - START_TIME)
