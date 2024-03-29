use inc::Module::Install;

name          ( 'PPI-Tinderbox'              );
abstract      ( 'The PPI Tinderbox - Parse every module in CPAN' );
author        ( 'Adam Kennedy<cpan@ali.as>'  );
version_from  ( 'lib/PPI/Tinderbox.pm'       );
license       ( 'perl'                       );

requires      ( 'perl'            => '5.005' );
requires      ( 'Time::HiRes'     => '1.64'  );
requires      ( 'PPI'             => '0.840' );
requires      ( 'PPI::Processor'  => '0.14'  );
requires      ( 'CPAN::Processor' => '0.07'  );

build_requires( 'File::Spec'      => '0.82'  );
build_requires( 'Test::More'      => '0.47'  );

auto_install();

&WriteAll;
