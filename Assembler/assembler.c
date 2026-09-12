#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>
#include <windows.h>

char bytes[32768];
int bytesPos = 0; 

int state = 0;
char opcodeBuffer;
bool addressIncoming = false;

void addBytes(const char *hexBytes) {
    while (*hexBytes != '\0') {
        while (isspace((unsigned char)*hexBytes)) {
            hexBytes++;
        }

        if (*hexBytes == '\0') {
            break;
        }

        if (!isxdigit((unsigned char)hexBytes[0]) ||
            !isxdigit((unsigned char)hexBytes[1]) ||
            bytesPos >= (int)sizeof(bytes)) {
            return;
        }

        char byteString[3] = { hexBytes[0], hexBytes[1], '\0' };
        bytes[bytesPos++] = (char)strtoul(byteString, NULL, 16);
        hexBytes += 2;
    }
}

void throw(char *token, int code) {
    printf("Fatal error: ");
    switch (code) {
        case 1: 
            printf("'%s' is not a valid operation. (1)\n", token);
            break;
        case 2:
            printf("'%s' is not a valid address target. (2)\n", token);
            break;
        case 3:
            printf("Bad value '%s' (3)\n", token);
            break;
        case 99:
            printf("something bad happened (99)\n");
        default:
            printf("An error occured. (%d)\n", code);
            break;
    }
}

int parseToken(char *token) {
    if (state == 0) {
        if (strcmp(token, "LDA") == 0) {
            opcodeBuffer = 0b01000010;
            state = 1;
        } else if (strcmp(token, "LDB") == 0) {
            opcodeBuffer = 0b01000100;
            state = 1;
        } else if (strcmp(token, "STA") == 0) {
            opcodeBuffer = 0b01000001;
            state = 1;
        } else if (strcmp(token, "STB") == 0) {
            opcodeBuffer = 0b01000011;
            state = 1;
        } else if (strcmp(token, "ADD") == 0) {
            opcodeBuffer = 0b00000001;
            state = 1;
        } else if (strcmp(token, "SUB") == 0) {
            opcodeBuffer = 0b00000010;
            state = 1;
        } else if (strcmp(token, "AND") == 0) {
            opcodeBuffer = 0b00000011;
            state = 1;
        } else if (strcmp(token, "ORR") == 0) {
            opcodeBuffer = 0b00000100;
            state = 1;
        } else if (strcmp(token, "XOR") == 0) {
            opcodeBuffer = 0b00000101;
            state = 1;
        } else if (strcmp(token, "SHL") == 0) {
            opcodeBuffer = 0b00000110;
            state = 1;
        } else if (strcmp(token, "SHR") == 0) {
            opcodeBuffer = 0b00000111;
            state = 1;
        } else if (strcmp(token, "CEQ") == 0) {
            opcodeBuffer = 0b00001000;
            state = 1;
        } else if (strcmp(token, "CNE") == 0) {
            opcodeBuffer = 0b00001001;
            state = 1;
        } else if (strcmp(token, "CGT") == 0) {
            opcodeBuffer = 0b00001010;
            state = 1;
        } else if (strcmp(token, "CLT") == 0) {
            opcodeBuffer = 0b00001011;
            state = 1;
        } else if (strcmp(token, "CGE") == 0) {
            opcodeBuffer = 0b00001100;
            state = 1;
        } else if (strcmp(token, "CLE") == 0) {
            opcodeBuffer = 0b00001101;
            state = 1;
        } else {
            throw(token, 1);
            return -1;
        }
    } else if (state == 1) {
        if (strcmp(token, "B") == 0) {
            opcodeBuffer = (opcodeBuffer & ~0x00) | 0x00;
            bytes[bytesPos++] = opcodeBuffer;
            state = 0;
        } else if (strcmp(token, "S") == 0) {
            opcodeBuffer = (opcodeBuffer & ~0x10) | 0x10;
            state = 0;
        } else if (strcmp(token, "M") == 0) {
            opcodeBuffer = (opcodeBuffer & ~0x20) | 0x20;
            addressIncoming = true;
            state = 2;
        } else if (strcmp(token, "I") == 0) {
            opcodeBuffer = (opcodeBuffer & ~0x30) | 0x30;
            state = 2;
        } else {
            throw(token, 2);
        }
    } else if (state == 2) {
        if (addressIncoming) {
            if (strlen(token) == 5) {
                bytes[bytesPos++] = opcodeBuffer;
                if (token[0] == '$') {
                    char byteString[3] = { token[3], token[4], '\0' };
                    bytes[bytesPos++] = (char)strtoul(byteString, NULL, 16);
                    char byte2String[3] = { token[1], token[2], '\0' };
                    bytes[bytesPos++] = (char)strtoul(byte2String, NULL, 16);
                } else {
                    throw(token, 3);
                }
            } else {
                throw(token, 3);
            }
        } else {
            bytes[bytesPos++] = opcodeBuffer;
                if (token[0] == '$') {
                    char byteString[3] = { token[1], token[2], '\0' };
                    bytes[bytesPos++] = (char)strtoul(byteString, NULL, 16);
                } else if (token[0] == '#') {
                    char decimalString[3] = { token[1], token[2], '\0' };
                    if (!isdigit((unsigned char)token[1]) ||
                        !isdigit((unsigned char)token[2])) {
                        throw(token, 3);
                    } else {
                        bytes[bytesPos++] = (char)strtoul(decimalString, NULL, 10);
                    }
                } else if (token[0] == '%' && strlen(token) == 9) {
                    unsigned char value = 0;
                    bool valid = true;
                    for (int i = 1; i < 9; i++) {
                        if (token[i] != '0' && token[i] != '1') {
                            valid = false;
                            break;
                        }
                        value = (unsigned char)((value << 1) | (token[i] - '0'));
                    }
                    if (!valid) {
                        throw(token, 3);
                    } else {
                        bytes[bytesPos++] = (char)value;
                    }
                } else {
                    throw(token, 3);
                }
        }
        addressIncoming = false;
    } else {
        throw(token, 99);        
    }
    
    return 0;
}

