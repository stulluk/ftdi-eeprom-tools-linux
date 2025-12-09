#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ftd2xx.h"

int main(int argc, char *argv[])
{
    if (argc != 2) {
        printf("Usage: sudo %s <new_serial>\n", argv[0]);
        return 1;
    }

    char *new_serial = argv[1];
    if (strlen(new_serial) > 16) {
        printf("Error: Serial number too long (max 16 chars)\n");
        return 1;
    }

    FT_STATUS ftStatus;
    FT_HANDLE ftHandle;
    FT_PROGRAM_DATA ftData;

    char manufacturer[64];
    char manufacturerId[16];
    char description[64];
    char serialNumber[16];

    // Initialize FT_PROGRAM_DATA
    memset(&ftData, 0, sizeof(ftData));
    ftData.Signature1 = 0x00000000;
    ftData.Signature2 = 0xffffffff;
    ftData.Version = 0x00000002;  // for FT232R and newer

    ftData.Manufacturer = manufacturer;
    ftData.ManufacturerId = manufacturerId;
    ftData.Description = description;
    ftData.SerialNumber = serialNumber;

    printf("=== FTDI EEPROM Serial Programmer ===\n");

    DWORD numDevs = 0;
    ftStatus = FT_CreateDeviceInfoList(&numDevs);
    if (ftStatus != FT_OK || numDevs == 0) {
        printf("No FTDI devices found.\n");
        return 1;
    }

    printf("Found %u FTDI device(s)\n", numDevs);

    ftStatus = FT_Open(0, &ftHandle);
    if (ftStatus != FT_OK) {
        printf("FT_Open failed (%d)\n", ftStatus);
        return 1;
    }

    // Read current EEPROM contents
    ftStatus = FT_EE_Read(ftHandle, &ftData);
    if (ftStatus != FT_OK) {
        printf("FT_EE_Read failed (%d)\n", ftStatus);
        FT_Close(ftHandle);
        return 1;
    }

    printf("Current serial: %s\n", ftData.SerialNumber);

    // Update serial number
    strncpy(ftData.SerialNumber, new_serial, sizeof(serialNumber)-1);
    ftData.SerialNumber[sizeof(serialNumber)-1] = '\0';

    printf("Programming new serial: %s\n", ftData.SerialNumber);

    ftStatus = FT_EE_Program(ftHandle, &ftData);
    if (ftStatus != FT_OK) {
        printf("FT_EE_Program failed (%d)\n", ftStatus);
        FT_Close(ftHandle);
        return 1;
    }

    printf("✅ EEPROM updated successfully.\n");

    FT_Close(ftHandle);
    return 0;
}

