#!/usr/bin/perl
use v5.10; use strict; use warnings;
#==============================================================================
# FILE:         THYROSIM.pm
# AUTHOR:       Simon X. Han
# DESCRIPTION:
#   Package where Thyroid Simulator subroutines live.
# NOTES:
#   SS: Steady state
#   IC: Initial condition
#   iX: Prefix for the Xth integration
#   qX: Prefix for the Xth compartment, refers only to q1 - q19
#   cX: Prefix for the Xth compartment, refers to both qX and pseudo
#       compartments.
#==============================================================================

package THYROSIM;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

#====================================================================
# SUBROUTINE:   new
# DESCRIPTION:
#   Returns an object of THYROSIM.
#====================================================================
sub new {
    my ($class,%params) = @_;
    my $self = {};

    #--------------------------------------------------
    # Define existing compartments. Must match java/Thyrosim.java.
    #--------------------------------------------------

    # Compartments 1-19 are as defined in the ODEs. The pseudo compartments are
    # those needed by the program, but not part of the ODEs. Values match the
    # order results from java/Thyrosim.java is printed.
    $self->{compartment}->{t}   = 0;  # Pseudo compartment
    $self->{compartment}->{1}   = 1;
    $self->{compartment}->{2}   = 2;
    $self->{compartment}->{3}   = 3;
    $self->{compartment}->{4}   = 4;
    $self->{compartment}->{5}   = 5;
    $self->{compartment}->{6}   = 6;
    $self->{compartment}->{7}   = 7;
    $self->{compartment}->{8}   = 8;
    $self->{compartment}->{9}   = 9;
    $self->{compartment}->{10}  = 10;
    $self->{compartment}->{11}  = 11;
    $self->{compartment}->{12}  = 12;
    $self->{compartment}->{13}  = 13;
    $self->{compartment}->{14}  = 14;
    $self->{compartment}->{15}  = 15;
    $self->{compartment}->{16}  = 16;
    $self->{compartment}->{17}  = 17;
    $self->{compartment}->{18}  = 18;
    $self->{compartment}->{19}  = 19;
    $self->{compartment}->{ft4} = 20; # Pseudo compartment
    $self->{compartment}->{ft3} = 21; # Pseudo compartment

    # Shorthand for the 19 ODE compartments
    $self->{qdots} = [ 1 .. 19 ];

    #--------------------------------------------------
    # Set which results to send to the browser
    #--------------------------------------------------

    # By default, send t, q1, q4, q7, ft4, and ft3 to browser
    $self->{show}->{t}   = 1;
    $self->{show}->{1}   = 1;
    $self->{show}->{4}   = 1;
    $self->{show}->{7}   = 1;
    $self->{show}->{ft4} = 1;
    $self->{show}->{ft3} = 1;

    # Can additionally send everything to browser
    if ($params{setshow} eq "all") {
        foreach my $c (keys %{$self->{compartment}}) {
            $self->{show}->{$c} = 1;
        }
    }

    #--------------------------------------------------
    # Set document root and file root
    #--------------------------------------------------
    $self->{docRoot} = $params{docRoot};
    $self->{fRoot}   = $params{fRoot};

    #--------------------------------------------------
    # SS values. Ran model for 1008 hours and taking final values.
    #--------------------------------------------------

    # Thysim: Thyrosim
    # Calculated by Lu Chen using Marisa's IC
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{1}  = 0.322114215761171;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{2}  = 0.201296960359917;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{3}  = 0.638967411907560;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{4}  = 0.00663104034826483;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{5}  = 0.0112595761822961;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{6}  = 0.0652960640300348;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{7}  = 1.78829584764370;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{8}  = 7.05727560072869;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{9}  = 7.05714474742141;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{10} = 0;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{11} = 0;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{12} = 0;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{13} = 0;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{14} = 3.34289716182018;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{15} = 3.69277248068433;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{16} = 3.87942133769244;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{17} = 3.90061903207543;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{18} = 3.77875734283571;
    $self->{ICKey}->{Thyrosim}->{1000088010000880}->{19} = 3.55364471589659;

    # Thysim: ThyrosimJr
    # Calculated by Simon Han using updated parameters from Aaron et al.
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{1}  = 0.08537986566616353;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{2}  = 0.11151355189891558;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{3}  = 0.11757879939521299;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{4}  = 0.0021584999885251883;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{5}  = 0.003844919701867285;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{6}  = 0.02891231073810239;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{7}  = 5.201125786290925;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{8}  = 5.553663927601651;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{9}  = 5.556354748291701;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{10} = 0;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{11} = 0;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{12} = 0;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{13} = 0;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{14} = 10.134192450244074;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{15} = 11.557153559626624;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{16} = 12.431906546150651;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{17} = 12.71040493270924;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{18} = 12.443498542246873;
    $self->{ICKey}->{ThyrosimJr}->{1000088010000880}->{19} = 11.75608393106433;

    #--------------------------------------------------
    # Define input types and hormones
    #--------------------------------------------------

    # Define input types
    $self->{inputType}->{1} = "Oral";
    $self->{inputType}->{2} = "IV";
    $self->{inputType}->{3} = "Infusion";

    $self->{inputType}->{Oral}     = 1;
    $self->{inputType}->{IV}       = 2;
    $self->{inputType}->{Infusion} = 3;

    # Define hormone types
    $self->{hormone}->{3} = "T3";
    $self->{hormone}->{4} = "T4";

    $self->{hormone}->{T3} = 3;
    $self->{hormone}->{T4} = 4;

    #--------------------------------------------------
    # Define other simulation parameters
    #--------------------------------------------------

    # Define default dial values
    $self->{dial}->{1} = 100; # T4 Secretion
    $self->{dial}->{2} = 88;  # T4 Absorption
    $self->{dial}->{3} = 100; # T3 Secretion
    $self->{dial}->{4} = 88;  # T3 Absorption

    # Define default simulation time (days)
    $self->{simTime} = 5;
    $self->{simTimeMax} = 100;

    # Define default thysim
    $self->{thysim}  = $params{thysim}  // "Thyrosim";

    # Define default recalculate IC (0 for no)
    $self->{recalcIC} = 0;

    # Define molecular weights of T3 & T4, to convert between mcg and mols
    $self->{toMols}->{3}   = 651;
    $self->{toMols}->{4}   = 777;
    $self->{toMols}->{T3}  = 651;
    $self->{toMols}->{T4}  = 777;
    $self->{toMols}->{TSH} = 5.6;

    bless $self, $class;

    #--------------------------------------------------
    # Post-bless initializations
    #--------------------------------------------------

    # Initialize compartments
    $self->initCompartments();

    # Load parameter list if forced
    if ($params{loadParams}) {
        $self->loadParams();
        $self->{loadParams} = 1;
    }

    return $self;
}

