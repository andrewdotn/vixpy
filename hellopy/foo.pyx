import os.path
import time

from threading import Thread

START_TIME = time.time()

VIX_INVALID_HANDLE   = 0
VIX_VMDELETE_DISK_FILES     = 0x0002

VIX_OK = 0

VIX_EVENTTYPE_JOB_COMPLETED          = 2
VIX_EVENTTYPE_JOB_PROGRESS           = 3
VIX_EVENTTYPE_FIND_ITEM              = 8
VIX_EVENTTYPE_CALLBACK_SIGNALLED     = 2 # Deprecated

VIX_PROPERTY_JOB_RESULT_ERROR_CODE                 = 3000


cdef extern from "vix.h":

    ctypedef int VixHandle

    ctypedef int VixHostOptions
    ctypedef int VixEventType
    ctypedef int VixError

    cdef enum VixServiceProvider:
        VIX_SERVICEPROVIDER_DEFAULT                   = 1
        VIX_SERVICEPROVIDER_VMWARE_SERVER             = 2
        VIX_SERVICEPROVIDER_VMWARE_WORKSTATION        = 3
        VIX_SERVICEPROVIDER_VMWARE_PLAYER             = 4
        VIX_SERVICEPROVIDER_VMWARE_VI_SERVER          = 10
        VIX_SERVICEPROVIDER_VMWARE_WORKSTATION_SHARED = 11

    ctypedef int VixPropertyID
    cdef enum:
        VIX_PROPERTY_JOB_RESULT_HANDLE                     = 3010
        VIX_PROPERTY_NONE                                  = 0

    cdef enum VixVMPowerOpOptions:
        VIX_VMPOWEROP_NORMAL                      = 0
        VIX_VMPOWEROP_FROM_GUEST                  = 0x0004
        VIX_VMPOWEROP_SUPPRESS_SNAPSHOT_POWERON   = 0x0080
        VIX_VMPOWEROP_LAUNCH_GUI                  = 0x0200
        VIX_VMPOWEROP_START_VM_PAUSED             = 0x1000

    ctypedef int VixCloneType
    cdef enum:
       VIX_CLONETYPE_FULL       = 0
       VIX_CLONETYPE_LINKED     = 1

    cdef enum VixRunProgramOptions:
           VIX_RUNPROGRAM_RETURN_IMMEDIATELY   = 0x0001
           VIX_RUNPROGRAM_ACTIVATE_WINDOW      = 0x0002


    ctypedef void VixEventProc(VixHandle handle,
                               VixEventType eventType,
                               VixHandle moreEventInfo,
                               void *clientData)

    cdef const char* Vix_GetErrorText(VixError err,
                                      const char *locale);

    cdef VixError Vix_GetProperties(VixHandle handle,
                                    VixPropertyID firstPropertyID, ...);

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

    cdef void VixHost_Disconnect(VixHandle hostHandle);

    cdef VixHandle VixJob_Wait(VixHandle jobHandle,
                               VixPropertyID, ...) nogil

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

    cdef VixHandle VixVM_CopyFileFromGuestToHost(VixHandle vmHandle,
                                        const char *hostPathName,
                                        const char *guestPathName,
                                        int options,
                                        VixHandle propertyListHandle,
                                        VixEventProc *callbackProc,
                                        void *clientData);


    cdef VixHandle VixVM_Delete(VixHandle vmHandle,
                       int options,
                       VixEventProc *callbackProc,
                       void *clientData);

##

class Closeable():
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()

def _vix_format_error(errCode):
    return "Vix operation failed with code %d: %s" % (
        errCode, Vix_GetErrorText(errCode, NULL).decode('UTF-8'))

def _vix_check_error(retCode):
    if retCode != VIX_OK:
        raise Exception(_vix_format_error(retCode))

def _vix_wait_job_and_check_error(jobHandle):
    cdef VixHandle handle = jobHandle
    try:
        with nogil:
            retCode = VixJob_Wait(handle, VIX_PROPERTY_NONE)
        _vix_check_error(retCode)
    finally:
        Vix_ReleaseHandle(jobHandle)

