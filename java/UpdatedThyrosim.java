package com;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.Properties;

import org.apache.commons.math3.ode.FirstOrderDifferentialEquations;
import org.apache.commons.math3.ode.FirstOrderIntegrator;
import org.apache.commons.math3.ode.nonstiff.DormandPrince853Integrator;
import org.apache.commons.math3.ode.sampling.StepHandler;
import org.apache.commons.math3.ode.sampling.StepInterpolator;

public class Thyrosim implements FirstOrderDifferentialEquations
{

    private double p1,  p2,  p3,  p4,  p5,  p6,  p7,  p8,  p9,  p10;
    private double p11, p12, p13, p14, p15, p16, p17, p18, p19, p20;
    private double p21, p22, p23, p24, p25, p26, p27, p28, p29, p30;
    private double p31, p32, p33, p34, p35, p36, p37, p38, p39, p40;
    public double p41, p42, p43, p44, p45, p46, p47, p48;
    private double kdelay, u1, u4, d1, d2, d3, d4;

    public Plotter t4_plotter, t3_plotter, tsh_plotter, ft4_plotter, ft3_plotter;

    // Functions that Java ODE solver needs
    // Declare parameters
    public Thyrosim(double dial1, double dial2, double dial3, double dial4,
                    double inf1,  double inf4,
                    double _kdelay,
                    double _p1,  double _p2,  double _p3,  double _p4,
                    double _p5,  double _p6,  double _p7,  double _p8,
                    double _p9,  double _p10, double _p11, double _p12,
                    double _p13, double _p14, double _p15, double _p16,
                    double _p17, double _p18, double _p19, double _p20,
                    double _p21, double _p22, double _p23, double _p24,
                    double _p25, double _p26, double _p27, double _p28,
                    double _p29, double _p30, double _p31, double _p32,
                    double _p33, double _p34, double _p35, double _p36,
                    double _p37, double _p38, double _p39, double _p40,
                    double _p41, double _p42, double _p43, double _p44,
                    double _p45, double _p46, double _p47, double _p48)
    {
        u1 = inf1;  // Infusion into plasma T4
        u4 = inf4;  // Infusion into plasma T3
        d1 = dial1; // Dial values
        d2 = dial2;
        d3 = dial3;
        d4 = dial4;

        kdelay = _kdelay;
        p1     = _p1;
        p2     = _p2;
        p3     = _p3;
        p4     = _p4;
        p5     = _p5;
        p6     = _p6;
        p7     = _p7;
        p8     = _p8;
        p9     = _p9;
        p10    = _p10;
        p11    = _p11;
        p12    = _p12;
        p13    = _p13;
        p14    = _p14;
        p15    = _p15;
        p16    = _p16;
        p17    = _p17;
        p18    = _p18;
        p19    = _p19;
        p20    = _p20;
        p21    = _p21;
        p22    = _p22;
        p23    = _p23;
        p24    = _p24;
        p25    = _p25;
        p26    = _p26;
        p27    = _p27;
        p28    = _p28;
        p29    = _p29;
        p30    = _p30;
        p31    = _p31;
        p32    = _p32;
        p33    = _p33;
        p34    = _p34;
        p35    = _p35;
        p36    = _p36;
        p37    = _p37;
        p38    = _p38;
        p39    = _p39;
        p40    = _p40;
        p41    = _p41;
        p42    = _p42;
        p43    = _p43;
        p44    = _p44;
        p45    = _p45;
        p46    = _p46;
        p47    = _p47;
        p48    = _p48;

        // Post param load modification
        p44 = p44 * d2;
        p46 = p46 * d4;

        t4_plotter = new Plotter("T4", "days", "micrograms/L");
        t3_plotter = new Plotter("T3", "days", "micrograms/L");
        tsh_plotter = new Plotter("TSH", "days", "milliunits/L");
        ft4_plotter = new Plotter("FT4", "days", "nanograms/L");
        ft3_plotter = new Plotter("FT3", "days", "nanograms/L");

    }