#====================================================================
# SUBROUTINE:   initCompartments
# DESCRIPTION:
#   Initialize each compartment. Only 'show' compartments will have 'values'
#   populated. While end values will always be populated, be aware that they are
#   iteration dependant, so are more like temporary values.
#
#   min/max:    Will be initialized when the first value is seen.
#====================================================================
sub initCompartments {
    my ($self) = @_;
    my @cs = keys %{$self->{compartment}}; # All compartments
    foreach my $c (@cs) {
        $self->{data}->{$c} = {};
        $self->{data}->{$c}->{name} = $c;
        $self->{data}->{$c}->{min} = undef;
        $self->{data}->{$c}->{max} = undef;
        $self->{data}->{$c}->{end} = 0;
        $self->{data}->{$c}->{idx} = $self->getCompIdx($c);
        $self->{data}->{$c}->{count} = 0;
        $self->{data}->{$c}->{values} = []; # arrayRef
    }
}

#====================================================================
# SUBROUTINE:   processForm
# DESCRIPTION:
#   The parameter 'data' can come in one of two forms:
#     1. A string with all simulation conditions or
#     2. An experiment name
#   In 1, the string can be fed to processForm() to parse simulation conditions.
#   In 2, retrieve a 'data' string using the experiment name and then feed to
#   processForm().
#
#   Since the parameter thysim is used in many different places, it is set here
#   first. If the value from getExperiment() also has thysim, then thysim is
#   overwritten. This gives us some flexibility in terms of whether to define
#   thysim specific experiments in getExperiment().
#
#   For testing, can use a custom experiment, like:
#   $data = $self->getExperiment("simple-3");
#
#   Additional initializations done here:
#     loadParams() if 'data' is an experiment name
#     loadConversionFactors()
#====================================================================
sub processForm {
    my ($self,$data) = @_;

    my $form = $self->getFormParams($data);
    $self->setLvl1('thysim',$form->{thysim}) if exists $form->{thysim};

    # Check for experiment
    if (exists $form->{experiment}) {
        $self->_processForm($self->getExperiment($form->{experiment}));
        $self->loadParams();
    } else {
        $self->_processForm($data);
    }

    # Load conversion factors.
    $self->loadConversionFactors();
}

#====================================================================
# SUBROUTINE:   _processForm
# DESCRIPTION:
#   Given 'data', split into individual simulation conditions and organize them
#   as follows:
#     Total simulation time:
#       $self->{simTime}        = $number
#     Recalculate initial conditions:
#       $self->{recalcIC}       = $number
#     Dials (secretion/absorption):
#       $self->{dial}->{$dial}  = $number
#     Thyrosim model:
#       $self->{thysim}         = $string
#     Simulation conditions (each input has some of the below):
#       $self->{input}->{$num}->{dose}       = $number
#       $self->{input}->{$num}->{int}        = $number
#       $self->{input}->{$num}->{singledose} = $number
#       $self->{input}->{$num}->{start}      = $number
#       $self->{input}->{$num}->{end}        = $number
#       $self->{input}->{$num}->{disabled}   = $number
#       $self->{input}->{$num}->{hormone}    = $number
#       $self->{input}->{$num}->{type}       = $number
#   Additional initializations done here:
#     setInitialIC()
#     detIntSteps()
# NOTES: $num is the $num-th input
#====================================================================
sub _processForm {
    my ($self,$data) = @_;

    my $form = $self->getFormParams($data);

    # Save the form parameters
    foreach my $key (keys %$form) {
        # Total simulation time
        if ($key eq "simtime") {
            my $simtime = $form->{$key} > $self->{simTimeMax}
                        ? $self->{simTimeMax} : $form->{$key};
            $self->setLvl1('simTime',$simtime);
        # Recalculate IC
        } elsif ($key eq "recalcIC") {
            $self->setLvl1('recalcIC',$form->{$key});
        # Dials
        } elsif ($key =~ m/^dialinput(\d)/) {
            $self->setLvl2('dial',$1,$form->{$key});
        # Thysim model
        } elsif ($key eq "thysim") {
            $self->setLvl1('thysim',$form->{$key});
        # Parameter value - kdelay
        } elsif ($key eq "kdelay") {
            $self->setLvl2('params','kdelay',$form->{$key});
        # Parameter values - p1-48
        } elsif ($key =~ m/^p\d+/) {
            $self->setLvl2('params',$key,$form->{$key});
        # Dosing information. Assume splittable by '-'
        } elsif ($key =~ m/(\w+)-(\d+)/) {
            $self->setLvl3('input',$2,$1,$form->{$key});
        # Ignore un-identified inputs
        } else {
        }
    }

    # Check if parameters were passed from the browser
    if (!defined $self->getLvl2('params','kdelay')) {
        $self->loadParams();
    }

    # Build $self->{IC}->{0}. Only needed when recalculating IC
    $self->setInitialIC();

    # Determine intergration steps
    $self->detIntSteps();
}

