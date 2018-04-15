/* 
 * Copyright (C) 2012-2014 Chris McClelland
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *  
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <makestuff.h>
#include <libfpgalink.h>
#include <libbuffer.h>
#include <liberror.h>
#include <libdump.h>
#include <argtable2.h>
#include <readline/readline.h>
#include <readline/history.h>
#ifdef WIN32
#include <Windows.h>
#else
#include <sys/time.h>
#include <unistd.h>

#endif

/////////////////////////////////////
/* Our includes and helper functions */

#include "new_utilities.h"
#include <time.h>
#define U32MAX 0xFFFFFFFFU

////////////////////////////////////

bool sigIsRaised(void);
void sigRegisterHandler(void);



static const char *ptr;
static bool enableBenchmarking = false;

static bool isHexDigit(char ch) {
	return
		(ch >= '0' && ch <= '9') ||
		(ch >= 'a' && ch <= 'f') ||
		(ch >= 'A' && ch <= 'F');
}

static uint16 calcChecksum(const uint8 *data, size_t length) {
	uint16 cksum = 0x0000;
	while ( length-- ) {
		cksum = (uint16)(cksum + *data++);
	}
	return cksum;
}

static bool getHexNibble(char hexDigit, uint8 *nibble) {
	if ( hexDigit >= '0' && hexDigit <= '9' ) {
		*nibble = (uint8)(hexDigit - '0');
		return false;
	} else if ( hexDigit >= 'a' && hexDigit <= 'f' ) {
		*nibble = (uint8)(hexDigit - 'a' + 10);
		return false;
	} else if ( hexDigit >= 'A' && hexDigit <= 'F' ) {
		*nibble = (uint8)(hexDigit - 'A' + 10);
		return false;
	} else {
		return true;
	}
}

static int getHexByte(uint8 *byte) {
	uint8 upperNibble;
	uint8 lowerNibble;
	if ( !getHexNibble(ptr[0], &upperNibble) && !getHexNibble(ptr[1], &lowerNibble) ) {
		*byte = (uint8)((upperNibble << 4) | lowerNibble);
		byte += 2;
		return 0;
	} else {
		return 1;
	}
}

static const char *const errMessages[] = {
	NULL,
	NULL,
	"Unparseable hex number",
	"Channel out of range",
	"Conduit out of range",
	"Illegal character",
	"Unterminated string",
	"No memory",
	"Empty string",
	"Odd number of digits",
	"Cannot load file",
	"Cannot save file",
	"Bad arguments"
};

typedef enum {
	FLP_SUCCESS,
	FLP_LIBERR,
	FLP_BAD_HEX,
	FLP_CHAN_RANGE,
	FLP_CONDUIT_RANGE,
	FLP_ILL_CHAR,
	FLP_UNTERM_STRING,
	FLP_NO_MEMORY,
	FLP_EMPTY_STRING,
	FLP_ODD_DIGITS,
	FLP_CANNOT_LOAD,
	FLP_CANNOT_SAVE,
	FLP_ARGS,
	FLP_TIMEOUT
} ReturnCode;

static ReturnCode doRead(
	struct FLContext *handle, uint8 chan, uint32 length, FILE *destFile, uint16 *checksum,
	const char **error, uint32 timeout)
{
	ReturnCode retVal = FLP_SUCCESS;
	uint32 bytesWritten;
	FLStatus fStatus;
	uint32 chunkSize;
	const uint8 *recvData;
	const uint8 *ptr;
	uint16 csVal = 0x0000;
	#define READ_MAX 65536

	// Read first chunk
	chunkSize = length >= READ_MAX ? READ_MAX : length;
	// fStatus = flReadChannelAsyncSubmit(handle, chan, chunkSize, NULL, error);
	fStatus = customflReadChannel(handle, chan, chunkSize, &recvData, error, timeout);
	printf("%d,,,,%d\n", fStatus , FL_TIMEOUT);
	fflush(stdout);

	// Check for timeout
	if(fStatus == FL_TIMEOUT){
		printf("doread to parseLine\n");
		fflush(stdout);
		retVal = FLP_TIMEOUT;
		return retVal;
	}

	CHECK_STATUS(fStatus, FLP_LIBERR, cleanup, "doRead()");
	// length = length - chunkSize;

	// while ( length ) {
	// 	// Read chunk N
	// 	chunkSize = length >= READ_MAX ? READ_MAX : length;
	// 	// fStatus = flReadChannelAsyncSubmit(handle, chan, chunkSize, NULL, error);
	// 	fStatus = customflReadChannelAsyncSubmit(handle, chan, chunkSize, NULL, error, timeout);
	// 	CHECK_STATUS(fStatus, FLP_LIBERR, cleanup, "doRead()");
	// 	length = length - chunkSize;
		
	// 	// Await chunk N-1
	// 	// fStatus = flReadChannelAsyncAwait(handle, &recvData, &actualLength, &actualLength, error);
	// 	fStatus = customflReadChannelAsyncAwait(handle, &recvData, &actualLength, &actualLength, error);
		
	// 	// Check for timeout
	// 	// if(fStatus == FL_TIMEOUT){
	// 	// 	retVal = FLP_TIMEOUT;
	// 	// 	return retVal;
	// 	// }
	// 	CHECK_STATUS(fStatus, FLP_LIBERR, cleanup, "doRead()");

	// 	// Write chunk N-1 to file
	// 	bytesWritten = (uint32)fwrite(recvData, 1, actualLength, destFile);
	// 	CHECK_STATUS(bytesWritten != actualLength, FLP_CANNOT_SAVE, cleanup, "doRead()");

	// 	// Checksum chunk N-1
	// 	chunkSize = actualLength;
	// 	ptr = recvData;
	// 	while ( chunkSize-- ) {
	// 		csVal = (uint16)(csVal + *ptr++);
	// 	}
	// }

	// Await last chunk
	// fStatus = flReadChannelAsyncAwait(handle, &recvData, &actualLength, &actualLength, error);
	// fStatus = customflReadChannelAsyncAwait(handle, &recvData, &actualLength, &actualLength, error);
	
	// // Check for timeout
	// if(fStatus == FL_TIMEOUT){
	// 	retVal = FLP_TIMEOUT;
	// 	return retVal;
	// }
	CHECK_STATUS(fStatus, FLP_LIBERR, cleanup, "doRead()");
	
	// Write last chunk to file
	printf("%d\n", sizeof(*recvData));
	fflush(stdout);
	printf(*recvData);
	fflush(stdout);
	bytesWritten = (uint32)fwrite(recvData, 1, length, destFile);
	// CHECK_STATUS(bytesWritten != actualLength, FLP_CANNOT_SAVE, cleanup, "doRead()");

	// // Checksum last chunk
	// chunkSize = actualLength;
	// ptr = recvData;
	// while ( chunkSize-- ) {
	// 	csVal = (uint16)(csVal + *ptr++);
	// }
	
	// // Return checksum to caller
	// *checksum = csVal;
cleanup:
	return retVal;
}

