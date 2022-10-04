#include <atomic>
#include <fcntl.h>
#include <new>
#include <stdio.h>
#include <string.h>
#include <sys/file.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

struct A {
  A(int initial_value) { internal_value = initial_value; }
  void write(int value) { internal_value = value; }
  int read() const { return internal_value; }
  void watch(int value) {
    while (internal_value == value)
      usleep(1000);
  }
  std::atomic<int> internal_value;
};

size_t getfilesize(int fd) {
  struct stat st;
  fstat(fd, &st);
  return st.st_size;
}

void waitabit() { usleep(10000); }

int main() {
  int mapsize = getpagesize();
  const char *filename = "/tmp/shared.dat";
  int fid = ::open(filename, O_CREAT | O_RDWR, S_IRWXU | S_IRWXG);
  void *ptr =
      ::mmap(nullptr, mapsize, PROT_READ | PROT_WRITE, MAP_SHARED, fid, 0);

  // Start synchronized section
  while (flock(fid, LOCK_EX) != 0) {
    waitabit();
  }

  A *a;
  if (getfilesize(fid) == 0) {
    int res = ftruncate(fid, mapsize);
    a = new (ptr) A(0);
  } else {
    a = reinterpret_cast<A *>(ptr);
  }

  int value = a->read();
  value += 1;
  a->write(value);

  // Finish synchronized section
  flock(fid, LOCK_UN); // unlock

  // Change 5 times
  for (int j = 0; j < 5; ++j) {
    printf("-->proc %d %d\n", getpid(), value);
    a->watch(value);
    value += 2;
    a->write(value);
  }
  printf("Finishing\n");
  ::munmap(ptr, mapsize);
  ::close(fid);
}