#====================================================================
# SUBROUTINE:   processResults
# DESCRIPTION:
#   Process results from the solver. Each line of results contains the
#   following:
#     [0]:    t
#     [1-19]: q1 to q19 values at t
#     [20]:   FT4p at t
#     [21]:   FT3p at t
#   Do:
#     - Save results for show compartments
#     - Update min/max values
#     - Update total number of results
#     - Set end values as initial conditions for the next iteration
#     - Adjust initial conditions by input amounts
#====================================================================
sub processResults {
    my ($self,$res,$iThis) = @_;

    my $iNext = $iThis + 1;

    my $ln_total = scalar @$res; # ln for lines
    my $ln_count = 1;

    my @shows = keys %{$self->{show}};        # Compartments to show
    my @comps = keys %{$self->{compartment}}; # All compartments
    my @qdots = @{$self->{qdots}};            # q1 - q19

    # Iterate over lines of results
    foreach my $line (@$res) {
        $line =~ s/[\r\n]*$//; # Remove newline
        my @row = split / /, $line;

        # Iterate over all show compartments
        foreach my $c (@shows) {
            my $s = $self->{data}->{$c}; # Shorthand
            my $v = $row[$s->{idx}];     # Value

            # Adjust value for t so that it is continuous:
            # 0 1 2 3 0 1 2 3 => 0 1 2 3 4 5 6 7
            $v += $s->{end} if $c eq "t";

            # Save value only for i1+ because i0 isn't shown to users
            push(@{$s->{values}},$v) if $iThis > 0;

            # Initialize min/max
            $s->{min} = $v if !defined $s->{min};
            $s->{max} = $v if !defined $s->{max};

            # Update min/max
            $s->{min} = $v if $v < $s->{min};
            $s->{max} = $v if $v > $s->{max};
        }

        # This is the last line of results
        if ($ln_total == $ln_count) {

            # Update all end values
            foreach my $c (@comps) {
                my $s = $self->{data}->{$c}; # Shorthand
                my $v = $row[$s->{idx}];     # Value

                # For time, the end value has to be the overall end value. When
                # $s->{values}->[-1] is not defined, as in i0, use $s->{end},
                # which is initialized as 0. For other compartments, taking the
                # $v here suffices. Cannot use $s->{values}->[-1] because values
                # are only saved for $iThis > 0;
                if ($c eq "t") {
                    $s->{end} = $s->{values}->[-1] // $s->{end};
                } else {
                    $s->{end} = $v;
                }
            }
        }

        $ln_count++;
    } # Iterate over lines of results end

    #--------------------------------------------------
    # Post-iteration processing
    #--------------------------------------------------

    # Save end values as IC for next iteration (only qdots)
    foreach my $c (@qdots) {
        $self->{IC}->{$iNext}->{$c} = $self->{data}->{$c}->{end};
    }

    # Make input adjustments for next iteration
    $self->setAdjustedIC($iThis);

    # Update counts (all compartments). Updating counts here allows checking how
    # many new values were added per iX.
    foreach my $c (@comps) {
        my $s = $self->{data}->{$c}; # Shorthand
        $s->{count} = scalar @{$s->{values}};
    }

}

#====================================================================
# SUBROUTINE:   processKeyVal
# DESCRIPTION:
#   Set next integration's IC with values from an $ickey. Then, make adjustments
#   to IC based on inputs.
#
#   Currently only used when i0 is skipped and this is used to set i1's IC with
#   values from a default $ickey.
#====================================================================
sub processKeyVal {
    my ($self,$ickey,$iThis) = @_;
    my $iNext  = $iThis + 1;
    my $thysim = $self->getThysim();
    my $qs = $self->getLvl3('ICKey',$thysim,$ickey);
    # Loop through all compartments to set their IC
    foreach my $c (keys %$qs) {
        $self->{IC}->{$iNext}->{$c} = $qs->{$c};
    }
    $self->setAdjustedIC($iThis);
}