    public int getDimension()
    {
        return 19;
    }

    public void computeDerivatives(double t, double[] q, double[] qDot)
    {
        
double q4F, q1F, SR3, SR4, fCIRC, SRTSH, fdegTSH, fLAG, f4, NL;

// scale compartment sizes. in thyrosimIM compartment sizes were all 1. why?
double p69 = 1; // PV_ratio scalar
double p74 = 1; // slow_scale scalar
double p75 = 1; // fast_scale scalar

double recScalar69 = 1 / p69;
double recScalar74 = 1 / p74;
double recScalar75 = 1 / p75;

double q1 = q[0] * recScalar69;   //   scale t4 by 1/PV ratio
double q2 = q[1] * recScalar75;   //   scale t4fast pool by 1/fast scale
double q3 = q[2] * recScalar74;   //   scale t4slow pool by 1/slow scale
double q4 = q[3] * recScalar69;   //   scale t3 plasma by 1/PV ratio
double q5 = q[4] * recScalar75;   //   scale t3fast pool by 1/fast scale
double q6 = q[5] * recScalar74;   //   scale t3slow pool by 1/slow scale
double q7 = q[6] * recScalar69;   //   scale TSH plasma by 1/PV ratio

// VARIABLES VINH INSERTING DURING CONVERSION PROCESS
// may already exist in code somewhere, must ask later
double p49 = 3.001011022378; //  K_circ        umol
double p50 = 3.094711690204; // K_srTSH       umol
double p51 = 5.674773816316; // n_hillcirc    scalar (hill exponent)
double p52 = 6.290803221796; // m_hillcirc    scalar (hill exponent)
double p53 = 8.498343729591; // K_f4          umol
double p54 = 14.36664496926; // l_hillf3      scalar (hill exponent)

// Auxillary equations
// speed up due to repetition
double q1Squared = Math.pow(q1, 2);
double q1Cubed = Math.pow(q1, 3);
double T3Blagtonhilleire = Math.pow(q[8], p51);
double KSR_tshmhillTSH = Math.pow(p50, p52);
double TwoT3B11 = Math.pow(q[7], 11);
double Kf4lhillf3 = Math.pow(p53, p54);

q4F = (p24 + p25 * q1 + p26 * q1Squared + p27 * q1Cubed) * q4; // FT3p
q1F = (p7 + p8 * q1 + p9 * q1Squared + p10 * q1Cubed) * q1; // FT4p
SR3 = (p19 * q[18]) * d3; // Brain delay
SR4 = (p1 * q[18]) * d1; // Brain delay
fCIRC = T3Blagtonhilleire / ((T3Blagtonhilleire + Math.pow(p49, p51)));
SRTSH = (p30 + p31 * fCIRC * Math.sin(2 * Math.PI * t - p33)) * (KSR_tshmhillTSH / (KSR_tshmhillTSH + Math.pow(q[8], p52)));
// System.out.println(p31);
fdegTSH = p34 + p35/(p36 + q7);
fLAG = p41 + 2 * TwoT3B11/(Math.pow(p42,11) + TwoT3B11);
f4 = p37 * (1 + 5 * (Kf4lhillf3) / (Kf4lhillf3 + Math.pow(q[7], p54)));
NL = p13/(p14+q2);

// ODEs
//double plasma_volume_ratio = 1; // PV_ratio scalar
//double slow_volume_ratio = 1; // slow_scale scalar
//double fast_volume_ratio = 1; // fast_scale scalar
double p57 = d1; //dial[1]
double p58 = d2; 
double p59 = d3;
double p60 = d4;
//  p[57] = dial[1] # controls T4 secretion rate
//  p[58] = dial[2] # controls T4 absorption rate
//  p[59] = dial[3] # controls T3 secretion rate
//  p[60] = dial[4] # controls T3 absorption rate
double p61 = 5.003761571969437;
double p62 = 0.11122955089297369;
double p63 = 0.4;
double p64 = 0.1;
//  # variance parameters for T4/T3/TSH and schneider error (these are used only for parameter estimation!)
//         p[61] = 5.003761571969437   # σ for T4 in Blakesley (fixed to reasonable value before fitting)
//         p[62] = 0.11122955089297369 # σ for T3 Blakesley and Jonklaas (fixed to reasonable value before fitting)
//         p[63] = 0.4                 # σ for TSH in Blakesley and Jonklaas (fixed to reasonable value before fitting)
//         p[64] = 0.1                 # σ for FT4 in Jonklaas (fixed to reasonable value before fitting)
double p65 = 21.82854404275587;
double p66 = 22.99050845201536;
//     # Blakesley reference BMI
//         p[65] = 21.82854404275587 # (male, fitted)
//         p[66] = 22.99050845201536 # w / h^2 (female, fitted)

double p67 = 1.0;

//  # Vtsh scaling factor
//     p[67] = 1.0

//     # Volume scaling ratio
//     p[69] = 1.0 # Plasma volume ratio

//   # ref height for male and female
//     p[78] = 1.7608716659237555 # (fitted)
//     p[79] = 1.6696106891941103 # (fitted)
double p78 = 1.7608716659237555;
double p79 = 1.6696106891941103;

// # clearance scale (male / female)
//     p[80] = 1.0499391485135692 # male clearance (fitted)
double p80 = 1.0499391485135692;

// # Initialize infusion parameters
// p[81] = 0.0 # T4 infusion
// p[82] = 0.0 # T3 infusion
double p81 = 0.0;
double p82 = 0.0;

// double p59 = d3; //dial[3]
// missing p[80] as this was removed (for thyroSOLVER) (p[80] = ivT4 dose)
qDot[0] = p81 + (SR4 + p3 * q2 + p4 * q3 - (p5 + p6) * q1F) * p69 + p11 * q[10];  // T4dot (need to remove u1) unmod
qDot[1] = (p6 * q1F - (p3 + p12 + NL) * q2) * p75;  // T4fast   unmod                           // T4fast
qDot[2] = (p5 * q1F - (p4 + p15 / (p16 + q3) + p17 / (p18 + q3)) * q3) * p74;  // T4slow  unmod
// missing p[81] as this was removed for thyroSOLVER (p[81] = ivT3 dose)
qDot[3] = p82 + (SR3 + p20 * q5 + p21 * q6 - (p22 + p23) * q4F) * p69 + p28 * q[12];  // T3pdot unmod
qDot[4] = (p23 * q4F + NL * q2 - (p20 + p29) * q5) * p75;  // T3fast  unmod
qDot[5] = (p22 * q4F + p15 * q3 / (p16 + q3) + p17 * q3 / (p18 + q3) - (p21) * q6) * p74;  // T3slow    unmod
qDot[6] = (SRTSH - fdegTSH * q7) * p69;  // TSHp    unmod          
qDot[7] = f4 / p38 * q1 + p37 / p39 * q4 - p40 * q[7];  // T3B    unmod
qDot[8] = fLAG * (q[7] - q[8]);  // T3B LAG   unmod
double p43ofq9 = p43 * q[9];
double p45qof11 = p45 * q[11];
qDot[9] = -p43ofq9;  // T4PILLdot    unmod
qDot[10]=  p43ofq9 - (p44 * d2 + p11) * q[10];  // T4GUTdot: note p[43] * p[57] = p[43] * dial[1] = k4excrete   unmod
qDot[11]= -p45qof11;  // T3PILLdot  unmod
qDot[12]= (p45qof11 - (p46 * d4 + p28) * q[12]); //T3GUTdot: note p[45] * p[59] = p[45] * dial[3] = k3excrete  unmod

// Delay ODEs
qDot[13] = (q7) - kdelay * q[13];                              // delay1
qDot[14] = kdelay*(q[13] - q[14]);                                  // delay2
qDot[15] = kdelay*(q[14] - q[15]);                                  // delay3
qDot[16] = kdelay*(q[15] - q[16]);                                  // delay4
qDot[17] = kdelay*(q[16] - q[17]);                                  // delay5
qDot[18] = kdelay*(q[17] - q[18]);                                  // delay6


// double q4F, q1F, SR3, SR4, fCIRC, SRTSH, fdegTSH, fLAG, f4, NL;

// // Auxillary equations
// q1F = (p7 +p8 *q[0]+p9 *Math.pow(q[0],2)+p10*Math.pow(q[0],3))*q[0]; // FT4p
// q4F = (p24+p25*q[0]+p26*Math.pow(q[0],2)+p27*Math.pow(q[0],3))*q[3]; // FT3p
// SR3 = (p19*q[18])*d3; // Brain delay
// SR4 = (p1 *q[18])*d1; // Brain delay
// fCIRC = 1+(p32/(p31*Math.exp(-q[8]))-1)*(1/(1+Math.exp(10*q[8]-55)));
// SRTSH = (p30+p31*fCIRC*Math.sin(Math.PI/12*t-p33))*Math.exp(-q[8]);
// fdegTSH = p34+p35/(p36+q[6]);
// fLAG = p41+2*Math.pow(q[7],11)/(Math.pow(p42,11)+Math.pow(q[7],11));
// f4 = p37+5*p37/(1+Math.exp(2*q[7]-7));
// NL = p13/(p14+q[1]);

// // ODEs
// qDot[0] = SR4+p3*q[1]+p4*q[2]-(p5+p6)*q1F+p11*q[10]+u1;            // T4dot
// qDot[1] = p6*q1F-(p3+p12+NL)*q[1];                                 // T4fast
// qDot[2] = p5*q1F-(p4+p15/(p16+q[2])+p17/(p18+q[2]))*q[2];          // T4slow
// qDot[3] = SR3+p20*q[4]+p21*q[5]-(p22+p23)*q4F+p28*q[12]+u4;        // T3pdot
// qDot[4] = p23*q4F+NL*q[1]-(p20+p29)*q[4];                          // T3fast
// qDot[5] = p22*q4F+p15*q[2]/(p16+q[2])+p17*q[2]/(p18+q[2])-p21*q[5];// T3slow
// qDot[6] = SRTSH-fdegTSH*q[6];                                      // TSHp
// qDot[7] = f4/p38*q[0]+p37/p39*q[3]-p40*q[7];                       // T3B
// qDot[8] = fLAG*(q[7]-q[8]);                                        // T3B LAG
// qDot[9] = -p43*q[9];                                               // T4PILLdot
// qDot[10]=  p43*q[9]-(p44+p11)*q[10];                               // T4GUTdot
// qDot[11]= -p45*q[11];                                              // T3PILLdot
// qDot[12]=  p45*q[11]-(p46+p28)*q[12];                              // T3GUTdot

// // Delay ODEs
// qDot[13] = -kdelay*q[13] +q[6];                                    // delay1
// qDot[14] = kdelay*(q[13] -q[14]);                                  // delay2
// qDot[15] = kdelay*(q[14] -q[15]);                                  // delay3
// qDot[16] = kdelay*(q[15] -q[16]);                                  // delay4
// qDot[17] = kdelay*(q[16] -q[17]);                                  // delay5
// qDot[18] = kdelay*(q[17] -q[18]);                                  // delay6

    }