static ReturnCode doWrite(
	struct FLContext *handle, uint8 chan, FILE *srcFile, size_t *length, uint16 *checksum,
	const char **error)
{
	ReturnCode retVal = FLP_SUCCESS;
	size_t bytesRead, i;
	FLStatus fStatus;
	const uint8 *ptr;
	uint16 csVal = 0x0000;
	size_t lenVal = 0;
	#define WRITE_MAX (65536 - 5)
	uint8 buffer[WRITE_MAX];

	do {
		// Read Nth chunk
		bytesRead = fread(buffer, 1, WRITE_MAX, srcFile);
		if ( bytesRead ) {
			// Update running total
			lenVal = lenVal + bytesRead;

			// Submit Nth chunk
			fStatus = flWriteChannelAsync(handle, chan, bytesRead, buffer, error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup, "doWrite()");

			// Checksum Nth chunk
			i = bytesRead;
			ptr = buffer;
			while ( i-- ) {
				csVal = (uint16)(csVal + *ptr++);
			}
		}
	} while ( bytesRead == WRITE_MAX );

	// Wait for writes to be received. This is optional, but it's only fair if we're benchmarking to
	// actually wait for the work to be completed.
	fStatus = flAwaitAsyncWrites(handle, error);
	CHECK_STATUS(fStatus, FLP_LIBERR, cleanup, "doWrite()");

	// Return checksum & length to caller
	*checksum = csVal;
	*length = lenVal;
cleanup:
	return retVal;
}

