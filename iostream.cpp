#define _OPEN_SYS_UNLOCKED_EXT 1


#include <stdint.h>
#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>
#include <random>
#include <limits>
#include <iomanip>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>


/*
    --- Results in CYCLES ---

$ g++ -std=c++11 -O3 iostream.cpp -o iostream   (g++ 4.8.4)
$ ./iostream
           iostream+endl: 1374.68 cycles
             iostream+\n: 159.43 cycles
           Glibc+fprintf: 141.268 cycles
             Glibc+fputs: 99.5037 cycles
    Glibc+fputs_unlocked: 74.8459 cycles
            Kernel+write: 1136.71 cycles
                Str+endl: 117.318 cycles
                  Str+\n: 125.912 cycles
    iostream+double+endl: 2265.17 cycles
      iostream+double+\n: 1034.05 cycles
    Glibc+fprintf+double: 697.966 cycles
         Str+double+endl: 996.361 cycles
           Str+double+\n: 1016.91 cycles

$ clang++-3.6 -std=c++11 -O3 iostream.cpp -o iostream
$ ./iostream
           iostream+endl: 1380.73 cycles
             iostream+\n: 165.854 cycles
           Glibc+fprintf: 86.6088 cycles
             Glibc+fputs: 101.1 cycles
    Glibc+fputs_unlocked: 90.0366 cycles
            Kernel+write: 1148.61 cycles
                Str+endl: 123.951 cycles
                  Str+\n: 149.701 cycles
    iostream+double+endl: 2307.69 cycles
      iostream+double+\n: 1091.57 cycles
    Glibc+fprintf+double: 674.236 cycles
         Str+double+endl: 1052.65 cycles
           Str+double+\n: 1047.78 cycles
*/

static inline uint64_t rdtsc()
{
    uint64_t a, d;
    __asm__ volatile( "rdtsc" : "=a"( a ), "=d"( d ) );
    return ( d<<32 ) | a;
}

struct Test {
    Test( const char* msg ) : name(msg), sum(0), count(0), carry(0) {}
    double average() const { return count>0 ? sum/count : std::numeric_limits<double>::quiet_NaN(); }
    void update( uint64_t value ) { double y = value - carry; double t = sum + y; carry = (t-sum) - y; sum = t; count++; }
    std::string name;
    double sum;
    double carry;
    uint64_t count;
};



const uint64_t NLOOPS = 10000000;

int main()
{
    std::vector<Test> test{
            "iostream+endl", "iostream+\\n",
            "Glibc+fprintf", "Glibc+fputs", "Glibc+fputs_unlocked", "Kernel+write",
            "Str+endl", "Str+\\n",
            "iostream+double+endl", "iostream+double+\\n",
            "Glibc+fprintf+double",
            "Str+double+endl", "Str+double+\\n",
            "Empty"
    };
    const uint32_t numtests = test.size();
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<uint32_t> di(0,numtests-1);

    {
        std::ofstream outfile( "output1.txt", std::ios_base::trunc );
        std::ofstream outfile2( "output2.txt", std::ios_base::trunc );
        std::ostringstream outstr1;
        std::ostringstream outstr2;
        FILE* fout1 = fopen( "output3a.txt", "w" );
        FILE* fout2 = fopen( "output3b.txt", "w" );
        FILE* fout3 = fopen( "output3c.txt", "w" );
        int fid = open( "output4.txt", O_WRONLY|O_CREAT, S_IRUSR|S_IWUSR );
        if ( fid<0 )  {
            perror( "open" );
        }
        setvbuf( fout1, NULL, _IOFBF, 1*1024*1024 );
        setvbuf( fout2, NULL, _IOFBF, 1*1024*1024 );
        setvbuf( fout3, NULL, _IOFBF, 1*1024*1024 );

        uint64_t t0,t1;
        for ( uint64_t j=0; j<NLOOPS; ++j ) {
            uint32_t k = di(gen);
            double x = k/3;
            if ( (t0=rdtsc())==0 ) continue;
            switch( k ) {
                case 0: outfile << "Hello world " << std::endl; break;
                case 1: outfile2 << "Hello world " << "\n"; break;
                case 2: fprintf( fout1, "Hello world\n" ); break;
                case 3: fputs( "Hello world\n", fout2 ); break;
                case 4: fputs_unlocked( "Hello world\n", fout3 ); break;
                case 5: write( fid, "Hello world\n", 12 ); break;
                case 6: outstr1 << "Hello world " << std::endl; break;
                case 7: outstr2 << "Hello world " << "\n"; break;
                case 8: outfile << "Hello world " << x << std::endl; break;
                case 9: outfile2 << "Hello world " << x << "\n"; break;
                case 10: fprintf( fout1, "Hello world %f\n", x ); break;
                case 11: outstr1 << "Hello world " << x << std::endl; break;
                case 12: outstr2 << "Hello world " << x << "\n"; break;
                case 13: break;
            }
            if ( (t1=rdtsc())==0 ) continue;
            test[k].update( t1-t0 );
        }
        ::fclose(fout1);
        ::fclose(fout2);
        ::fclose(fout3);
        ::close(fid);
    }

    double quantum = test[numtests-1].average();
    for ( unsigned j=0; j<numtests-1; ++j ) {
        const Test& t( test[j] );
        std::cout << std::setw(24) << t.name << ": " << t.average() - quantum << " cycles " << std::endl;
    }
    return 0;
}
