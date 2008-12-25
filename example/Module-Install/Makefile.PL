###############################################################################
# This is an example Makefile.PL for ppbuild based projects that need to be
# able to work with Module::Install
###############################################################################
use inc::Module::Install;

# Load the PPBFile, map tasks to MakeMaker rules. ( TASK => RULE );
ppbfile 'PPBFile', 'install' => 'install', 'test' => 'test';

# Obvious
WriteAll;