static int parseLine(struct FLContext *handle, const char *line, const char **error, uint32 timeout) {
	ReturnCode retVal = FLP_SUCCESS, status;
	FLStatus fStatus;
	struct Buffer dataFromFPGA = {0,};
	BufferStatus bStatus;
	uint8 *data = NULL;
	char *fileName = NULL;
	FILE *file = NULL;
	double totalTime, speed;
	#ifdef WIN32
		LARGE_INTEGER tvStart, tvEnd, freq;
		DWORD_PTR mask = 1;
		SetThreadAffinityMask(GetCurrentThread(), mask);
		QueryPerformanceFrequency(&freq);
	#else
		struct timeval tvStart, tvEnd;
		long long startTime, endTime;
	#endif
	bStatus = bufInitialise(&dataFromFPGA, 1024, 0x00, error);
	CHECK_STATUS(bStatus, FLP_LIBERR, cleanup);
	ptr = line;
	do {
		while ( *ptr == ';' ) {
			ptr++;
		}
		switch ( *ptr ) {
		case 'r':{
			uint32 chan;
			uint32 length = 1;
			char *end;
			ptr++;
			
			// Get the channel to be read:
			errno = 0;
			chan = (uint32)strtoul(ptr, &end, 16);
			CHECK_STATUS(errno, FLP_BAD_HEX, cleanup);

			// Ensure that it's 0-127
			CHECK_STATUS(chan > 127, FLP_CHAN_RANGE, cleanup);
			ptr = end;

			// Only three valid chars at this point:
			CHECK_STATUS(*ptr != '\0' && *ptr != ';' && *ptr != ' ', FLP_ILL_CHAR, cleanup);

			if ( *ptr == ' ' ) {
				ptr++;

				// Get the read count:
				errno = 0;
				length = (uint32)strtoul(ptr, &end, 16);
				CHECK_STATUS(errno, FLP_BAD_HEX, cleanup);
				ptr = end;
				
				// Only three valid chars at this point:
				CHECK_STATUS(*ptr != '\0' && *ptr != ';' && *ptr != ' ', FLP_ILL_CHAR, cleanup);
				if ( *ptr == ' ' ) {
					const char *p;
					const char quoteChar = *++ptr;
					CHECK_STATUS(
						(quoteChar != '"' && quoteChar != '\''),
						FLP_ILL_CHAR, cleanup);
					
					// Get the file to write bytes to:
					ptr++;
					p = ptr;
					while ( *p != quoteChar && *p != '\0' ) {
						p++;
					}
					CHECK_STATUS(*p == '\0', FLP_UNTERM_STRING, cleanup);
					fileName = malloc((size_t)(p - ptr + 1));
					CHECK_STATUS(!fileName, FLP_NO_MEMORY, cleanup);
					CHECK_STATUS(p - ptr == 0, FLP_EMPTY_STRING, cleanup);
					strncpy(fileName, ptr, (size_t)(p - ptr));
					fileName[p - ptr] = '\0';
					ptr = p + 1;
				}
			}
			if ( fileName ) {
				uint16 checksum = 0x0000;

				// Open file for writing
				file = fopen(fileName, "wb");
				CHECK_STATUS(!file, FLP_CANNOT_SAVE, cleanup);
				free(fileName);
				fileName = NULL;

				size_t oldLength = dataFromFPGA.length;
				bStatus = bufAppendConst(&dataFromFPGA, 0x00, length, error);
				CHECK_STATUS(bStatus, FLP_LIBERR, cleanup);

				#ifdef WIN32
					QueryPerformanceCounter(&tvStart);
					status = doRead(handle, (uint8)chan, length, file, &checksum, error, timeout);
					QueryPerformanceCounter(&tvEnd);
					totalTime = (double)(tvEnd.QuadPart - tvStart.QuadPart);
					totalTime /= freq.QuadPart;
					speed = (double)length / (1024*1024*totalTime);
				#else
					gettimeofday(&tvStart, NULL);
					// status = doRead(handle, (uint8)chan, length, file, &checksum, error, timeout);
					fStatus = customflReadChannel(handle, (uint8)chan, length, dataFromFPGA.data + oldLength, error, timeout);

					gettimeofday(&tvEnd, NULL);
					startTime = tvStart.tv_sec;
					startTime *= 1000000;
					startTime += tvStart.tv_usec;
					endTime = tvEnd.tv_sec;
					endTime *= 1000000;
					endTime += tvEnd.tv_usec;
					totalTime = (double)(endTime - startTime);
					totalTime /= 1000000;  // convert from uS to S.
					speed = (double)length / (1024*1024*totalTime);
				#endif
				if ( enableBenchmarking ) {
					printf(
						"Read %d bytes (checksum 0x%04X) from channel %d at %f MiB/s\n",
						length, checksum, chan, speed);
				}
				
				if(fStatus == FL_TIMEOUT){
					retVal = FLP_TIMEOUT;
					// printf("parseLine to cleanup\n");
					// fflush(stdout);
					goto cleanup;
				}
				CHECK_STATUS(status, status, cleanup);

				// write
				int bytesWritten = (uint32)fwrite(dataFromFPGA.data, 1, dataFromFPGA.length, file);	
				// Close the file
				fclose(file);
				file = NULL;
				CHECK_STATUS(true, status, cleanup);
			} else {
				size_t oldLength = dataFromFPGA.length;
				bStatus = bufAppendConst(&dataFromFPGA, 0x00, length, error);
				CHECK_STATUS(bStatus, FLP_LIBERR, cleanup);
				#ifdef WIN32
					QueryPerformanceCounter(&tvStart);
					// fStatus = flReadChannel(handle, (uint8)chan, length, dataFromFPGA.data + oldLength, error);
					fStatus = customflReadChannel(handle, (uint8)chan, length, dataFromFPGA.data + oldLength, error, timeout);
					QueryPerformanceCounter(&tvEnd);
					totalTime = (double)(tvEnd.QuadPart - tvStart.QuadPart);
					totalTime /= freq.QuadPart;
					speed = (double)length / (1024*1024*totalTime);
				#else
					gettimeofday(&tvStart, NULL);
					// fStatus = flReadChannel(handle, (uint8)chan, length, dataFromFPGA.data + oldLength, error);
					fStatus = customflReadChannel(handle, (uint8)chan, length, dataFromFPGA.data + oldLength, error, timeout);
					gettimeofday(&tvEnd, NULL);
					startTime = tvStart.tv_sec;
					startTime *= 1000000;
					startTime += tvStart.tv_usec;
					endTime = tvEnd.tv_sec;
					endTime *= 1000000;
					endTime += tvEnd.tv_usec;
					totalTime = (double)(endTime - startTime);
					totalTime /= 1000000;  // convert from uS to S.
					speed = (double)length / (1024*1024*totalTime);
				#endif
				if ( enableBenchmarking ) {
					printf(
						"Read %d bytes (checksum 0x%04X) from channel %d at %f MiB/s\n",
						length, calcChecksum(dataFromFPGA.data + oldLength, length), chan, speed);
				}
				
				if(fStatus == FL_TIMEOUT){
					retVal = FLP_TIMEOUT;
					// printf("to cleanup\n");
					// fflush(stdout);
					goto cleanup;
				}
				CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			}
			break;
		}
		case 'w':{
			unsigned long int chan;
			size_t length = 1, i;
			char *end, ch;
			const char *p;
			ptr++;
			
			// Get the channel to be written:
			errno = 0;
			chan = strtoul(ptr, &end, 16);
			CHECK_STATUS(errno, FLP_BAD_HEX, cleanup);

			// Ensure that it's 0-127
			CHECK_STATUS(chan > 127, FLP_CHAN_RANGE, cleanup);
			ptr = end;

			// There must be a space now:
			CHECK_STATUS(*ptr != ' ', FLP_ILL_CHAR, cleanup);

			// Now either a quote or a hex digit
		   ch = *++ptr;
			if ( ch == '"' || ch == '\'' ) {
				uint16 checksum = 0x0000;

				// Get the file to read bytes from:
				ptr++;
				p = ptr;
				while ( *p != ch && *p != '\0' ) {
					p++;
				}
				CHECK_STATUS(*p == '\0', FLP_UNTERM_STRING, cleanup);
				fileName = malloc((size_t)(p - ptr + 1));
				CHECK_STATUS(!fileName, FLP_NO_MEMORY, cleanup);
				CHECK_STATUS(p - ptr == 0, FLP_EMPTY_STRING, cleanup);
				strncpy(fileName, ptr, (size_t)(p - ptr));
				fileName[p - ptr] = '\0';
				ptr = p + 1;  // skip over closing quote

				// Open file for reading
				file = fopen(fileName, "rb");
				CHECK_STATUS(!file, FLP_CANNOT_LOAD, cleanup);
				free(fileName);
				fileName = NULL;
				
				#ifdef WIN32
					QueryPerformanceCounter(&tvStart);
					status = doWrite(handle, (uint8)chan, file, &length, &checksum, error);
					QueryPerformanceCounter(&tvEnd);
					totalTime = (double)(tvEnd.QuadPart - tvStart.QuadPart);
					totalTime /= freq.QuadPart;
					speed = (double)length / (1024*1024*totalTime);
				#else
					gettimeofday(&tvStart, NULL);
					status = doWrite(handle, (uint8)chan, file, &length, &checksum, error);
					gettimeofday(&tvEnd, NULL);
					startTime = tvStart.tv_sec;
					startTime *= 1000000;
					startTime += tvStart.tv_usec;
					endTime = tvEnd.tv_sec;
					endTime *= 1000000;
					endTime += tvEnd.tv_usec;
					totalTime = (double)(endTime - startTime);
					totalTime /= 1000000;  // convert from uS to S.
					speed = (double)length / (1024*1024*totalTime);
				#endif
				if ( enableBenchmarking ) {
					printf(
						"Wrote "PFSZD" bytes (checksum 0x%04X) to channel %lu at %f MiB/s\n",
						length, checksum, chan, speed);
				}
				CHECK_STATUS(status, status, cleanup);

				// Close the file
				fclose(file);
				file = NULL;
			} else if ( isHexDigit(ch) ) {
				// Read a sequence of hex bytes to write
				uint8 *dataPtr;
				p = ptr + 1;
				while ( isHexDigit(*p) ) {
					p++;
				}
				CHECK_STATUS((p - ptr) & 1, FLP_ODD_DIGITS, cleanup);
				length = (size_t)(p - ptr) / 2;
				data = malloc(length);
				dataPtr = data;
				for ( i = 0; i < length; i++ ) {
					getHexByte(dataPtr++);
					ptr += 2;
				}
				#ifdef WIN32
					QueryPerformanceCounter(&tvStart);
					fStatus = flWriteChannel(handle, (uint8)chan, length, data, error);
					QueryPerformanceCounter(&tvEnd);
					totalTime = (double)(tvEnd.QuadPart - tvStart.QuadPart);
					totalTime /= freq.QuadPart;
					speed = (double)length / (1024*1024*totalTime);
				#else
					gettimeofday(&tvStart, NULL);
					fStatus = flWriteChannel(handle, (uint8)chan, length, data, error);
					gettimeofday(&tvEnd, NULL);
					startTime = tvStart.tv_sec;
					startTime *= 1000000;
					startTime += tvStart.tv_usec;
					endTime = tvEnd.tv_sec;
					endTime *= 1000000;
					endTime += tvEnd.tv_usec;
					totalTime = (double)(endTime - startTime);
					totalTime /= 1000000;  // convert from uS to S.
					speed = (double)length / (1024*1024*totalTime);
				#endif
				if ( enableBenchmarking ) {
					printf(
						"Wrote "PFSZD" bytes (checksum 0x%04X) to channel %lu at %f MiB/s\n",
						length, calcChecksum(data, length), chan, speed);
				}
				CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
				free(data);
				data = NULL;
			} else {
				FAIL(FLP_ILL_CHAR, cleanup);
			}
			break;
		}
		case '+':{
			uint32 conduit;
			char *end;
			ptr++;

			// Get the conduit
			errno = 0;
			conduit = (uint32)strtoul(ptr, &end, 16);
			CHECK_STATUS(errno, FLP_BAD_HEX, cleanup);

			// Ensure that it's 0-127
			CHECK_STATUS(conduit > 255, FLP_CONDUIT_RANGE, cleanup);
			ptr = end;

			// Only two valid chars at this point:
			CHECK_STATUS(*ptr != '\0' && *ptr != ';', FLP_ILL_CHAR, cleanup);

			fStatus = flSelectConduit(handle, (uint8)conduit, error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			break;
		}
		default:
			FAIL(FLP_ILL_CHAR, cleanup);
		}
	} while ( *ptr == ';' );
	CHECK_STATUS(*ptr != '\0', FLP_ILL_CHAR, cleanup);

	dump(0x00000000, dataFromFPGA.data, dataFromFPGA.length);

cleanup:
	bufDestroy(&dataFromFPGA);
	if ( file ) {
		fclose(file);
	}
	free(fileName);
	free(data);
	if ( retVal != FLP_TIMEOUT && retVal > FLP_LIBERR ) {
		const int column = (int)(ptr - line);
		int i;
		fprintf(stderr, "%s at column %d\n  %s\n  ", errMessages[retVal], column, line);
		for ( i = 0; i < column; i++ ) {
			fprintf(stderr, " ");
		}
		fprintf(stderr, "^\n");
	}
	return retVal;
}

static const char *nibbles[] = {
	"0000",  // '0'
	"0001",  // '1'
	"0010",  // '2'
	"0011",  // '3'
	"0100",  // '4'
	"0101",  // '5'
	"0110",  // '6'
	"0111",  // '7'
	"1000",  // '8'
	"1001",  // '9'

	"XXXX",  // ':'
	"XXXX",  // ';'
	"XXXX",  // '<'
	"XXXX",  // '='
	"XXXX",  // '>'
	"XXXX",  // '?'
	"XXXX",  // '@'

	"1010",  // 'A'
	"1011",  // 'B'
	"1100",  // 'C'
	"1101",  // 'D'
	"1110",  // 'E'
	"1111"   // 'F'
};

int main(int argc, char *argv[]) {
	ReturnCode retVal = FLP_SUCCESS, pStatus;
	struct arg_str *ivpOpt = arg_str0("i", "ivp", "<VID:PID>", "            vendor ID and product ID (e.g 04B4:8613)");
	struct arg_str *vpOpt = arg_str1("v", "vp", "<VID:PID[:DID]>", "       VID, PID and opt. dev ID (e.g 1D50:602B:0001)");
	struct arg_str *fwOpt = arg_str0("f", "fw", "<firmware.hex>", "        firmware to RAM-load (or use std fw)");
	struct arg_str *portOpt = arg_str0("d", "ports", "<bitCfg[,bitCfg]*>", " read/write digital ports (e.g B13+,C1-,B2?)");
	struct arg_str *queryOpt = arg_str0("q", "query", "<jtagBits>", "         query the JTAG chain");
	struct arg_str *progOpt = arg_str0("p", "program", "<config>", "         program a device");
	struct arg_uint *conOpt = arg_uint0("c", "conduit", "<conduit>", "        which comm conduit to choose (default 0x01)");
	struct arg_str *actOpt = arg_str0("a", "action", "<actionString>", "    a series of CommFPGA actions");
	struct arg_lit *shellOpt  = arg_lit0("s", "shell", "                    start up an interactive CommFPGA session");
	struct arg_lit *benOpt  = arg_lit0("b", "benchmark", "                enable benchmarking & checksumming");
	struct arg_lit *rstOpt  = arg_lit0("r", "reset", "                    reset the bulk endpoints");
	struct arg_str *dumpOpt = arg_str0("l", "dumploop", "<ch:file.bin>", "   write data from channel ch to file");
	struct arg_lit *helpOpt  = arg_lit0("h", "help", "                     print this help and exit");
	struct arg_str *eepromOpt  = arg_str0(NULL, "eeprom", "<std|fw.hex|fw.iic>", "   write firmware to FX2's EEPROM (!!)");
	struct arg_str *backupOpt  = arg_str0(NULL, "backup", "<kbitSize:fw.iic>", "     backup FX2's EEPROM (e.g 128:fw.iic)\n");

	// Custom input through specified file
	struct arg_str *readOpt = arg_str0(NULL, "custom", "<track_data.csv>", "   read track data from this file");

	struct arg_end *endOpt   = arg_end(20);
	void *argTable[] = {
		ivpOpt, vpOpt, fwOpt, portOpt, queryOpt, progOpt, conOpt, actOpt,
		shellOpt, benOpt, rstOpt, dumpOpt, helpOpt, eepromOpt, backupOpt, readOpt, endOpt
	};
	const char *progName = "flcli";
	int numErrors;
	struct FLContext *handle = NULL;
	FLStatus fStatus;
	const char *error = NULL;
	const char *ivp = NULL;
	const char *vp = NULL;
	bool isNeroCapable, isCommCapable;
	uint32 numDevices, scanChain[16], i;
	const char *line = NULL;
	uint8 conduit = 0x01;


	if ( arg_nullcheck(argTable) != 0 ) {
		fprintf(stderr, "%s: insufficient memory\n", progName);
		FAIL(1, cleanup);
	}

	numErrors = arg_parse(argc, argv, argTable);

	if ( helpOpt->count > 0 ) {
		printf("FPGALink Command-Line Interface Copyright (C) 2012-2014 Chris McClelland\n\nUsage: %s", progName);
		arg_print_syntax(stdout, argTable, "\n");
		printf("\nInteract with an FPGALink device.\n\n");
		arg_print_glossary(stdout, argTable,"  %-10s %s\n");
		FAIL(FLP_SUCCESS, cleanup);
	}

	if ( numErrors > 0 ) {
		arg_print_errors(stdout, endOpt, progName);
		fprintf(stderr, "Try '%s --help' for more information.\n", progName);
		FAIL(FLP_ARGS, cleanup);
	}

	fStatus = flInitialise(0, &error);
	CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);

	vp = vpOpt->sval[0];

	printf("Attempting to open connection to FPGALink device %s...\n", vp);
	fStatus = flOpen(vp, &handle, NULL);
	if ( fStatus ) {
		if ( ivpOpt->count ) {
			int count = 60;
			uint8 flag;
			ivp = ivpOpt->sval[0];
			printf("Loading firmware into %s...\n", ivp);
			if ( fwOpt->count ) {
				fStatus = flLoadCustomFirmware(ivp, fwOpt->sval[0], &error);
			} else { 
				fStatus = flLoadStandardFirmware(ivp, vp, &error);
			}
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			
			printf("Awaiting renumeration");
			flSleep(1000);
			do {
				printf(".");
				fflush(stdout);
				fStatus = flIsDeviceAvailable(vp, &flag, &error);
				CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
				flSleep(250);
				count--;
			} while ( !flag && count );
			printf("\n");
			if ( !flag ) {
				fprintf(stderr, "FPGALink device did not renumerate properly as %s\n", vp);
				FAIL(FLP_LIBERR, cleanup);
			}

			printf("Attempting to open connection to FPGLink device %s again...\n", vp);
			fStatus = flOpen(vp, &handle, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
		} else {
			fprintf(stderr, "Could not open FPGALink device at %s and no initial VID:PID was supplied\n", vp);
			FAIL(FLP_ARGS, cleanup);
		}
	}

	printf(
		"Connected to FPGALink device %s (firmwareID: 0x%04X, firmwareVersion: 0x%08X)\n",
		vp, flGetFirmwareID(handle), flGetFirmwareVersion(handle)
	);

	if ( eepromOpt->count ) {
		if ( !strcmp("std", eepromOpt->sval[0]) ) {
			printf("Writing the standard FPGALink firmware to the FX2's EEPROM...\n");
			fStatus = flFlashStandardFirmware(handle, vp, &error);
		} else {
			printf("Writing custom FPGALink firmware from %s to the FX2's EEPROM...\n", eepromOpt->sval[0]);
			fStatus = flFlashCustomFirmware(handle, eepromOpt->sval[0], &error);
		}
		CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
	}

	if ( backupOpt->count ) {
		const char *fileName;
		const uint32 kbitSize = strtoul(backupOpt->sval[0], (char**)&fileName, 0);
		if ( *fileName != ':' ) {
			fprintf(stderr, "%s: invalid argument to option --backup=<kbitSize:fw.iic>\n", progName);
			FAIL(FLP_ARGS, cleanup);
		}
		fileName++;
		printf("Saving a backup of %d kbit from the FX2's EEPROM to %s...\n", kbitSize, fileName);
		fStatus = flSaveFirmware(handle, kbitSize, fileName, &error);
		CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
	}

	if ( rstOpt->count ) {
		// Reset the bulk endpoints (only needed in some virtualised environments)
		fStatus = flResetToggle(handle, &error);
		CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
	}

	if ( conOpt->count ) {
		conduit = (uint8)conOpt->ival[0];
	}

	isNeroCapable = flIsNeroCapable(handle);
	isCommCapable = flIsCommCapable(handle, conduit);

	if ( portOpt->count ) {
		uint32 readState;
		char hex[9];
		const uint8 *p = (const uint8 *)hex;
		printf("Configuring ports...\n");
		fStatus = flMultiBitPortAccess(handle, portOpt->sval[0], &readState, &error);
		CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
		sprintf(hex, "%08X", readState);
		printf("Readback:   28   24   20   16    12    8    4    0\n          %s", nibbles[*p++ - '0']);
		printf(" %s", nibbles[*p++ - '0']);
		printf(" %s", nibbles[*p++ - '0']);
		printf(" %s", nibbles[*p++ - '0']);
		printf("  %s", nibbles[*p++ - '0']);
		printf(" %s", nibbles[*p++ - '0']);
		printf(" %s", nibbles[*p++ - '0']);
		printf(" %s\n", nibbles[*p++ - '0']);
		flSleep(100);
	}

	if ( queryOpt->count ) {
		if ( isNeroCapable ) {
			fStatus = flSelectConduit(handle, 0x00, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			fStatus = jtagScanChain(handle, queryOpt->sval[0], &numDevices, scanChain, 16, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			if ( numDevices ) {
				printf("The FPGALink device at %s scanned its JTAG chain, yielding:\n", vp);
				for ( i = 0; i < numDevices; i++ ) {
					printf("  0x%08X\n", scanChain[i]);
				}
			} else {
				printf("The FPGALink device at %s scanned its JTAG chain but did not find any attached devices\n", vp);
			}
		} else {
			fprintf(stderr, "JTAG chain scan requested but FPGALink device at %s does not support NeroProg\n", vp);
			FAIL(FLP_ARGS, cleanup);
		}
	}

	if ( progOpt->count ) {
		printf("Programming device...\n");
		if ( isNeroCapable ) {
			fStatus = flSelectConduit(handle, 0x00, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			fStatus = flProgram(handle, progOpt->sval[0], NULL, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
		} else {
			fprintf(stderr, "Program operation requested but device at %s does not support NeroProg\n", vp);
			FAIL(FLP_ARGS, cleanup);
		}
	}

	if ( benOpt->count ) {
		enableBenchmarking = true;
	}
	
	if ( actOpt->count ) {
		printf("Executing CommFPGA actions on FPGALink device %s...\n", vp);
		if ( isCommCapable ) {
			uint8 isRunning;
			fStatus = flSelectConduit(handle, conduit, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			fStatus = flIsFPGARunning(handle, &isRunning, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			if ( isRunning ) {
				pStatus = parseLine(handle, actOpt->sval[0], &error, U32MAX);
				CHECK_STATUS(pStatus, pStatus, cleanup);
			} else {
				fprintf(stderr, "The FPGALink device at %s is not ready to talk - did you forget --program?\n", vp);
				FAIL(FLP_ARGS, cleanup);
			}
		} else {
			fprintf(stderr, "Action requested but device at %s does not support CommFPGA\n", vp);
			FAIL(FLP_ARGS, cleanup);
		}
	}

	if ( dumpOpt->count ) {
		const char *fileName;
		unsigned long chan = strtoul(dumpOpt->sval[0], (char**)&fileName, 10);
		FILE *file = NULL;
		const uint8 *recvData;
		uint32 actualLength;
		if ( *fileName != ':' ) {
			fprintf(stderr, "%s: invalid argument to option -l|--dumploop=<ch:file.bin>\n", progName);
			FAIL(FLP_ARGS, cleanup);
		}
		fileName++;
		printf("Copying from channel %lu to %s", chan, fileName);
		file = fopen(fileName, "wb");
		CHECK_STATUS(!file, FLP_CANNOT_SAVE, cleanup);
		sigRegisterHandler();
		fStatus = flSelectConduit(handle, conduit, &error);
		CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
		fStatus = flReadChannelAsyncSubmit(handle, (uint8)chan, 22528, NULL, &error);
		CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
		do {
			fStatus = flReadChannelAsyncSubmit(handle, (uint8)chan, 22528, NULL, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			fStatus = flReadChannelAsyncAwait(handle, &recvData, &actualLength, &actualLength, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			fwrite(recvData, 1, actualLength, file);
			printf(".");
		} while ( !sigIsRaised() );
		printf("\nCaught SIGINT, quitting...\n");
		fStatus = flReadChannelAsyncAwait(handle, &recvData, &actualLength, &actualLength, &error);
		CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
		fwrite(recvData, 1, actualLength, file);
		fclose(file);
	}

	/**********************************/
	/* Wrapper for Railway Scheduling */
	/**********************************/

	if ( readOpt->count ) {
		if ( isCommCapable ) {
			printf("Establishing connection ...\n");
			fflush(stdout);

			uint8 isRunning;
			fStatus = flSelectConduit(handle, conduit, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			fStatus = flIsFPGARunning(handle, &isRunning, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);

			// constant strings
			const char* filename = readOpt->sval[0];

			char* dataFile = "/home/rupesh/20140524/makestuff/apps/flcli/track_data.csv";
			char* tempFile = "temp";


			const char* KEY = "10100000110100111111000101011011";
			const char* ACK1 = "00101010001010100010101000101011";
			const char* ACK2 = "10101010101010101010101010101011";
			char* wannaSend = "11001110110011101100111011001111";
			char* NotWannaSent = "00110001001100010011000100110011";

			// variable declarations
			char command[80];
			char data32[33]; data32[0] = '\0';
			char data64[65]; data64[0] = '\0';
			char temp[9]; temp[0] = '\0';
			uint8 X, Y;

			uint8 currentI = 0; 
			uint8 stage = 0;
			uint8 xcoors[64];
			uint8 ycoors[64];
			
			uint8 totalChannel = 64;

			bool readOnce = 0;
			
			printf("Using %s as database ...\n", filename);
			fflush(stdout);
			
			do {
				// Wait for 3 seconds for LEDs to play around
				if (stage == 0) {
					sleep(3);
					stage = 1;
				}

				else if (stage == 1){
					// Read encrypted coodinates on channel iteratively on data32
					// Decrypt the read data and get coordnates
					// Encrypting and sendind read coordinates and send to channel 2*i+1
					// Read ACK and compare, if correct save local coordinates
					sleep(2);
					printf("\n\nReading encrypted coordinates on channel %d ...\n",2*currentI);
					fflush(stdout);
					sprintf(command, "r%x 4 \"%s\"", 2*currentI, tempFile);
					add_history(command);
					pStatus = parseLine(handle, command, &error, 3000);
					fflush(stdout);
					if (pStatus == FLP_TIMEOUT) {
						printf("Timeout occurred. Skipping channel %d.\n", 2*currentI);
						fflush(stdout);
						currentI = (currentI+1)%totalChannel;
						stage = 1;
						continue;
					}
					printf("Reading read data from temporary file ...\n");
					fflush(stdout);
					readFromTempfile(data32, tempFile);

					// Decrypt data
					printf("Decrypting data and obtaining coordinates ...\n");
					fflush(stdout);
					decrypt(data32, KEY);

					// Get coordinates
					X = toInt(data32);
					Y = toInt(data32 + 4);

					// Encrypting and sendind read coordinates and send to channel 2*currentI + 1
					printf("Encrypting coordinates and sending back to FPGA board ...\n");
					fflush(stdout);
					
					myencrypt(data32, KEY);
					toHex(data32,temp);
					sprintf(command, "w%x %s", 2*currentI+1, temp);
					add_history(command);
					pStatus = parseLine(handle, command, &error, U32MAX);

					printf("Reading ACK1 ...\n");
					fflush(stdout);

					sprintf(command, "r%x 4 \"%s\"", 2*currentI, tempFile);
					add_history(command);
					pStatus = parseLine(handle, command, &error, U32MAX);
					if (pStatus == FLP_TIMEOUT) {
						printf("Timeout occurred. Skipping channel %d.\n", 2*currentI);
						currentI = (currentI+1)%totalChannel;
						stage = 1;
						continue;
					}
					else if(pStatus == FLP_SUCCESS){
						printf("Reading read data from temporary file ...\n");
						fflush(stdout);
						readFromTempfile(data32, tempFile);

						decrypt(data32, KEY);
						fflush(stdout);
						if (strcmp(data32, ACK1) == 0){
							printf("ACK1 received.\n");
							fflush(stdout);
							stage = 2;
							// Save to local memory here
							xcoors[currentI] = X;
							ycoors[currentI] = Y;
						}
						else{
							printf("Invalid ACK1. Reading again on channel %d.", 2*currentI);
							fflush(stdout);
							sleep(5);

							printf("Reading ACK1 again ...\n");
							fflush(stdout);

							sprintf(command, "r%x 4 \"%s\"", 2*currentI, tempFile);
							add_history(command);
							pStatus = parseLine(handle, command, &error, U32MAX);
							if (pStatus == FLP_TIMEOUT) {
								printf("Timeout occurred. Skipping channel %d.\n", 2*currentI);
								currentI = (currentI+1)%totalChannel;
								stage = 1;
								continue;
							}
							else if(pStatus == FLP_SUCCESS){
								printf("Reading read data from temporary file ...\n");
								fflush(stdout);
								readFromTempfile(data32, tempFile);

								decrypt(data32, KEY);
								fflush(stdout);
								if (strcmp(data32, ACK1) == 0){
									printf("ACK1 received.\n");
									fflush(stdout);
									stage = 2;
									// Save to local memory here
									xcoors[currentI] = X;
									ycoors[currentI] = Y;
								}
								else{

									printf("Invalid ACK1. Skipping channel %d.", 2*currentI);
									fflush(stdout);
									currentI = (currentI+1)%totalChannel;
									stage = 1;
									continue;
								}
							}		
						}
					}
				}
				else if (stage == 2) {
					// send ACK2 on channel (2i+1)
					// read data track_data.csv corresponding to current-coordinates
					// send first four bytes on 2i+1
					// Read from channel 2i, trying to listen ACK1 with timeout 256 seconds
						// if ACK1 found stage = 2
						// else stage = 1  currentI++

					printf("Sending encrypted ACK2 to FPGA board ...\n");
					fflush(stdout);	

					strcpy(data32,ACK2);
					myencrypt(data32, KEY);

					toHex(data32,temp);
					sprintf(command, "w%x %s", 2*currentI+1, temp);
					add_history(command);
					pStatus = parseLine(handle, command, &error, U32MAX);
					sleep(1);

					if (! readOnce) {
						printf("Reading track data from %s...\n", dataFile);
						fflush(stdout);
						readFile(dataFile);
						readOnce = 1;
					}

					getData(X,Y,data64);

					printf("Sending first 32 bits of encrypted data...\n");
					fflush(stdout);

					// then send 32 bit encrypted data on channel 2*currentI+1
					strncpy(data32, data64, 32);
					myencrypt(data32, KEY);

					toHex(data32,temp);
					sprintf(command, "w%x %s", 2*currentI+1, temp);
					add_history(command);
					pStatus = parseLine(handle, command, &error, U32MAX);
					
					sleep(1);

					sprintf(command, "r%x 4 \"%s\"", 2*currentI, tempFile);
					add_history(command);
					pStatus = parseLine(handle, command, &error, 256000);
					if (pStatus == FLP_TIMEOUT) {
						currentI = (currentI+1)%totalChannel;
						stage = 1;
						continue;
					}
					printf("Reading read data from temporary file ...\n");
					fflush(stdout);
					readFromTempfile(data32, tempFile);
					decrypt(data32, KEY);		
					if(strcmp(data32, ACK1)==0){
							printf("ACK1 received.\n");
							fflush(stdout);
							stage = 3;
					}
					else {
						printf("Invalid ACK1. Skipping channel %d.\n", 2*currentI);
						fflush(stdout);
						currentI = (currentI+1)%totalChannel;
						stage = 1;
					}					
					
				}
				else if (stage == 3){
					// send next 4 bytes of data
					// Read from channel 2i, trying to listen for ACK1 with timeout 256 seconds if ACK1 found, stage = 3 else stage = 1 currentI++
					// Now send next 32 bit encrypted data on channel 1
					printf("Sending next 32 bits of encrypted data...\n");
					fflush(stdout);

					strncpy(data32, data64 + 32, 32);
					myencrypt(data32, KEY);
					
					toHex(data32,temp);
					sprintf(command, "w%x %s", 2*currentI+1, temp);
					add_history(command);
					pStatus = parseLine(handle, command, &error, U32MAX);

					sprintf(command, "r%x 4 \"%s\"", 2*currentI, tempFile);
					add_history(command);
					sleep(1);	
					pStatus = parseLine(handle, command, &error, 256000);
					if (pStatus == FLP_TIMEOUT) {
						printf("Timeout occurred. Skipping channel %d.\n", 2*currentI);
						fflush(stdout);
						currentI = (currentI+1)%totalChannel;
						stage = 1;
						continue;
					}
					printf("Reading read data from temporary file ...\n");
					fflush(stdout);
					readFromTempfile(data32, tempFile);
					decrypt(data32, KEY);
					if(strcmp(data32, ACK1)==0){
							printf("ACK1 received.\n");
							fflush(stdout);
							stage = 4;
					}
					else {
						printf("Invalid ACK1. Skipping channel %d.\n", 2*currentI);
						fflush(stdout);
						currentI = (currentI+1)%totalChannel;
						stage = 1;
						continue;
					}
				}
				
				else if (stage == 4){
					// send ACK2 on channel (2i+1)	
					printf("Sending encrypted ACK2 to FPGA board ...\n");
					fflush(stdout);	

					strcpy(data32,ACK2);
					myencrypt(data32, KEY);

					toHex(data32,temp);
					sprintf(command, "w%x %s", 2*currentI+1, temp);
					add_history(command);
					pStatus = parseLine(handle, command, &error, U32MAX);
					sleep(25);
					stage = 5;
				}
				
				else if (stage == 5){
					// Read from FPGA board with timeout 5 seconds
					// if wannaSend
							// read from FPGA with timeout 60 seconds
							// if correct message
							// 		update database and move to next stage
					
					printf("Waiting for write command from FPGA board...\n");
					fflush(stdout);

					sprintf(command, "r%x 4 \"%s\"", 2*currentI, tempFile);
					add_history(command);
					pStatus = parseLine(handle, command, &error, 5000);
					if (pStatus == FLP_TIMEOUT) {
						printf("Timeout occurred. Skipping channel %d.\n", 2*currentI);
						fflush(stdout);
						currentI = (currentI+1)%totalChannel;
						stage = 1;
						continue;
					}
					printf("Identifying command...\n");
					fflush(stdout);
					readFromTempfile(data32, tempFile);	
					decrypt(data32, KEY);

					if(strcmp(data32, wannaSend)==0){
						printf("Up button pressed.\nWaiting for data...\n");
						fflush(stdout);
						sprintf(command, "r%x 4 \"%s\"", 2*currentI, tempFile);
						add_history(command);
						
						pStatus = parseLine(handle, command, &error, 80000);
						if (pStatus == FLP_TIMEOUT) {
							printf("Timeout occurred. Skipping channel %d.\n", 2*currentI);
							fflush(stdout);
							currentI = (currentI+1)%totalChannel;
							stage = 1;
							continue;
						}
						
						readFromTempfile(data32, tempFile);
						decrypt(data32,KEY);
						char timedOut[33] = "00000001001000110000000100100011\0";
						if(strcmp(data32,timedOut)==0){
							printf("Timeout occurred. Skipping channel %d.\n", 2*currentI);
							fflush(stdout);	
							currentI = (currentI+1)%totalChannel;
							stage = 1;						
							continue;
						}
						printf("Down button pressed.\nReading read data from temporary file...\n");
						fflush(stdout);

						printf("Received data to update database.\n");
						updateData(X,Y,data32);	
						
					}
					else if(strcmp(data32,NotWannaSent)==0){
						printf("Board Not sending any data.\n");
						fflush(stdout);
						currentI = (currentI+1)%totalChannel;
						stage = 1;
						continue;						
					}
					else{
						printf("Invalid command. Skipping channel %d.\n", 2*currentI);
						fflush(stdout);
						currentI = (currentI+1)%totalChannel;
						stage = 1;
						continue;
					}

					sleep(5);
					stage = 1;
					currentI = (currentI+1) % totalChannel;
										
				}				
			} while(true);
		}
	}

	if ( shellOpt->count ) {
		printf("\nEntering CommFPGA command-line mode:\n");
		if ( isCommCapable ) {
			uint8 isRunning;
			fStatus = flSelectConduit(handle, conduit, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			fStatus = flIsFPGARunning(handle, &isRunning, &error);
			CHECK_STATUS(fStatus, FLP_LIBERR, cleanup);
			if ( isRunning ) {
					do {
						do {
							line = readline("> ");
						} while ( line && !line[0] );
						if ( line && line[0] && line[0] != 'q' ) {
							add_history(line);
							pStatus = parseLine(handle, line, &error, 5000);
							if(pStatus != FLP_TIMEOUT){
								CHECK_STATUS(pStatus, pStatus, cleanup);
							}
							free((void*)line);
						}
					} while ( line && line[0] != 'q' );
				} else {
					fprintf(stderr, "The FPGALink device at %s is not ready to talk - did you forget --xsvf?\n", vp);
					FAIL(FLP_ARGS, cleanup);
				}
			} else {
				fprintf(stderr, "Shell requested but device at %s does not support CommFPGA\n", vp);
				FAIL(FLP_ARGS, cleanup);
			}
		}

cleanup:
	free((void*)line);
	flClose(handle);
	if ( error ) {
		fprintf(stderr, "%s\n", error);
		flFreeError(error);
	}
	return retVal;
}
