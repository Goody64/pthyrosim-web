#!/usr/bin/perl
use v5.10; use strict; use warnings;
#==============================================================================
# FILE:         testsolver.pl
# AUTHOR:       Simon X. Han
# DESCRIPTION:
#   Test the server side solver by executing it on the command line.
#
#   Make sure docRoot and fRoot are correct. 
#==============================================================================

use Data::Dumper;

use lib "../pm";
use THYROSIM;

my $thsim = THYROSIM->new(setshow    => 'default',
                          docRoot    => '/home/www',
                          fRoot      => 'thyrosimon',
                          thysim     => 'Thyrosim',
                          loadParams => 1);

# In a normal browser setting, these are done in $thsim->_processForm().
$thsim->loadParams();
$thsim->loadConversionFactors();

my $cmd = "java -cp .:/home/www/thyrosimon/java/commons-math3-3.6.1.jar:"
        . "/home/www/thyrosimon/java/ "
        . "edu.ucla.distefanolab.thyrosim.algorithm.Thyrosim"
        . " 0.322114215761171 0.201296960359917 0.63896741190756"
        . " 0.00663104034826483 0.0112595761822961 0.0652960640300348"
        . " 1.7882958476437 7.05727560072869 7.05714474742141 0 0 0 0"
        . " 3.34289716182018 3.69277248068433 3.87942133769244"
        . " 3.90061903207543 3.77875734283571 3.55364471589659"
        . " 0 1008 1 1 1 1 0 0 $thsim->{thysim} noinit"
        . " " . $thsim->getParams();

my @res = `$cmd`;
$thsim->processResults(\@res,'1');
$thsim->getBrowserObj();

# Print results to log. Make sure included comps were set to show.
my $reslog = "log";
$thsim->printCompResults($reslog,"t","1","4","7","ft4","ft3");
