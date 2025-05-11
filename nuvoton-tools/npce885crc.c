/*
 * Generator for Insyde KBC EC code CRC (IN... header)
 *
 * (c) leecher@dose.0wnz.at 02/2022
 *
 * https://github.com/leecher1337/thinkpad-Lx30-ec
 *
 * Compile with:    gcc -o npce885crc npce885crc.c
 *
 */
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stddef.h>
#include <errno.h>

#pragma pack(1)
typedef struct
{
	uint32_t sig;
	uint32_t start_addr;
	uint16_t pad;
	uint32_t size;
	uint32_t eip;
	uint16_t crc;
} IN_HDR;
#pragma pack()

int patch_file(char *file, unsigned int offset, int fUpdate)
{
	FILE* fp;
	unsigned int crc_offset;
	IN_HDR hdr;
	int i, ret = 0;
	short c;
	unsigned char crc;

	if (!(fp = fopen(file, fUpdate ? "r+b" : "rb")))
	{
		perror("Cannot open file");
		return -1;
	}
	if (fseek(fp, offset, SEEK_SET))
	{
		perror("Cannot seek to offset");
		fclose(fp);
		return -1;
	}
	if (fread(&hdr, sizeof(hdr), 1, fp))
	{
		if (hdr.sig == 0x4e49)
		{
			printf("CRC Start address=%08X\nAssumed load address: %08X\n", (hdr.start_addr << 1), (hdr.start_addr << 1) & 0xFFFFFF00);
			crc_offset = (hdr.start_addr << 1) & 0xFF;
			printf("CRC indexing offset = %X\n", crc_offset);
			if (fseek(fp, offset + crc_offset, SEEK_SET) == 0)
			{
				crc_offset = offsetof(IN_HDR, crc) - crc_offset;

				for (i = 0, c = 0, crc = 0; i < hdr.size && c != EOF; i++)
				{
					c = fgetc(fp);
					if (i == crc_offset) continue;
					crc -= c;
				}

				if (c != EOF)
				{
					printf("Calculated CRC = %02X, file CRC = %02X --> ", crc, hdr.crc);
					if (crc != hdr.crc)
					{
						printf("CRC differs!\n");
						if (fUpdate && fseek(fp, offset, SEEK_SET) == 0)
						{
							hdr.crc = crc;
							printf("Updating CRC...");
							fflush(stdout);
							if (fwrite(&hdr, sizeof(hdr), 1, fp) != 1)
							{
								perror("FAILED");
								ret = -1;
							}
							else printf("OK!\n");
						}
					}
					else printf("OK!\n");
				}
				else
				{
					perror("Cannot read full image, too small?");
					ret = -1;
				}
			}
			else
			{
				perror("Cannot seek to CRC offset");
				ret = -1;
			}
		}
		else
		{
			fprintf(stderr, "Invalid header %X, not an IN file. Did you specify the correct offset of IN piggyback code?\n", hdr.sig);
			ret = -1;
		}
	}
	else
	{
		perror("Error reading header");
		ret = -1;
	}
	fclose(fp);
	return ret;
}

int usage(char *a0)
{
	fprintf (stderr, "Usage: %s [-o <0xoffset>] [-u] <file>\n\n" \
	"\t-o\tFile starts at <offset> in <file>, default is 0\n" \
	"\t-u\tUpdate CRC, if it differs\n" \
	"\t<file> = File to patch\n\n"\
	"Example: %s -o 0x808000 -u $01H3000.FL1\n\n", a0, a0);
	return -1;
}

int main(int argc, char **argv)
{
	int fUpdate = 0, i;
	unsigned int offset = 0;
	char *file = NULL;

	printf ("NUVOTON Insyde firmware CRC calculator v1.00\n(c) leecher@dose.0wnz.at 02/2022\n\n");
	if (argc<2) return usage(argv[0]);
	for (i=1; i<argc; i++)
	{
		if (argv[i][0] == '-')
		{
			switch (argv[i][1])
			{
			case 'o':
				if (argc<i+2)
				{
					fprintf(stderr, "Please specify valid offset\n");
					return -1;
				}
				offset = strtoul(argv[++i], NULL, 16);
				printf ("Searching at offset %X\n", offset);
				continue;
			case 'u':
				fUpdate = 1;
				continue;
			}
		}
		file = argv[i];
	}
	if (!file) return usage(argv[0]);

	return patch_file(file, offset, fUpdate);
}