#====================================================================
# SUBROUTINE:   detIntSteps
# DESCRIPTION:
#   Determine integration steps. Everytime an input is given, integration must
#   be stopped, initial conditions updated to reflect the input, and
#   re-submitted to the solver.
#
#   For example, if an oral dose is given at times 0 and 2 days, the solver
#   needs to be called for the following time intervals:
#     1. A time interval so the system reaches steady state. This is the 0th
#        integration and should already be done by this point.
#     2. [0 48] hours for the 1st input between times 0 and 2 days.
#     3. [0 simtime-48] for the 2nd input between times 2 and end of simulation.
#
#   In case of infusion, integration must also restart at end times.
#
#   First, keep track whether a time is a start or end time, as well as what
#   inputs are relevant at that time:
#     $self->{inputTime}->{$time}->{$input_num} = start or end
#   $time can be either $starttime or endtime. This object will be looked at by
#   setAdjustedIC() to adjust IC. In general, $endtime will only be noted if it
#   is the end of an infusion.
#
#   Second, the above is looped through to determine integration steps.
#   Integration steps are organized as follows:
#     $self->{thisStep}->{$iThis}->[0] = $starttime
#     $self->{thisStep}->{$iThis}->[1] = $endtime
# NOTES:
#   $iThis is the iteration when an input is introduced, so therefore should
#   always be a "start" time. If an input is given at simulation start, it would
#   be at i1. If an input is given at some time after simulation start, it would
#   be at >= i2. Since i1 in this case would take place during the time between
#   simulation start and when the 1st input is given.
#====================================================================
sub detIntSteps {
    my ($self) = @_;

    my $simtime = $self->getLvl1('simTime');

    # Loop through all inputs to find start/end times
    my $inputs = $self->{input}; # Shorthand

    # No inputs? Run simulation from 0 to simtime
    if (!defined $inputs) {
        $self->setIntStart('thisStep',1,0);
        $self->setIntStart('trueStep',1,0);
        $self->setIntBound('thisStep',1,$simtime);
        $self->setIntBound('trueStep',1,$simtime);
        return 1;
    }

    # Initialize inputTime 0. If there is an input at t=0, this initialization
    # will not do anything. If there isn't one, this serves as a placeholder
    # for determining intergration intervals.
    $self->{inputTime}->{0}->{0} = "start";

    foreach my $inputNum (keys %$inputs) {
        my $thisInput = $inputs->{$inputNum}; # Save typing
        my $type  = $self->getLvl3('input',$inputNum,'type');
        my $start = $self->getLvl3('input',$inputNum,'start');
        my $end   = $self->getLvl3('input',$inputNum,'end');
        my $int   = $self->getLvl3('input',$inputNum,'int');

        # Oral
        if ($type == 1) {
            if ($self->getLvl3('input',$inputNum,'singledose')) {
                $self->{inputTime}->{$start}->{$inputNum} = "start";

            # Not singledose? Create input based on once every X interval
            } else {
                my $thisStart = $start;
                while ($thisStart <= $end) {
                    $self->{inputTime}->{$thisStart}->{$inputNum} = "start";
                    $thisStart+=$int;
                }
            }
        }

        # IV Pulse
        if ($type == 2) {
            $self->{inputTime}->{$start}->{$inputNum} = "start";
        }

        # Infusion
        if ($type == 3) {
            $self->{inputTime}->{$start}->{$inputNum} = "start";
            $self->{inputTime}->{$end}->{$inputNum}   = "end";

            # Figure/set infusion quantity
            my $duration = $end - $start;
            my $hours    = $self->toHour($duration);
            my $mcg      = $self->getLvl3('input',$inputNum,'dose');
            my $hormone  = $self->getLvl3('input',$inputNum,'hormone');
            my $toMols   = $self->getLvl2('toMols',$hormone);

            my $infValue = $mcg / $toMols / 24; # Dose is per day

            # T3
            if ($hormone == 3) {
                $self->setLvl3('infusion',$inputNum,'u4',$infValue);
            }

            # T4
            if ($hormone == 4) {
                $self->setLvl3('infusion',$inputNum,'u1',$infValue);
            }
        }
    }

    # After building all relevant times, determine integration intervals
    my ($count,$prior,$reqToSimTime) = (0,0,1);
    foreach my $time (sort {$a <=> $b} keys %{$self->{inputTime}}) {

        if ($count > 0) {
            # Integration always start at t = 0
            $self->setIntStart('thisStep',$count,0);
            $self->setIntStart('trueStep',$count,$prior);

            # Determine integration end time.
            # Check total simulation against current time. Cut integration
            # interval short if necessary.
            if ($time >= $simtime) {
                $time = $simtime;
                $reqToSimTime = 0;
            }

            $time = $time > $simtime ? $simtime : $time;
            my $intEnd = $time - $prior;
            $self->setIntBound('thisStep',$count,$intEnd);
            $self->setIntBound('trueStep',$count,$time);
        }

        # Update variables for determining next interval
        $prior = $time;
        $count++;
        last if !$reqToSimTime; # Skip all other inputs if $simtime is reached.
    }

    # Determine last interval here. Should be $time to $simtime
    if ($reqToSimTime) {
        my $intEnd = $simtime - $prior;
        $self->setIntStart('thisStep',$count,0);
        $self->setIntStart('trueStep',$count,$prior);

        $self->setIntBound('thisStep',$count,$intEnd);
        $self->setIntBound('trueStep',$count,$simtime);
    }
}

#====================================================================
# SUBROUTINE:   loadParams
# DESCRIPTION:
#   Loads parameters for a given thysim model. By default, loads
#   Thyrosim.params. See the config/ dir for a list of thysim.
#====================================================================
sub loadParams {
    my ($self) = @_;

    $self->{thysim} = $self->{thysim} // "Thyrosim";

    my $file = "../config/" . $self->{thysim} . ".params";
    open my $fh, '<', $file or die "Can't open file '$file': $!";

    while (my $row = <$fh>) {
        $row =~ s/[\r\n]*$//; # Remove newline
        my ($key,$value) = split /=/, $row;
        $self->{params}->{$key} = $value;
    }

    close $fh or die "Can't close file '$file': $!";
}

#====================================================================
# SUBROUTINE:   loadConversionFactors
# DESCRIPTION:
#   Load conversion factors.
#
#   Conversion factors of T3, T4, and TSH from mcg/dL to mols.
#====================================================================
sub loadConversionFactors {
    my ($self) = @_;

    my $p47 = $self->{params}->{p47}; # Plasma volume (L)
    my $p48 = $self->{params}->{p48}; # TSH volume (L)
    my $ft4 = 0.45; # Temp conversion factor for free T4
    my $ft3 = 0.50; # Temp conversion factor for free T3

    $self->{CF}->{T4}  = $self->{toMols}->{T4} /$p47; # mcg/L
    $self->{CF}->{T3}  = $self->{toMols}->{T3} /$p47; # mcg/L
    $self->{CF}->{TSH} = $self->{toMols}->{TSH}/$p48; # mU/L
    $self->{CF}->{FT4} = $ft4 * 1000 * $self->{CF}->{T4}; # ng/L
    $self->{CF}->{FT3} = $ft3 * 1000 * $self->{CF}->{T3}; # ng/L
}

#====================================================================
# SUBROUTINE:   setInitialIC
# DESCRIPTION:
#   Take values from the default $ickey and put it into the object that keeps
#   initial conditions for i0.
#====================================================================
sub setInitialIC {
    my ($self) = @_;

    my $thysim = $self->getThysim();
    my $ickey  = $self->getICKey('default');
    my $qs     = $self->getLvl3('ICKey',$thysim,$ickey);
    # Loop through all compartments to set their IC for i0
    foreach my $c (keys %$qs) {
        $self->{IC}->{0}->{$c} = $qs->{$c};
    }
}

