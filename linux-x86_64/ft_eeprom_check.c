#include <stdio.h>
#include <string.h>
#include "ftd2xx.h"

int main(void)
{
    FT_STATUS ftStatus;
    FT_HANDLE ftHandle;
    DWORD dwSize = 0;
    FT_PROGRAM_DATA Data;
    char Manufacturer[64], ManufacturerId[64], Description[64], SerialNumber[64];

    printf("=== FTDI EEPROM Detection Test (libftd2xx 1.4.x) ===\n");

    DWORD numDevs = 0;
    ftStatus = FT_CreateDeviceInfoList(&numDevs);
    if (ftStatus != FT_OK) {
        printf("FT_CreateDeviceInfoList failed (%d)\n", ftStatus);
        return 1;
    }
    printf("Found %u FTDI device(s)\n", numDevs);
    if (numDevs == 0) return 0;

    ftStatus = FT_Open(0, &ftHandle);
    if (ftStatus != FT_OK) {
        printf("FT_Open failed (%d)\n", ftStatus);
        return 1;
    }
    printf("Device 0 opened successfully.\n");

    // User area size
    ftStatus = FT_EE_UASize(ftHandle, &dwSize);
    if (ftStatus == FT_OK)
        printf("EEPROM user area size: %u bytes\n", dwSize);
    else
        printf("FT_EE_UASize failed (%d)\n", ftStatus);

    // Prepare FT_PROGRAM_DATA struct
    memset(&Data, 0, sizeof(Data));
    Data.Signature1 = 0x00000000;
    Data.Signature2 = 0xFFFFFFFF;
    Data.Version = 5;
    Data.Manufacturer = Manufacturer;
    Data.ManufacturerId = ManufacturerId;
    Data.Description = Description;
    Data.SerialNumber = SerialNumber;
    Data.Manufacturer[0] = 0;
    Data.ManufacturerId[0] = 0;
    Data.Description[0] = 0;
    Data.SerialNumber[0] = 0;

    // EEPROM read
    ftStatus = FT_EE_Read(ftHandle, &Data);
    if (ftStatus == FT_OK) {
        printf("\nEEPROM Read OK ✅\n");
        printf("  Manufacturer : %s\n", Data.Manufacturer);
        printf("  ManufacturerId: %s\n", Data.ManufacturerId);
        printf("  Description   : %s\n", Data.Description);
        printf("  Serial        : %s\n", Data.SerialNumber);
    } else if (ftStatus == FT_EEPROM_NOT_PRESENT) {
        printf("\n❌ EEPROM not present (FT_EEPROM_NOT_PRESENT)\n");
    } else if (ftStatus == FT_OTHER_ERROR) {
        printf("\n⚠️ EEPROM access failed (FT_OTHER_ERROR)\n");
    } else {
        printf("\n⚠️ FT_EE_Read failed (status %d)\n", ftStatus);
    }

    FT_Close(ftHandle);
    printf("\nTest complete.\n");
    return 0;
}