class VixHost(Closeable):

    def __init__(self):
        cdef VixHandle hostHandle = VIX_INVALID_HANDLE
        jobHandle = VixHost_Connect(-1,
                   VIX_SERVICEPROVIDER_VMWARE_WORKSTATION,
                   "",
                   0,
                   "",
                   "",
                   0,
                   VIX_INVALID_HANDLE,
                   NULL,
                   NULL)
        try:
            _vix_check_error(VixJob_Wait(jobHandle,
                            VIX_PROPERTY_JOB_RESULT_HANDLE,
                            &hostHandle,
                            VIX_PROPERTY_NONE))
            self.hostHandle = hostHandle
        finally:
            Vix_ReleaseHandle(jobHandle)

    def close(self):
        VixHost_Disconnect(self.hostHandle)

class VixVm(Closeable):

    def __init__(self, host, path):
        self.host = host
        self.path = path

        cdef VixHandle vmHandle = VIX_INVALID_HANDLE

        jobHandle = VixVM_Open(self.host.hostHandle,
                   path.encode('UTF-8'), NULL, NULL)
        try:
            _vix_check_error(VixJob_Wait(jobHandle,
                                          VIX_PROPERTY_JOB_RESULT_HANDLE,
                                          &vmHandle,
                                          VIX_PROPERTY_NONE))
            self.vmHandle = vmHandle
        finally:
            Vix_ReleaseHandle(jobHandle)

    def close(self):
        print "Closing", self
        Vix_ReleaseHandle(self.vmHandle)

    def power_on(self):
        print "power_on(%s)" % str(self)
        _vix_wait_job_and_check_error(VixVM_PowerOn(
            self.vmHandle,
            VIX_VMPOWEROP_NORMAL,
            VIX_INVALID_HANDLE,
            NULL,
            NULL))
        print "power_on(%s) done" % str(self)

    def power_off(self):
        print "power_off(%s)" % str(self)
        _vix_wait_job_and_check_error(VixVM_PowerOff(
            self.vmHandle,
            VIX_VMPOWEROP_NORMAL,
            NULL,
            NULL))
        print "power_off(%s) done" % str(self)

    def wait_for_tools(self, timeout=30):
        print "wait_for_tools(%s)" % str(self)
        _vix_wait_job_and_check_error(VixVM_WaitForToolsInGuest(
            self.vmHandle, timeout, NULL, NULL))
        print "wait_for_tools(%s) done" % str(self)

    def clone(self, dest, linked=True):
        print "clone(%s)" % str(self)
        cdef VixCloneType cloneType
        if linked:
            cloneType  = VIX_CLONETYPE_LINKED
        else:
            cloneType  = VIX_CLONETYPE_FULL

        _vix_wait_job_and_check_error(VixVM_Clone(
            self.vmHandle,
            VIX_INVALID_HANDLE,
            cloneType,
            dest.encode('UTF-8'),
            0,
            VIX_INVALID_HANDLE,
            NULL,
            NULL))
        print "clone(%s) done" % str(self)

    def delete(self):
        print "delete(%s)" % str(self)
        _vix_wait_job_and_check_error(VixVM_Delete(
            self.vmHandle,
            2,
            NULL,
            NULL))
        print "delete(%s) done" % str(self)

    def __str__(self):
        return "VixVM<%s>" % self.path

##

with VixHost() as h:
    print "Host handle", h.hostHandle

    vmx_path = os.path.expanduser(
        "~/Virtual Machines.localized/vixpy-base.vmwarevm/vixpy-base.vmx")

    with VixVm(h, vmx_path) as base_vm:

        def do_stuff(i):
            def func():
                clone_path = os.path.expanduser(
                    "~/Virtual Machines.localized/vixpy-clone%d.vmwarevm/vixpy-clone%d.vmx" % (i, i))
                base_vm.clone(clone_path)

                with VixVm(h, clone_path) as child:
                    child.power_on()
                    child.wait_for_tools()
                    child.power_off()
                    child.delete()

            return func

        threads = []
        for i in range(0, 4):
            threads.append(Thread(target=do_stuff(i)))
        for t in threads:
            t.start()
        for t in threads:
            t.join()

END_TIME = time.time()

print "%.3fs elapsed" % (END_TIME - START_TIME)