#====================================================================
# SUBROUTINE:   setAdjustedIC
# DESCRIPTION:
#   Adjust IC with input quantity as appropriate.
# NOTES:
#   Input types: 1 = Oral, 2 = IV, 3 = Infusion
#   Hormone: 3 = T3, 4 = T4
#====================================================================
sub setAdjustedIC {
    my ($self,$iThis) = @_;

    my $iNext = $iThis + 1;

    # Check whether there is a next iteration, skip if there isn't
    return 1 if !exists $self->{trueStep}->{$iNext};

    # Find all inputs given at $trueStart
    my $trueStart = $self->getIntStart('trueStep',$iNext);
    foreach my $inputNum (keys %{$self->{inputTime}->{$trueStart}}) {

        # Initialized inputTime->0 is an empty hashRef
        next if (!$self->{input}->{$inputNum});

        # Get hormone's info
        my $hormone = $self->getLvl3('input',$inputNum,'hormone');
        my $type    = $self->getLvl3('input',$inputNum,'type');
        my $dose    = $self->getLvl3('input',$inputNum,'dose');

        # Get the conversion factor
        my $toMols = $self->getLvl2('toMols',$hormone);

        # Initialize newIC variables
        my $newIC = 0;

        # T3 input
        if ($hormone == 3) {

            # Update T3 oral compartment
            if ($type == 1) {
                $newIC = $self->getLvl3('IC',$iNext,12) + $dose/$toMols;
                $self->setLvl3('IC',$iNext,12,$newIC);
            }

            # Update T3 IV compartment
            if ($type == 2) {
                $newIC = $self->getLvl3('IC',$iNext,4) + $dose/$toMols;
                $self->setLvl3('IC',$iNext,4,$newIC);
            }
        }

        # T4 input
        if ($hormone == 4) {

            # Update T4 oral compartment
            if ($type == 1) {
                $newIC = $self->getLvl3('IC',$iNext,10) + $dose/$toMols;
                $self->setLvl3('IC',$iNext,10,$newIC);
            }

            # Update T4 IV compartment
            if ($type == 2) {
                $newIC = $self->getLvl3('IC',$iNext,1) + $dose/$toMols;
                $self->setLvl3('IC',$iNext,1,$newIC);
            }
        }
    }
}

#====================================================================
# SUBROUTINE:   getBrowserObj
# DESCRIPTION:
#   Generate an object to send to the browser for graphing. The object has:
#     $obj->{simTime}
#         ->{data}->{$c}->{min}
#                       ->{max}
#                       ->{count}
#                       ->{values}
#
#   Everything was generated in processResults(). Here, we additionally convert
#   all 'values' from mols to display units.
#====================================================================
sub getBrowserObj {
    my ($self) = @_;

    # Get conversion factors
    my $cfs;
    $cfs->{1}   = $self->{CF}->{T4};
    $cfs->{4}   = $self->{CF}->{T3};
    $cfs->{7}   = $self->{CF}->{TSH};
    $cfs->{ft4} = $self->{CF}->{FT4};
    $cfs->{ft3} = $self->{CF}->{FT3};

    #--------------------------------------------------
    # Generate the browser object
    #--------------------------------------------------

    my $obj;

    # Copy simTime over
    $obj->{simTime} = $self->getLvl1('simTime');

    # Iterate over show compartments
    my @shows = keys %{$self->{show}}; # Compartments to show
    foreach my $c (@shows) {

        # Copy data over as is
        $obj->{data}->{$c} = $self->{data}->{$c};

        # For non-time compartments, apply conversion factor
        my $cf = $cfs->{$c} // 1;
        my $s = $obj->{data}->{$c}; # Shorthand
        $s->{end} = sprintf("%.4f", $s->{end}*$cf); # 4 decimal places
        $s->{min} = sprintf("%.4f", $s->{min}*$cf);
        $s->{max} = sprintf("%.4f", $s->{max}*$cf);
        @{$s->{values}} = map { sprintf("%.4f", $_*$cf) } @{$s->{values}};

        # NOTES: Since we're dealing with references, the above will change the
        # original $self->{data} values. This is why getBrowserObj() should only
        # be called right before sending data to the browser.
    }

    $self->{browserObj} = $obj; # Save a copy
    return $obj;
}

#====================================================================
# SUBROUTINE:   setLvl1
# DESCRIPTION:
#   Save a value 1 level after $self.
# USES:
#   simTime: total simulation time
#     $self->{simTime} = $value
#   recalcIC: whether to recalculate initial conditions
#     $self->{recalcIC} = binary
#   thysim: the thysim model to use
#     $self->{thysim} = $thysim
#====================================================================
sub setLvl1 {
    $_[0]->{$_[1]} = $_[2];
}

#====================================================================
# SUBROUTINE:   setLvl2
# DESCRIPTION:
#   Save a value 2 levels after $self.
# USES:
#   dial: saves $value of a $dial
#     $self->{dial}->{$dial} = $value
#====================================================================
sub setLvl2 {
    $_[0]->{$_[1]}->{$_[2]} = $_[3];
}

#====================================================================
# SUBROUTINE:   setLvl3
# DESCRIPTION:
#   Save a value 3 levels after $self.
# USES:
#   input: saves $value of input parameter $name given $inputNum
#     $self->{input}->{$inputNum}->{$name} = $value
#====================================================================
sub setLvl3 {
    $_[0]->{$_[1]}->{$_[2]}->{$_[3]} = $_[4];
}