    public static void personalize(boolean sex, double height, double BW){
        // sex: true = male, false = female

        // 1 - Compute Ideal Sex & Height Dependent Body Weight, iBW
        double iBW, delta_iBW, HEM, Vb, Vp, Vp_new, Vpref, Vtsh_new, k05_new;
        if(sex){
            iBW = 176.3 - 220.6 * height + 93.5 * Math.pow(height, 2);
            HEM = 0.45;
        }
        else{
            iBW = 145.8 - 182.7 * height + 79.55 * Math.pow(height, 2);
            HEM = 0.4;
        }
        
        // 2 - Compute Patient-Specific % Deviation from iBWg , ∆iBW
        delta_iBW = 100 * (BW - iBW) / iBW;
        
        // 3 - Compute Patient-Specific Blood Volume, Vb
        double a = 1.27;
        double n = 0.373;
        double Vb_per_kg;
        // Vb = a*Math.pow(100+delta_iBW, n-1)*BW;
        if(sex){  // male
                Vb_per_kg = 71.96 * Math.exp(-0.007516 * delta_iBW);
            } else {  // female
                Vb_per_kg = 43.65 + 20.79 * Math.exp(-0.01545 * delta_iBW) 
                            + 2.043 * Math.exp(-0.08392 * delta_iBW);
            }
    
        // Compute total blood volume in liters
        Vb = Vb_per_kg * BW / 1000;
        // 4 - Compute Patient-Specific Blood Plasma Volume, Vp
        Vp = Vb * (1 - HEM);

        // 5 - Rescale VP (i.e., Compute VP,new)
        // BW = BMI * H^2
        // BW_Mref = 21.8 * (1.76)^2 = 67.52768
        // BW_Fref = 23 * (1.67)^2 = 64.1447
        double BW_Mref = 67.52768, BW_Fref = 64.1447;
        //      Male
        // iBW = 176.3 - 220.6(1.76) + 93.5(1.76)^2 == 77.6696
        // delta_iBW = 100 * (BW_Mref - iBW) / iBW = -13.0577729253
        // Vb = 1.27(100 + delta_iBW)^(0.373-1) * BW_Mref = 5.21660391812
        // Vm_pref = Vb(1-0.45) = 2.86913215497

        //      Female
        // iBW = 145.8 - 182.7(1.67) + 79.55(1.67^2) = 62.547995
        // delta_iBW = 100 * (BW_Fref - iBW) / iBW = 2.55276767864
        // Vb = 1.27(100 + delta_iBW)^(0.373-1) * BW_Fref = 4.46786959281
        // Vf_pref = Vb(1 - 0.4) = 2.68072175569

        // Vpref = (Vm_pref + Vf_pref) / 2

        Vpref = 2.77492695533;

        // waiting on Karim to point us to reference BWs
        Vp_new = (3.2*Vp)/Vpref;
        
        // 6 - Compute Patient-Specific TSH Distribution Volume, Vtsh
        Vtsh_new = 5.2 + (Vp_new - 3.2);

        // 7 - Compute Patient-Specific T3 Clearance Rate, k05_new
        double Cm = 1.05, k05 = 0.185;
        if(sex){
            k05_new = Cm * k05 * Math.pow((BW / BW_Mref), 0.75);
        }
        else{
            k05_new = k05 * Math.pow(BW / BW_Fref, 0.75);
        }

        // prints the 3 values
        double[] newVals = new double[] {Vp_new, Vtsh_new, k05_new};
        System.out.println(Arrays.toString(newVals));
    }