int assemble(char *content) {
    char token[128];
    int tokenIdx = 0;

    for (int c = 0; c < strlen(content); c++) {
        if (!isspace(content[c])) {
            token[tokenIdx++] = content[c];
        } else {
            token[tokenIdx++] = '\0';
            parseToken(token);
            tokenIdx = 0;
            token[0] = '\0';
        }
    }

    return 0;
}

int main() {
    printf("TCX 8 bit Assembler V0.1 2026\n");
    while (true) {
        printf("\nTC1>");
        char filename[500];
        fgets(filename, sizeof(filename), stdin);

        size_t len = strlen(filename);
        if (len > 0 && filename[len - 1] == '\n') {
            filename[len - 1] = '\0';
        }
        if (strcmp(&filename[len - 4], "asm") != 0) {
            printf("\n\033[31mFile open failure: '%s' is not a valid .asm file\033[0m\n", filename);
            continue;
        }

        FILE *file = fopen(filename, "r");
        if (file) {
            fseek(file, 0, SEEK_END);
            long file_size = ftell(file);
            rewind(file);

            char *content = malloc(file_size + 1);
            if (content) {
                size_t bytesRead = fread(content, 1, file_size, file);
                content[bytesRead] = '\0';
                fclose(file);
                printf("\nStarting build of file '%s'...\n", filename);

                int sucess = assemble(content);
                
                if (sucess == 0) {    
                    char compFileName[32];
                    for (int i = 0; i < strlen(filename); i++) {
                        if (filename[i] == '.') {
                            compFileName[i] = '\0';
                            break;
                        }
                        compFileName[i] = filename[i];
                    }
                    strcat(compFileName, ".bin");

                    int outputSize = 0x4000;
                    FILE *binary = fopen(compFileName, "wb");

                    fwrite(bytes, 1, 32768, binary);
                    fclose(binary);
                }
                free(content);
            } else {
                printf("\n\033[31mFile open failure: memory allocation failure. Please try again\033[0m\n");
                fclose(file);
            }
        } else {
            printf("\n\033[31mFile open failure: file '%s' was not found\033[0m\n", filename);
        }
        printf("Compilation finished.\n", filename); 
    }
}