#====================================================================
# SUBROUTINE:   setIntStart
# DESCRIPTION:
#   Set the start time.
# USES:
#   thisStep: refers to 'this' interval's start time.
#     $self->{thisStep}->{$count}->[0] = $value
#   trueStep: refers to 'true' interval's start time.
#     $self->{trueStep}->{$count}->[0] = $value
# NOTES: $count is an integer that correponds with iX.
#====================================================================
sub setIntStart {
    $_[0]->{$_[1]}->{$_[2]}->[0] = $_[3];
}

#====================================================================
# SUBROUTINE:   setIntBound
# DESCRIPTION:
#   Set the end time (bound).
# USES:
#   thisStep: refers to 'this' interval's end time.
#     $self->{thisStep}->{$count}->[1] = $value
#   trueStep: refers to 'true' interval's end time.
#     $self->{trueStep}->{$count}->[1] = $value
# NOTES: $count is an integer that correponds with iX.
#====================================================================
sub setIntBound {
    $_[0]->{$_[1]}->{$_[2]}->[1] = $_[3];
}

#====================================================================
# SUBROUTINE:   getIntStart
# DESCRIPTION:
#   Get the start time.
# USES:
#   thisStep: refers to 'this' interval's start time.
#     $self->{thisStep}->{$count}->[0] = $value
#   trueStep: refers to 'true' interval's start time.
#     $self->{trueStep}->{$count}->[0] = $value
# NOTES: $count is an integer that corresponds with iX.
#====================================================================
sub getIntStart {
    return $_[0]->{$_[1]}->{$_[2]}->[0];
}

#====================================================================
# SUBROUTINE:   getIntBound
# DESCRIPTION:
#   Get the end time (bound).
# USES:
#   thisStep: refers to 'this' interval's end time.
#     $self->{thisStep}->{$count}->[1] = $value
#   trueStep: refers to 'true' interval's end time.
#     $self->{trueStep}->{$count}->[1] = $value
# NOTES: $count is an integer that corresponds with iX.
#====================================================================
sub getIntBound {
    return $_[0]->{$_[1]}->{$_[2]}->[1];
}

#====================================================================
# SUBROUTINE:   getIntCount
# DESCRIPTION:
#   returns an arrayRef of $count.
# NOTES: $count is an integer that corresponds with iX.
#====================================================================
sub getIntCount {
    my ($self) = @_;
    my @counts;
    foreach my $count (sort {$a <=> $b} keys %{$self->{thisStep}}) {
        push(@counts,$count);
    }
    return \@counts;
}

#====================================================================
# SUBROUTINE:   getICKey
# DESCRIPTION:
#   Retrieve the initial condition 'key' which is just all the dial values in
#   sequence. For default dial values, the key would be '1000088010000880'.
#====================================================================
sub getICKey {
    my ($self,$default) = @_;

    # If user selected to not recalculate IC, return default ICKEY
    if ($default || !$self->recalcIC()) {
        return "1000088010000880";
    }

    # Get the dial values
    return sprintf("%04d",$self->getLvl2('dial',1) * 10)
         . sprintf("%04d",$self->getLvl2('dial',2) * 10)
         . sprintf("%04d",$self->getLvl2('dial',3) * 10)
         . sprintf("%04d",$self->getLvl2('dial',4) * 10);
}

#====================================================================
# SUBROUTINE:   getICString
# DESCRIPTION:
#   Turn initial conditions into a string for input into the solver. IC is only
#   needed for q1 - q19.
#====================================================================
sub getICString {
    my ($self,$iThis) = @_;
    my $str = "";
    foreach my $c ( @{$self->{qdots}} ) {
        $str .= $self->{IC}->{$iThis}->{$c}." ";
    }
    return $str;
}

#====================================================================
# SUBROUTINE:   getDialString
# DESCRIPTION:
#   Get approximate secretion/absorption multipliers. These values are
#   calculated here so that the solver is only used for integrations.
#   $dial1 = T4 secretion multiplier
#     Multiplies the 'SR4' equation as a 0-1 value. Default is 1.
#   $dial2 = T4 absorption multiplier
#     Multiplies the 'k4excrete' parameter to make the following true:
#       k4absorb/(k4absorb+k4excrete) = absorb%
#       absorb% is between 0-2 and default is 0.88
#   $dial3 = T3 secretion multiplier
#     Multiplies the 'SR3' equation as a 0-1 value. Default is 1.
#   $dial4 = T3 absorption multiplier
#     Multiplies the 'k3excrete' parameter to make the following true:
#       k3absorb/(k3absorb+k3excrete) = absorb%
#       absorb% is between 0-2 and default is 0.88
# NOTES: $dialx here corresponds to the same variable name in the solver.
#====================================================================
sub getDialString {
    my ($self) = @_;

    # Dial values are saved as percentages. Convert to decimal.
    my $dial1 = $self->getLvl2('dial',1) / 100;
    my $dial2 = $self->getLvl2('dial',2) / 100;
    my $dial3 = $self->getLvl2('dial',3) / 100;
    my $dial4 = $self->getLvl2('dial',4) / 100;

    # Calculate absorption multipliers
    my $p11 = $self->{params}->{p11}; # k4absorb
    my $p44 = $self->{params}->{p44}; # k4excrete
    my $p28 = $self->{params}->{p28}; # k3absorb
    my $p46 = $self->{params}->{p46}; # k3excrete

    my $T4absorb;
    my $T3absorb;

    if ($dial2 == 0) {
        $T4absorb = 0;
    } else {
        $T4absorb = (($p11*(1-$dial2))/$dial2)/$p44;
    }

    if ($dial4 == 0) {
        $T3absorb = 0;
    } else {
        $T3absorb = (($p28*(1-$dial4))/$dial4)/$p46;
    }

    return "$dial1 $T4absorb $dial3 $T3absorb";
}