    public void plot_all(){
        t4_plotter.plot();
        t3_plotter.plot();
        tsh_plotter.plot();
        ft4_plotter.plot();
        ft3_plotter.plot();
    }

    public static void main(String[] args)
    {
        // Parse input arguments
        double IC1    = Double.parseDouble(args[0]);
        double IC2    = Double.parseDouble(args[1]);
        double IC3    = Double.parseDouble(args[2]);
        double IC4    = Double.parseDouble(args[3]);
        double IC5    = Double.parseDouble(args[4]);
        double IC6    = Double.parseDouble(args[5]);
        double IC7    = Double.parseDouble(args[6]);
        double IC8    = Double.parseDouble(args[7]);
        double IC9    = Double.parseDouble(args[8]);
        double IC10   = Double.parseDouble(args[9]);
        double IC11   = Double.parseDouble(args[10]);
        double IC12   = Double.parseDouble(args[11]);
        double IC13   = Double.parseDouble(args[12]);
        double IC14   = Double.parseDouble(args[13]);
        double IC15   = Double.parseDouble(args[14]);
        double IC16   = Double.parseDouble(args[15]);
        double IC17   = Double.parseDouble(args[16]);
        double IC18   = Double.parseDouble(args[17]);
        double IC19   = Double.parseDouble(args[18]);
        double t1d    = Double.parseDouble(args[19]);
        double t2d    = Double.parseDouble(args[20]);
        double dial1  = Double.parseDouble(args[21]);
        double dial2  = Double.parseDouble(args[22]);
        double dial3  = Double.parseDouble(args[23]);
        double dial4  = Double.parseDouble(args[24]);
        double inf1   = Double.parseDouble(args[25]);
        double inf4   = Double.parseDouble(args[26]);
        String thysim = String.valueOf(args[27]);
        final String initic = String.valueOf(args[28]);
        double _kdelay = Double.parseDouble(args[29]);
        double _p1     = Double.parseDouble(args[30]);
        double _p2     = Double.parseDouble(args[31]);
        double _p3     = Double.parseDouble(args[32]);
        double _p4     = Double.parseDouble(args[33]);
        double _p5     = Double.parseDouble(args[34]);
        double _p6     = Double.parseDouble(args[35]);
        double _p7     = Double.parseDouble(args[36]);
        double _p8     = Double.parseDouble(args[37]);
        double _p9     = Double.parseDouble(args[38]);
        double _p10    = Double.parseDouble(args[39]);
        double _p11    = Double.parseDouble(args[40]);
        double _p12    = Double.parseDouble(args[41]);
        double _p13    = Double.parseDouble(args[42]);
        double _p14    = Double.parseDouble(args[43]);
        double _p15    = Double.parseDouble(args[44]);
        double _p16    = Double.parseDouble(args[45]);
        double _p17    = Double.parseDouble(args[46]);
        double _p18    = Double.parseDouble(args[47]);
        double _p19    = Double.parseDouble(args[48]);
        double _p20    = Double.parseDouble(args[49]);
        double _p21    = Double.parseDouble(args[50]);
        double _p22    = Double.parseDouble(args[51]);
        double _p23    = Double.parseDouble(args[52]);
        double _p24    = Double.parseDouble(args[53]);
        double _p25    = Double.parseDouble(args[54]);
        double _p26    = Double.parseDouble(args[55]);
        double _p27    = Double.parseDouble(args[56]);
        double _p28    = Double.parseDouble(args[57]);
        double _p29    = Double.parseDouble(args[58]);
        double _p30    = Double.parseDouble(args[59]);
        double _p31    = Double.parseDouble(args[60]);
        double _p32    = Double.parseDouble(args[61]);
        double _p33    = Double.parseDouble(args[62]);
        double _p34    = Double.parseDouble(args[63]);
        double _p35    = Double.parseDouble(args[64]);
        double _p36    = Double.parseDouble(args[65]);
        double _p37    = Double.parseDouble(args[66]);
        double _p38    = Double.parseDouble(args[67]);
        double _p39    = Double.parseDouble(args[68]);
        double _p40    = Double.parseDouble(args[69]);
        double _p41    = Double.parseDouble(args[70]);
        double _p42    = Double.parseDouble(args[71]);
        double _p43    = Double.parseDouble(args[72]);
        double _p44    = Double.parseDouble(args[73]);
        double _p45    = Double.parseDouble(args[74]);
        double _p46    = Double.parseDouble(args[75]);
        double _p47    = Double.parseDouble(args[76]);
        double _p48    = Double.parseDouble(args[77]);

        // Get ODEs and parameters
        Thyrosim ode = new Thyrosim(dial1, dial2, dial3, dial4, inf1, inf4,
                                    _kdelay,
                                    _p1,  _p2,  _p3,  _p4,  _p5,  _p6,  _p7,
                                    _p8,  _p9,  _p10, _p11, _p12, _p13, _p14,
                                    _p15, _p16, _p17, _p18, _p19, _p20, _p21,
                                    _p22, _p23, _p24, _p25, _p26, _p27, _p28,
                                    _p29, _p30, _p31, _p32, _p33, _p34, _p35,
                                    _p36, _p37, _p38, _p39, _p40, _p41, _p42,
                                    _p43, _p44, _p45, _p46, _p47, _p48);
        int t1 = (int)Math.round(t1d);
        int t2 = (int)Math.round(t2d);
        double[] q = new double[] {IC1, IC2, IC3, IC4, IC5, IC6,
                                   IC7, IC8, IC9, IC10,IC11,IC12,
                                   IC13,IC14,IC15,IC16,IC17,IC18,IC19};

        // Initialize a StepHandler for continuous output. If initic is enabled,
        // then only print the end values. Otherwise, print all values.
        final double[] p = new double[] { _p7,  _p8,  _p9,  _p10,
                                          _p24, _p25, _p26, _p27 };
        StepHandler stepHandler = new StepHandler()
        {
            public void init(double t0, double[] y0, double t)
            {
            }

            public void handleStep(StepInterpolator interpolator, boolean isLast)
            {
                double   t = interpolator.getCurrentTime();
                double[] y = interpolator.getInterpolatedState();
                if (initic.equals("initic")) { // Print only end values
                    if (isLast) {
                        System.out.println(getLine(t,y,p));
                    }
                } else { // Print everything
                    System.out.println(getLine(t,y,p));
                }
                double y0Squared = Math.pow(y[0], 2);
                double y0Cubed = Math.pow(y[0], 3);
                ode.t4_plotter.add_value(t, y[0] * 777/_p47);
                ode.t3_plotter.add_value(t, y[3] * 651/_p47);
                ode.tsh_plotter.add_value(t, y[6] * 5.6/_p48);
                ode.ft4_plotter.add_value(t, 0.45 * (p[0]+p[1]*y[0]+p[2]*y0Squared+p[3]*y0Cubed)*y[0] * 777000/3.2);
                ode.ft3_plotter.add_value(t, 0.5 * (p[4]+p[5]*y[0]+p[6]*y0Squared+p[7]*y0Cubed)*y[3] * 651000/3.2);
            }
        };

        // Initialize an integrator with the stepHandler and integrate
        double[] o = new double[]{ 1.0e-8, 100.0, 1.0e-10, 1.0e-10 };
        FirstOrderIntegrator foi = new DormandPrince853Integrator(o[0],o[1],o[2],o[3]);
        foi.addStepHandler(stepHandler);
        foi.integrate(ode,t1,q,t2,q);

        ode.plot_all();
        // System.out.println(q.length);
        personalize(true, 1.0, 1.0);

        // There are other integrators, e.g., GraggBulirschStoerIntegrator
    }

