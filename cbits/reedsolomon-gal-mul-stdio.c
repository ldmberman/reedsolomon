#if HAVE_CONFIG_H
# include "config.h"
#endif

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "reedsolomon.h"

int read_all(const int fd, uint8_t *vec, size_t count) {
        ssize_t rc = 0;

        while(count > 0) {
                rc = read(fd, vec, count);

                if(rc < 0) {
                        perror("read");
                        return -1;
                }

                count -= rc;
                vec += rc;
        }

        return 0;
}

int write_all(const int fd, const uint8_t *vec, size_t count) {
        ssize_t rc = 0;

        while(count > 0) {
                rc = write(fd, vec, count);

                if(rc < 0) {
                        perror("write");
                        return -1;
                }

                count -= rc;
                vec += rc;
        }

        return 0;
}


int main(int argc, char **argv) {
        int rc = 1;
        size_t size = 0,
               cnt = 0;
        uint8_t *data = NULL,
                *out = NULL,
                low_vector[16] = { 0 },
                high_vector[16] = { 0 };

        if(argc != 2) {
                fprintf(stderr, "Usage: %s SIZE\n", argv[0]);
                rc = 1;
                goto out;
        }

        rc = sscanf(argv[1], "%zu", &size);
        if(rc == EOF) {
                perror("sscanf");
                rc = 1;
                goto out;
        }

        rc = read_all(STDIN_FILENO, low_vector, sizeof(low_vector));
        if(rc != 0) {
                rc = 1;
                goto out;
        }

        rc = read_all(STDIN_FILENO, high_vector, sizeof(high_vector));
        if(rc != 0) {
                rc = 1;
                goto out;
        }

        data = malloc(size);
        if(data == NULL) {
                perror("malloc");
                rc = 1;
                goto out;
        }

        rc = read_all(STDIN_FILENO, data, size);
        if(rc != 0) {
                rc = 1;
                goto out;
        }

        out = malloc(size);
        if(out == NULL) {
                perror("malloc");
                rc = 1;
                goto out;
        }

        cnt = reedsolomon_gal_mul(low_vector, high_vector, data, out, size);
        if(cnt != size) {
                fprintf(stderr, "Count mismatch: size=%zu, cnt=%zu\n", size, cnt);
                rc = 1;
                goto out;
        }

        rc = write_all(STDOUT_FILENO, out, size);
        if(rc != 0) {
                rc = 1;
                goto out;
        }

        rc = 0;

out:
        free(data);
        free(out);

        return rc;
}