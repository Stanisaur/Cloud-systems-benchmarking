#include <stdio.h>
#include <sys/timex.h>
#include <unistd.h>
#include <time.h>

int main() {
    struct timex t = {0};
    while(1) {
        if (adjtimex(&t) != -1) {
            FILE *f = fopen("/dev/shm/global_clock.tmp", "w");
            if (f) {
                fprintf(f, "%ld.%09ld\n", t.time.tv_sec, t.time.tv_usec);
                fclose(f);
                rename("/dev/shm/global_clock.tmp", "/dev/shm/global_clock");
            }
        }
        nanosleep(&delay, NULL);; 
    }
}