class SociRstudioServerDev < Formula
  desc "Database access library for C++"
  homepage "https://soci.sourceforge.io/"
  url "https://s3.amazonaws.com/rstudio-buildtools/soci.tar.gz"
  version "4.0.0"
  sha256 "bb2e889d6aba0a1f34b862f3edc21852fadee72b181450abe0cd4ddc0589edc9"

  # bottle do
  #   sha256 "b25ecdd8f098dc48dc20195cd8852533e47e12fe6cbac8bccb31db99854d9c5b" => :catalina
  #   sha256 "0dc4c5223dcefeefbdbc647dc7827adf7fc01fe52a23f3bd325d6cf32624e532" => :mojave
  #   sha256 "76d7380ed18a0cac1d883d6d38aea9f7a43b587584f4dceab1c32f56596341cf" => :high_sierra
  # end

  depends_on "cmake" => :build
  depends_on "sqlite"
  # TODO: should there also be all the other DBs here too?

  def install
    args = std_cmake_args + %w[
      -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true
      -DSOCI_TESTS=OFF
      -DSOCI_CXX11=ON
      -DSOCI_EMPTY=OFF
      -DCMAKE_INCLUDE_PATH="#{Formula["boost-rstudio-server-dev"].opt_prefix}/include"
      -DBoost_USE_STATIC_LIBS=ON
      -DCMAKE_LIBRARY_PATH="#{Formula["boost-rstudio-server-dev"].opt_prefix}/lib"
      -DWITH_BOOST=ON
      -DWITH_POSTGRESQL=ON
      -DWITH_SQLITE3=ON
      -DWITH_DB2=OFF
      -DWITH_MYSQL=OFF
      -DWITH_ORACLE=OFF
      -DWITH_FIREBIRD=OFF
      -DWITH_ODBC=OFF
    ]

    mkdir "build" do
      system "cmake", "..", *args
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cxx").write <<~EOS
      #include "soci/soci.h"
      #include "soci/empty/soci-empty.h"
      #include <string>

      using namespace soci;
      std::string connectString = "";
      backend_factory const &backEnd = *soci::factory_empty();

      int main(int argc, char* argv[])
      {
        soci::session sql(backEnd, connectString);
      }
    EOS
    system ENV.cxx, "-o", "test", "test.cxx", "-std=c++11", "-L#{lib}", "-lsoci_core", "-lsoci_empty"
    system "./test"
  end
end