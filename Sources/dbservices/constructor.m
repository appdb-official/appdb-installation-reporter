#import <Foundation/Foundation.h>
#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

// Declare the function
extern void auto_report_install(void);

// Constructor function that runs when dylib is loaded
__attribute__((constructor)) static void init_reporter() {
  NSLog(@"appdb: dylib constructor called in process %d, thread %p", getpid(),
        (void *)pthread_self());
  auto_report_install();
}