###############################################################################
# This is an example Makefile.PL for ppbuild based projects that need to be
# able to produce a Makefile.
###############################################################################
use App::PPBuild::Makefile;

# Load the PPBFile
ppbfile 'PPBFile';

# Write a makefile that passes all rules to ppbuild.
# makefile will use a session to preserve rule has already been run behavior.
write_makefile;
