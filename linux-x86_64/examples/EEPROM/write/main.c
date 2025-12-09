/*
	To build use the following gcc statement 
	(assuming you have the d2xx library in the /usr/local/lib directory).
	gcc -o write main.c -L. -lftd2xx -Wl,-rpath,/usr/local/lib
*/

#include <stdio.h>
#include <sys/time.h>
#include "../../ftd2xx.h"

int main(int argc, char *argv[])
{
	FT_STATUS	ftStatus;
	FT_HANDLE	ftHandle0;
	int iport;
	FT_PROGRAM_DATA Data;
	static FT_DEVICE ftDevice;
	
	if(argc > 1) {
		sscanf(argv[1], "%d", &iport);
	}
	else {
		iport = 0;
	}
	printf("opening port %d\n", iport);
	FT_SetVIDPID(0x0403, 0x6011);
	ftStatus = FT_Open(iport, &ftHandle0);
	
	if(ftStatus != FT_OK) {
		/* 
			This can fail if the ftdi_sio driver is loaded
		 	use lsmod to check this and rmmod ftdi_sio to remove
			also rmmod usbserial
		 */
		printf("FT_Open(%d) failed\n", iport);
		return 1;
	}

	printf("ftHandle0 = %p\n", ftHandle0);

	printf("FT_Open succeeded.  Handle is %p\n", ftHandle0);

        ftStatus = FT_GetDeviceInfo(ftHandle0,
                                    &ftDevice,
                                    NULL,
                                    NULL,
                                    NULL,
                                    NULL);
        if (ftStatus != FT_OK)
        {
                printf("FT_GetDeviceType FAILED!\n");
                return 1;
        }

        printf("FT_GetDeviceInfo succeeded.  Device is type %d.\n",
               (int)ftDevice);

	Data.Signature1 = 0x00000000;
	Data.Signature2 = 0xffffffff;
	Data.VendorId = 0x0403;				
	Data.ProductId = 0x6001;
	Data.Manufacturer =  "FTDI";
	Data.ManufacturerId = "B0";
	Data.Description = "USB <-> Serial";

	printf("FT_DEVICE_BM is %d\n", FT_DEVICE_BM);
	printf("FT_DEVICE_232R is %d\n", FT_DEVICE_232R);

        if (ftDevice == FT_DEVICE_BM)
        {

		Data.Signature1 = 0x00000000;
		Data.Signature2 = 0xffffffff;
		Data.VendorId = 0x0403;				
		Data.ProductId = 0x6001;
		Data.Manufacturer =  "FTDI";
		Data.ManufacturerId = "FT232R USB UART";
		Data.Description = "USB <-> Serial";
		Data.SerialNumber = "SERTAC-WS1";		// if fixed, or NULL
		
		Data.MaxPower = 90;
		Data.PnP = 1;
		Data.SelfPowered = 0;
		Data.RemoteWakeup = 1;
		Data.Rev4 = 1;
		Data.IsoIn = 0;
		Data.IsoOut = 0;
		Data.PullDownEnable = 1;
		Data.SerNumEnable = 1;
		Data.USBVersionEnable = 0;
		Data.USBVersion = 0x110;
	}

	if (ftDevice == FT_DEVICE_232R)
        {

		Data.Description = "FT232R USB UART";
		Data.SerialNumber = "SERTAC-WS1";		// if fixed, or NULL
		Data.SerNumEnableR = 1;			// non-zero if serial number to be used
		Data.Cbus0 = 0x3;
		Data.Cbus1 = 0x2;
		Data.Cbus2 = 0x0;
		Data.Cbus3 = 0x1;
		Data.Cbus4 = 0x5;
		Data.MaxPower = 90;
		Data.RemoteWakeup = 1;
		Data.ManufacturerId = "B0";
	}

	if (ftDevice == FT_DEVICE_2232C)
        {

		Data.Signature1 = 0x00000000;
		Data.Signature2 = 0xffffffff;
		Data.VendorId = 0x0403;				
		Data.ProductId = 0x6010;
		Data.Manufacturer =  "FTDI";
		Data.ManufacturerId = "FT";
		Data.Description = "SPI";
		Data.SerialNumber = "FT123452";		// if fixed, or NULL
		
		Data.MaxPower = 200;
		Data.PnP = 1;
		Data.SelfPowered = 0;
		Data.RemoteWakeup = 0;
		Data.Rev4 = 0;
		Data.IsoIn = 0;
		Data.IsoOut = 0;
		Data.PullDownEnable = 0;
		Data.SerNumEnable = 1;
		Data.USBVersionEnable = 0;
		Data.USBVersion = 0;

		Data.Rev5 = 1;					// non-zero if Rev5 chip, zero otherwise
		Data.IsoInA = 0;				// non-zero if in endpoint is isochronous
		Data.IsoInB = 0;				// non-zero if in endpoint is isochronous
		Data.IsoOutA = 0;				// non-zero if out endpoint is isochronous
		Data.IsoOutB = 0;				// non-zero if out endpoint is isochronous
		Data.PullDownEnable5 = 0;		// non-zero if pull down enabled
		Data.SerNumEnable5 = 1;			// non-zero if serial number to be used
		Data.USBVersionEnable5 = 0;		// non-zero if chip uses USBVersion
		Data.USBVersion5 = 0x0200;		// BCD (0x0200 => USB2)
		Data.AIsHighCurrent = 0;		// non-zero if interface is high current
		Data.BIsHighCurrent = 0;		// non-zero if interface is high current
		Data.IFAIsFifo = 1;				// non-zero if interface is 245 FIFO
		Data.IFAIsFifoTar = 0;			// non-zero if interface is 245 FIFO CPU target
		Data.IFAIsFastSer = 0;			// non-zero if interface is Fast serial
		Data.AIsVCP = 0;				// non-zero if interface is to use VCP drivers
		Data.IFBIsFifo = 1;				// non-zero if interface is 245 FIFO
		Data.IFBIsFifoTar = 0;			// non-zero if interface is 245 FIFO CPU target
		Data.IFBIsFastSer = 0;			// non-zero if interface is Fast serial
		Data.BIsVCP = 0;				// non-zero if interface is to use VCP drivers
	}
	
	
	ftStatus = FT_EE_Program(ftHandle0, &Data);
	if(ftStatus != FT_OK) {
		printf("FT_EE_Program failed (%d)\n", (int)ftStatus);
		FT_Close(ftHandle0);
	}
	printf("EEPROM Written succesfully..\n");
	FT_Close(ftHandle0);
	return 0;
}
