use inc::Module::Install;

name           'App-PPBuild';
all_from       'lib/App/PPBuild.pm';
install_script 'bin/ppbuild';

WriteAll;