    // Generate the output per time point. In addition, recalculate FT4 and FT3
    // values here because unfortunately can't figure out how to extract q1F and
    // q4F values directly.
    public static String getLine(double t, double[] y, double[] p)
    {
        StringBuilder sb = new StringBuilder();
        sb.append(Double.toString(t)+" ");
        for (double v : y)
        {
            sb.append(Double.toString(v)+" ");
        }
        double y0Squared = Math.pow(y[0], 2);
        double y0Cubed = Math.pow(y[0], 3);
        double ft4 = 1.1 * 0.45 * (p[0]+p[1]*y[0]+p[2]*y0Squared+p[3]*y0Cubed)*y[0];
        double ft3 = 1.05 * 0.5 * (p[4]+p[5]*y[0]+p[6]*y0Squared+p[7]*y0Cubed)*y[3];
        sb.append(Double.toString(ft4)+" ");
        sb.append(Double.toString(ft3)+" ");
        return sb.toString();
    }

    // Can alternatively read parameter values in from the config file. Not
    // currently used.
    public double[] readConfig(String thysim)
    {
        // Load properties
        Properties prop = new Properties();
        String configFile = "../config/" + thysim + ".params";
        InputStream pis = null; // Param InputStream

        try {
            pis = new FileInputStream(configFile);
        } catch (FileNotFoundException ex) {
            System.out.println("File not found: " + configFile);
        }

        try {
            prop.load(pis);
        } catch (IOException io) {
            io.printStackTrace();
        }

        double[] p = new double[] { Double.valueOf(prop.getProperty("kdelay")),
                                    Double.valueOf(prop.getProperty("p1")),
                                    Double.valueOf(prop.getProperty("p2")),
                                    Double.valueOf(prop.getProperty("p3")),
                                    Double.valueOf(prop.getProperty("p4")),
                                    Double.valueOf(prop.getProperty("p5")),
                                    Double.valueOf(prop.getProperty("p6")),
                                    Double.valueOf(prop.getProperty("p7")),
                                    Double.valueOf(prop.getProperty("p8")),
                                    Double.valueOf(prop.getProperty("p9")),
                                    Double.valueOf(prop.getProperty("p10")),
                                    Double.valueOf(prop.getProperty("p11")),
                                    Double.valueOf(prop.getProperty("p12")),
                                    Double.valueOf(prop.getProperty("p13")),
                                    Double.valueOf(prop.getProperty("p14")),
                                    Double.valueOf(prop.getProperty("p15")),
                                    Double.valueOf(prop.getProperty("p16")),
                                    Double.valueOf(prop.getProperty("p17")),
                                    Double.valueOf(prop.getProperty("p18")),
                                    Double.valueOf(prop.getProperty("p19")),
                                    Double.valueOf(prop.getProperty("p20")),
                                    Double.valueOf(prop.getProperty("p21")),
                                    Double.valueOf(prop.getProperty("p22")),
                                    Double.valueOf(prop.getProperty("p23")),
                                    Double.valueOf(prop.getProperty("p24")),
                                    Double.valueOf(prop.getProperty("p25")),
                                    Double.valueOf(prop.getProperty("p26")),
                                    Double.valueOf(prop.getProperty("p27")),
                                    Double.valueOf(prop.getProperty("p28")),
                                    Double.valueOf(prop.getProperty("p29")),
                                    Double.valueOf(prop.getProperty("p30")),
                                    Double.valueOf(prop.getProperty("p31")),
                                    Double.valueOf(prop.getProperty("p32")),
                                    Double.valueOf(prop.getProperty("p33")),
                                    Double.valueOf(prop.getProperty("p34")),
                                    Double.valueOf(prop.getProperty("p35")),
                                    Double.valueOf(prop.getProperty("p36")),
                                    Double.valueOf(prop.getProperty("p37")),
                                    Double.valueOf(prop.getProperty("p38")),
                                    Double.valueOf(prop.getProperty("p39")),
                                    Double.valueOf(prop.getProperty("p40")),
                                    Double.valueOf(prop.getProperty("p41")),
                                    Double.valueOf(prop.getProperty("p42")),
                                    Double.valueOf(prop.getProperty("p43")),
                                    Double.valueOf(prop.getProperty("p44")),
                                    Double.valueOf(prop.getProperty("p45")),
                                    Double.valueOf(prop.getProperty("p46")),
                                    Double.valueOf(prop.getProperty("p47")),
                                    Double.valueOf(prop.getProperty("p48"))};
        return p;
    }
}