#====================================================================
# SUBROUTINE:   getInfValue
# DESCRIPTION:
#   Get infusion (u1 and u4) values.
#   1. Loop through all infusion inputs
#   2. See which one(s) fall between $trueStart
#   3. Sum infusion values for the respective hormone
# NOTES: u1 is T4; u4 is T3
#====================================================================
sub getInfValue {
    my ($self,$iThis) = @_;

    my $trueStart = $self->getIntStart('trueStep',$iThis);

    my ($u1,$u4) = (0,0); # Initialize u1 and u4

    # Loop through all inputs
    my $inputs = $self->{input}; # Shorthand
    foreach my $inputNum (keys %$inputs) {

        # Initialized inputTime->0 is an empty hashRef
        next if (!$self->{input}->{$inputNum});

        # Skip non-infusion inputs
        next if ($self->getLvl3('input',$inputNum,'type') != 3);

        my $start = $self->getLvl3('input',$inputNum,'start');
        my $end   = $self->getLvl3('input',$inputNum,'end');

        # Sum infusion dose only if $trueStart is within the infusion interval
        if ($trueStart >= $start && $trueStart < $end) {
            my $_u1 = $self->getLvl3('infusion',$inputNum,'u1') // 0;
            my $_u4 = $self->getLvl3('infusion',$inputNum,'u4') // 0;
            $u1 += $_u1;
            $u4 += $_u4;
        }
    }

    return "$u1 $u4";
}

#====================================================================
# SUBROUTINE:   getLvl1
# DESCRIPTION:
#   Retrieve a value 1 level after $self.
# USES:
#   simTime: total simulation time
#     $self->{simTime} = $value
#====================================================================
sub getLvl1 {
    return $_[0]->{$_[1]};
}

#====================================================================
# SUBROUTINE:   getLvl2
# DESCRIPTION:
#   Retrieve a value 2 levels after $self.
# USES:
#   show: checks whether $hormone is to be sent to the browser.
#     $self->{show}->{$hormone} = $value
#   dial:
#     $self->{dial}->{$dialNum} = $value
#   toMols:
#     $self->{toMols}->{$hormone} = $value
#====================================================================
sub getLvl2 {
    return $_[0]->{$_[1]}->{$_[2]};
}

#====================================================================
# SUBROUTINE:   getLvl3
# DESCRIPTION:
#   Retrieve a value 3 levels after $self.
# USES:
#   data-$name-values: returns an arrayRef of all values for a hormone $name.
#     $self->{data}->{$name}->{values} = $arrayRef
#   input: returns $value of an input parameter $name given $inputNum.
#     $self->{input}->{$inputNum}->{$name} = $value
#   infusion: returns infusion $value for u1 or u4.
#     $self->{infusion}->{$inputNum}->{$uX} = $value
#====================================================================
sub getLvl3 {
    return $_[0]->{$_[1]}->{$_[2]}->{$_[3]};
}

#====================================================================
# SUBROUTINE:   toHour
# DESCRIPTION:
#   Multiply a number by 24.
#====================================================================
sub toHour {
    return $_[1]*24;
}

#====================================================================
# SUBROUTINE:   hasICKey
# DESCRIPTION:
#   Checks whether an initial condition key exists.
#====================================================================
sub hasICKey {
    my ($self,$ickey) = @_;
    my $thysim = $self->getThysim();
    return $self->{ICKey}->{$thysim}->{$ickey} ? 1 : 0;
}

#====================================================================
# SUBROUTINE:   recalcIC
# DESCRIPTION:
#   Checks whether to recalculate initial conditions.
#====================================================================
sub recalcIC {
    my ($self) = @_;
    return $self->{recalcIC} ? 1 : 0;
}

#====================================================================
# SUBROUTINE:   getFormParams
# DESCRIPTION:
#   Helper function that returns form parameters in hashRef.
#====================================================================
sub getFormParams {
    my ($self,$data) = @_;
    my $form = {};
    if ($data) {
        my @vars = split(/&/,$data);
        foreach my $var (@vars) {
            my ($key,$val) = split(/=/,$var);
            $form->{$key} = $val;
        }
    }
    return $form;
}

#====================================================================
# SUBROUTINE:   getExperiment
# DESCRIPTION:
#   Get a predefined experiment.
#
#   Creates a string that looks like it came from the browser, with all the
#   items needed to run Thyrosim.
# NOTES:
#   Predefined experiments do not come with parameter strings. Therefore, if
#   detected that a predefined experiment is being run, then load the parameters
#   associated with $thysim.
#====================================================================
sub getExperiment {
    my ($self,$exp) = @_;
    my $thysim = $self->getThysim();

# The default example
return 'dialinput1=100&dialinput2=88&dialinput3=100&dialinput4=88'
     . '&simtime=5'
     . '&thysim='.$thysim
     . '' if $exp eq "experiment-default";

#--------------------------------------------------
# Simple experiments. All are thysim independent.
#--------------------------------------------------

# All 3 types of input at low doses
return 'dialinput1=100&dialinput2=88&dialinput3=100&dialinput4=88'
     . '&simtime=5'
     . '&thysim='.$thysim
     . '&type-1=1&hormone-1=4&disabled-1=0&dose-1=1'
     .  '&int-1=1&start-1=1&end-1=2'
     . '&type-2=2&hormone-2=4&disabled-2=0&dose-2=2&start-2=2'
     . '&type-3=3&hormone-3=4&disabled-3=0&dose-3=3&start-3=3'
     .  '&end-3=4'
     . '&type-4=1&hormone-4=4&disabled-4=0&dose-4=4'
     .  '&singledose-4=1&start-4=4'
     . '' if $exp eq "experiment-simple-1";

# Oral 400 mg T4, repeating daily from day 1 to 5
return 'dialinput1=100&dialinput2=88&dialinput3=100&dialinput4=88'
     . '&simtime=5'
     . '&thysim='.$thysim
     . '&hormone-1=4&type-1=1&disabled-1=0&dose-1=400&int-1=1'
     .  '&start-1=1&end-1=5'
     . '' if $exp eq "experiment-simple-2";

# Oral single dose 400 mg T4 on day 1
return 'dialinput1=100&dialinput2=88&dialinput3=100&dialinput4=88'
     . '&simtime=3'
     . '&thysim='.$thysim
     . '&hormone-1=4&type-1=1&disabled-1=0&dose-1=400'
     .  '&singledose-1=1&start-1=1'
     . '' if $exp eq "experiment-simple-3";

# No inputs
return 'dialinput1=100&dialinput2=88&dialinput3=100&dialinput4=88'
     . '&simtime=10'
     . '&thysim='.$thysim
     . '' if $exp eq "experiment-simple-4";

# 2 400 mg infusion inputs, day 1 to 4 and day 2 to 6
return 'dialinput1=100&dialinput2=88&dialinput3=100&dialinput4=88'
     . '&simtime=5'
     . '&thysim='.$thysim
     . '&hormone-1=4&type-1=3&disabled-1=0&dose-1=400'
     .  '&start-1=1&end-1=4'
     . '&hormone-2=4&type-2=3&disabled-2=0&dose-2=400'
     .  '&start-2=2&end-2=6'
     . '' if $exp eq "experiment-simple-5";

#--------------------------------------------------
# DiStefano-Jonklaas-2019 experiments
#--------------------------------------------------

# Figure 1
return 'dialinput1=25&dialinput2=88&dialinput3=25&dialinput4=88'
     . '&simtime=30&recalcIC=1'
     . '&hormone-1=4&type-1=1&disabled-1=0&dose-1=123&int-1=1'
     .  '&start-1=1&end-1=30'
     . '&hormone-2=3&type-2=1&disabled-2=0&dose-2=6.5&int-2=1'
     .  '&start-2=1&end-2=30'
     . '' if $exp eq "experiment-DiJo19-1";
}

