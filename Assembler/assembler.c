#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>
#include <windows.h>

char bytes[32768];
int bytesPos = 0; 

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

int assemble(char *content) {
    

    return 0;
}

int main() {
    printf("TC8 Assembler V0.1 2026\n");
    printf("TC8>");
    while (true) {
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