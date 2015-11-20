print "hello, world"

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

def blah():
    x = VixHost_Connect(-1,
                   VIX_SERVICEPROVIDER_VMWARE_WORKSTATION,
                   "",
                   0,
                   "",
                   "",
                   0,
                   -1,
                   NULL,
                   NULL);
    return x

print repr(blah());