#====================================================================
# SUBROUTINE:   printCompResults
# DESCRIPTION:
#   Given a $file and an array of compartments, print as follows:
#   c1  c2  c3  c4  etc.
# NOTES:
#   1. Only works for compartments set to show.
#   2. It is a good idea to set $cs[0] as t.
#====================================================================
sub printCompResults {
    my ($self,$file,@cs) = @_;

    open my $fh, '>', $file;

    # Print headers
    say $fh join("\t",@cs);

    # Print data
    my $obj = $self->{browserObj};
    for (my $i=0; $i<=$#{$obj->{data}->{t}->{values}}; $i++) {
        my @row;
        foreach my $c (@cs) {
            my $v = $obj->{data}->{$c}->{values}->[$i];
            push(@row,$v);
        }
        say $fh join("\t",@row);
    }

    close $fh;
}

#====================================================================
# SUBROUTINE:   printInitialConditions
# DESCRIPTION:
#   Print initial conditions to $file.
# NOTES:
#   The last ICs are also the end values of the run. If t is long enough and
#   divisible by 24 hours, then these are the SS values.
#====================================================================
sub printInitialConditions {
    my ($self,$file) = @_;

    open my $fh, '>', $file;

    # Iterate over all i runs and all compartments
    foreach my $i (sort {$a <=> $b} keys %{$self->{IC}}) {
        say $fh "Current iteration: $i";
        foreach my $q (sort {$a <=> $b} keys %{$self->{IC}->{$i}}) {
            say $fh "    Comp $q:\t".$self->{IC}->{$i}->{$q};
        }
    }

    close $fh;
}

#====================================================================
# SUBROUTINE:   printToLog
# DESCRIPTION:
#   Dump array of objects to $file.
#====================================================================
sub printToLog {
    my ($self,$file,@objs) = @_;
    open my $fh, '>', $file;
    foreach my $obj (@objs) {
        say $fh Dumper($obj);
    }
    close $fh;
}

#====================================================================
# SUBROUTINE:   getSolver
# DESCRIPTION:
#   Get the base command line argument for the solver. Currently, the acceptable
#   solver is Java only.
#====================================================================
sub getSolver {
    my ($self) = @_;

    my $docRoot = $self->{docRoot};
    my $fRoot   = $self->{fRoot};

    return "java -cp .:$docRoot/$fRoot/java/commons-math3-3.6.1.jar:"
         . "$docRoot/$fRoot/java/ "
         . "edu.ucla.distefanolab.thyrosim.algorithm.Thyrosim";
}

#====================================================================
# SUBROUTINE:   getThysim
# DESCRIPTION:
#   Getter for $self->{thysim}.
#====================================================================
sub getThysim {
    return $_[0]->{thysim};
}

#====================================================================
# SUBROUTINE:   getCompIdx
# DESCRIPTION:
#   Given a compartment name, return it's array index. See:
#   $self->{compartment}->{$name} = $idx
#====================================================================
sub getCompIdx {
    return $_[0]->{compartment}->{$_[1]};
}

#====================================================================
# SUBROUTINE:   getParams
# DESCRIPTION:
#   Get parameter values and format for use on the command line.
#====================================================================
sub getParams {
    my ($self) = @_;
    my $str = "";
    foreach my $p (@{$self->sortParams()}) {
        $str .= $self->{params}->{$p}." ";
    }
    return $str;
}

#====================================================================
# SUBROUTINE:   sortParams
# DESCRIPTION:
#   Return arrayRef of parameter keys sorted alphanumerically:
#   * kdelay
#   * p1 - p48
#====================================================================
sub sortParams {
    my ($self) = @_;
    my @params = keys %{$self->{params}};
    my @sorted = map  { $_->[1] }
                 sort { $a->[0] <=> $b->[0] }
                 map  { [ ($_ =~ /(\d+)/)[0] || 0, $_ ] }
                 @params;
    return \@sorted;
}

#====================================================================
# SUBROUTINE:
# DESCRIPTION:
#====================================================================
sub genericFunction {
}

1;
