#include <cstdint>
#include <string>
#include <iostream>

template <class T>
class myallocator
{
public:
    using value_type    = T;

    myallocator() noexcept {}  // not required, unless used
    template <class U> myallocator(myallocator<U> const&) noexcept {}

    value_type*  // Use pointer if pointer is not a value_type*
    allocate(std::size_t n)
    {
        value_type* res = static_cast<value_type*>(::operator new (n*sizeof(value_type)));
        std::cout << "myallocator(" << this << ")::allocate called " << res << std::endl;
        return res;
    }

    void
    deallocate(value_type* p, std::size_t) noexcept  // Use pointer if pointer is not a value_type*
    {
        std::cout << "myallocator("<< this << ")::deallocate called " << p << std::endl;
        ::operator delete(p);
    }
private:

};

template <class T, class U>
bool
operator==(myallocator<T> const&, myallocator<U> const&) noexcept
{
    return true;
}

template <class T, class U>
bool
operator!=(myallocator<T> const& x, myallocator<U> const& y) noexcept
{
    return !(x == y);
}

class Test {
    public:
    Test() {
        std::cout << "Trivial constructor called " << this << std::endl;
    }
    Test( const std::string& s ) {
        std::cout << "String constructor called " << this << std::endl;
        val = s;
    }
    template< unsigned N >
    Test( const char (&s)[N]  ) {
        std::cout << "Const char reference constructor called "
                  << this << std::endl;
        val = s;
    }
    Test( const Test& t ) {
        val = t.val;
        std::cout << "Copy constructor called " << this << std::endl;
    }
    Test( const Test&& t ) {
        val = t.val;
        std::cout << "Universal reference constructor called "
                  << this << " " << &t << std::endl;
    }
    ~Test() {
        std::cout << "Destructor called " << this << std::endl;
    }
private:
    std::string val;
};

#define EXEC(x) { \
    std::cout << "----> " << #x << std::endl;   \
    x;                                          \
    std::cout << "<--- "<< #x << std::endl;     \
}

#include <vector>

template< template<typename> typename Allocator>
void test()
{
    using AllocatorType = Allocator<Test>;
    AllocatorType a1, a2;
    using VecType = std::vector<Test,AllocatorType>;
    VecType v1(a1);
    VecType v2(a2);
    EXEC( v1.emplace_back( "string1" ); );
    EXEC( v2.emplace_back( v1.front() ); );
}

int main()
{
    EXEC( test<std::allocator>(); );
    EXEC( test<myallocator>(); );
    return 0;
}
