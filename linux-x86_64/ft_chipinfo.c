#include <stdio.h>
#include "ftd2xx.h"

int main(void)
{
    FT_STATUS ftStatus;
    DWORD numDevs = 0;

    // 1️⃣ Bağlı FTDI cihaz sayısını öğren
    ftStatus = FT_CreateDeviceInfoList(&numDevs);
    if (ftStatus != FT_OK) {
        printf("FT_CreateDeviceInfoList failed (status %d)\n", ftStatus);
        return 1;
    }

    printf("Found %u FTDI device(s)\n", numDevs);
    if (numDevs == 0) return 0;

    // 2️⃣ Her cihazın detay bilgilerini al
    for (DWORD i = 0; i < numDevs; i++) {
        DWORD flags = 0, type = 0, id = 0, locId = 0;
        char serial[64] = {0};
        char description[64] = {0};
        FT_HANDLE ftHandle = NULL;

        ftStatus = FT_GetDeviceInfoDetail(
            i,
            &flags,
            &type,
            &id,
            &locId,
            serial,
            description,
            &ftHandle
        );

        if (ftStatus == FT_OK) {
            printf("\nDevice %u info:\n", i);
            printf("  Flags:        0x%08X\n", flags);
            printf("  Type:         %u\n", type);
            printf("  VendorID:     0x%04X\n", (id >> 16) & 0xFFFF);
            printf("  ProductID:    0x%04X\n", id & 0xFFFF);
            printf("  Location ID:  0x%08X\n", locId);
            printf("  Serial:       %s\n", serial[0] ? serial : "(none)");
            printf("  Description:  %s\n", description[0] ? description : "(none)");
        } else {
            printf("FT_GetDeviceInfoDetail failed for device %u (status %d)\n", i, ftStatus);
        }

        // Kapalıysa aç, sonra kapat (bazı durumlarda gerekebilir)
        if (ftHandle == NULL) {
            if (FT_Open(i, &ftHandle) == FT_OK) {
                FT_Close(ftHandle);
            }
        }
    }

    return 0;
}

