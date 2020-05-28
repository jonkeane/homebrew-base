class BoostRstudioServer < Formula
  desc "Collection of portable C++ source libraries"
  homepage "https://www.boost.org/"
  url "https://downloads.sourceforge.net/project/boost/boost/1.69.0/boost_1_69_0.tar.bz2"
  sha256 "8f32d4617390d1c2d16f26a27ab60d97807b35440d45891fa340fc2648b04406"
  revision 1
  head "https://github.com/boostorg/boost.git"

   # bottle do
   #   cellar :any
   #   sha256 "52d3c80972a0af00b4a5779ca192ef1d2b5792e56acce6ab670b46546ba43418" => :mojave
   #   sha256 "7562a990f0393b8186564fee26cfb908cc21b45bb3bfa52b55d7e78c8d82957f" => :high_sierra
   #   sha256 "0c42d1ba47651b72a761218c2e00143bea3c7771c84319a847225b95dc861aa6" => :sierra
   # end

   depends_on "icu4c"

   def install
     # Force boost to compile with the desired compiler
     open("user-config.jam", "a") do |file|
       file.write "using darwin : : #{ENV.cxx} ;\n"
     end

     # libdir should be set by --prefix but isn't
     icu4c_prefix = Formula["icu4c"].opt_prefix
     bootstrap_args = %W[
       --prefix=#{prefix}
       --libdir=#{lib}
       --with-icu=#{icu4c_prefix}
     ]

     # Handle libraries that will not be built.
     without_libraries = ["mpi"]

     # Boost.Log cannot be built using Apple GCC at the moment. Disabled
     # on such systems.
     without_libraries << "log" if ENV.compiler == :gcc

     bootstrap_args << "--without-libraries=#{without_libraries.join(",")}"

     # layout should be synchronized with boost-python and boost-mpi
     # what is variant=realese about and is it needed? 
     args = %W[
       --prefix=#{prefix}
       --libdir=#{lib}
       --user-config=user-config.jam
       -sNO_LZMA=1
       -sNO_ZSTD=1       
       install
       threading=multi
       link=static,shared
       variant=release
     ]

     # toolset=clang-darwin needs adjusting for linux
     args << "toolset=clang-darwin" 
     # args << "cxxflags=-fPIC -std=c++11 -mmacosx-version-min=10.12" 
     # # Boost is using "clang++ -x c" to select C compiler which breaks C++14
     # # handling using ENV.cxx14. Using "cxxflags" and "linkflags" still works.
     args << "cxxflags=-std=c++14" # was 14
     if ENV.compiler == :clang
       args << "cxxflags=-stdlib=libc++" << "linkflags=-stdlib=libc++"
     end

     system "./bootstrap.sh", *bootstrap_args
     system "./b2", "headers"
     system "./b2", *args
   end

   def caveats
     s = ""
     # ENV.compiler doesn't exist in caveats. Check library availability
     # instead.
     if Dir["#{lib}/libboost_log*"].empty?
       s += <<~EOS
         Building of Boost.Log is disabled because it requires newer GCC or Clang.
       EOS
     end

     s
   end

   test do
     (testpath/"test.cpp").write <<~EOS
       #include <boost/algorithm/string.hpp>
       #include <string>
       #include <vector>
       #include <assert.h>
       using namespace boost::algorithm;
       using namespace std;
       int main()
       {
         string str("a,b");
         vector<string> strVec;
         split(strVec, str, is_any_of(","));
         assert(strVec.size()==2);
         assert(strVec[0]=="a");
         assert(strVec[1]=="b");
         return 0;
       }
     EOS
     system ENV.cxx, "test.cpp", "-std=c++14", "-stdlib=libc++", "-o", "test"
     system "./test"
   end
 end