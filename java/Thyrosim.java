package edu.ucla.distefanolab.thyrosim.algorithm;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.apache.commons.math3.ode.FirstOrderDifferentialEquations;
import org.apache.commons.math3.ode.FirstOrderIntegrator;
import org.apache.commons.math3.ode.nonstiff.DormandPrince853Integrator;
import org.apache.commons.math3.ode.sampling.StepHandler;
import org.apache.commons.math3.ode.sampling.StepInterpolator;

/**
 * UpdatedThyrosim – patient-specific p-THYROSIM kernel.
 *
 * Parameters are taken directly from the Julia reference notebook
 * (Clean_Code_LT43DosingApp.ipynb). The kernel supports:
 *   - Hours mode  (simulationLength ≤ 100 days, time axis in hours)
 *   - Days  mode  (simulationLength ≤ 1000 days, time axis in days)
 * selected via the {@code mode} flag ("hours" or "days").
 *
 * Public API entry point: {@link #simulate}.
 * Public output container:  {@link SimResult}.
 */

public class Thyrosim implements FirstOrderDifferentialEquations
{

    // constants from the notebook
    private static final double MW_T4  = 777.0;
    private static final double MW_T3  = 651.0;
    private static final double TSH_CONV = 5.6;
    private static final double KDELAY = 5.0 / 8.0;

    private final double[] p;
    // Functions that Java ODE solver needs
    // Declare parameters

    // Constructor – builds the ODE object from a fully-populated parameter array
    // Parameters (index matches Julia p[1..82], stored 0-based here)
   private Thyrosim(double[] params) {
        this.p = params;
    }
    @Override
    public int getDimension()
    {
        return 19;
    }

    @Override
    public void computeDerivatives(double t, double[] q, double[] dq) {

        double plasma_volume_ratio = p(69);

        // Scale plasma compartments by 1/Vp_ratio (matches Julia q1 = q[1]/p[69])
        double q1 = q[0] / p(69);
        double q2 = q[1];
        double q3 = q[2];
        double q4 = q[3] / p(69);
        double q5 = q[4];
        double q6 = q[5];
        double q7 = q[6] / p(69);

        // Clamp negatives (matches Julia adhoc fix)
        for (int i = 0; i < q.length; i++) {
            if (q[i] < 0) q[i] = 0;
        }

        // Auxiliary equations
        double q1Sq = q1 * q1;
        double q1Cu = q1Sq * q1;
        double q4F  = (p(24) + p(25)*q1 + p(26)*q1Sq + p(27)*q1Cu) * q4; // FT3p
        double q1F  = (p(7)  + p(8) *q1 + p(9) *q1Sq + p(10)*q1Cu) * q1; // FT4p

        // Secretion rates – include dial factors p[57] (d1) and p[59] (d3)
        double SR4 = p(1) * p(57) * q[18];   // T4 secretion (brain delay, dial1)
        double SR3 = p(19) * p(59) * q[18];  // T3 secretion (brain delay, dial3)

        // Hill-function terms
        double q9p51 = Math.pow(q[8], p(51));
        double p49p51 = Math.pow(p(49), p(51));
        double fCIRC = q9p51 / (q9p51 + p49p51);

        double p50p52 = Math.pow(p(50), p(52));
        double q9p52  = Math.pow(q[8], p(52));
        // SRTSH: note Julia uses pi/12 (circadian), time t is in hours internally
        double SRTSH  = (p(30) + p(31) * fCIRC * Math.sin(Math.PI / 12.0 * t - p(33)))
                        * (p50p52 / (p50p52 + q9p52));

        double fdegTSH = p(34) + p(35) / (p(36) + q7);

        double q8p11   = Math.pow(q[7], 11);
        double p42p11  = Math.pow(p(42), 11);
        double fLAG    = p(41) + 2.0 * q8p11 / (p42p11 + q8p11);

        double p53p54  = Math.pow(p(53), p(54));
        double q8p54   = Math.pow(q[7], p(54));
        double f4      = p(37) * (1.0 + 5.0 * p53p54 / (p53p54 + q8p54));

        double NL = p(13) / (p(14) + q2);

        // ODEs (compartment indices are 0-based; Julia q[1] → java q[0])
        dq[0]  = p(81) + (SR4 + p(3)*q2 + p(4)*q3 - (p(5)+p(6))*q1F) * plasma_volume_ratio
                       + p(11) * q[10];                               // T4 plasma
        dq[1]  = p(6)*q1F - (p(3) + p(12) + NL) * q2;               // T4 fast
        dq[2]  = p(5)*q1F - (p(4) + p(15)/(p(16)+q3) + p(17)/(p(18)+q3)) * q3; // T4 slow
        dq[3]  = p(82) + (SR3 + p(20)*q5 + p(21)*q6 - (p(22)+p(23))*q4F) * plasma_volume_ratio
                       + p(28) * q[12];                               // T3 plasma
        dq[4]  = p(23)*q4F + NL*q2 - (p(20) + p(29)) * q5;          // T3 fast
        dq[5]  = p(22)*q4F + p(15)*q3/(p(16)+q3) + p(17)*q3/(p(18)+q3) - p(21)*q6; // T3 slow
        dq[6]  = (SRTSH - fdegTSH * q7) * plasma_volume_ratio;       // TSH plasma
        dq[7]  = f4/p(38)*q1 + p(37)/p(39)*q4 - p(40)*q[7];         // T3B
        dq[8]  = fLAG * (q[7] - q[8]);                               // T3B LAG
        dq[9]  = -p(43) * q[9];                                       // T4 PILL
        dq[10] = p(43)*q[9] - (p(44)*p(58) + p(11)) * q[10];        // T4 GUT
        dq[11] = -p(45) * q[11];                                      // T3 PILL
        dq[12] = p(45)*q[11] - (p(46)*p(60) + p(28)) * q[12];       // T3 GUT

        // Delay chain (6 compartments)
        dq[13] = KDELAY * (q7 - q[13]);
        dq[14] = KDELAY * (q[13] - q[14]);
        dq[15] = KDELAY * (q[14] - q[15]);
        dq[16] = KDELAY * (q[15] - q[16]);
        dq[17] = KDELAY * (q[16] - q[17]);
        dq[18] = KDELAY * (q[17] - q[18]);
    }

    // Convenience: 1-based parameter lookup to match Julia notation
    private double p(int i) { return p[i - 1]; }

  
    // Sean and Jaden 3/5/26
    public static double predictVp(double h, double w, boolean sex) {
        // Hematocrit level: 0.45 for male, 0.40 for female
        double Hem = 0.45;
        double iw;
        if (sex) { // male
            iw = 176.3 - 220.6 * h + 93.5 * Math.pow(h, 2);
            Hem = 0.45;
        } else { // female
            iw = 145.8 - 182.7 * h + 79.55 * Math.pow(h, 2);
            Hem = 0.40;
        }

        // Percent deviation from ideal weight
        double deltaIw = (w - iw) / iw * 100.0;

        double VbPerKg;
        if (sex) {
            VbPerKg = 71.96 * Math.exp(-0.007516 * deltaIw);
        } else {
            VbPerKg = 43.65 + 20.79 * Math.exp(-0.01545 * deltaIw) + 2.043 * Math.exp(-0.08392 * deltaIw);
        }

        // Compute total blood volume in liters
        double Vb = VbPerKg * w / 1000.0;

        // Return plasma volume (liters)
        return Vb * (1.0 - Hem);
    }

    private static double referenceVp(double refBMI, boolean sex, double refHeight) {
        double w = refBMI * refHeight * refHeight;
        return predictVp(refHeight, w, sex);
    }

    /**
     * Build the canonical 82-element parameter array from the notebook.
     * All values are 1-based in comments (matching Julia p[1]..p[82]).
     */
    public static double[] defaultParameters() {
        double[] p = new double[82];
        p[0]  = 0.0027785399344;   // p[1]  S4 (fitted)
        p[1]  = 8.0;               // p[2]  tau
        p[2]  = 0.868;             // p[3]  k12
        p[3]  = 0.108;             // p[4]  k13
        p[4]  = 584.0;             // p[5]  k31free
        p[5]  = 1503.0;            // p[6]  k21free
        p[6]  = 0.000289;          // p[7]  A (FT4 polynomial)
        p[7]  = 0.000214;          // p[8]  B
        p[8]  = 0.000128;          // p[9]  C
        p[9]  = -8.83e-6;          // p[10] D
        p[10] = 0.88;              // p[11] k4absorb
        p[11] = 0.0189;            // p[12] k02
        p[12] = 0.012101809339;    // p[13] VmaxD1fast (fitted)
        p[13] = 2.85;              // p[14] KmD1fast
        p[14] = 6.63e-4;           // p[15] VmaxD1slow
        p[15] = 95.0;              // p[16] KmD1slow
        p[16] = 0.00074619;        // p[17] VmaxD2slow
        p[17] = 0.075;             // p[18] KmD2slow
        p[18] = 3.3572e-4;         // p[19] S3 (fitted)
        p[19] = 5.37;              // p[20] k45
        p[20] = 0.0689;            // p[21] k46
        p[21] = 127.0;             // p[22] k64free
        p[22] = 2043.0;            // p[23] k54free
        p[23] = 0.00395;           // p[24] a (FT3 polynomial)
        p[24] = 0.00185;           // p[25] b
        p[25] = 0.00061;           // p[26] c
        p[26] = -0.000505;         // p[27] d  (notebook: -0.000505)
        p[27] = 0.88;              // p[28] k3absorb
        p[28] = 0.184972339613;    // p[29] k05 (fitted, base female value)
        p[29] = 450.0;             // p[30] Bzero
        p[30] = 219.7085301388;    // p[31] Azero (fitted)
        p[31] = 0.0;               // p[32] Amax (set to 0)
        p[32] = -3.71;             // p[33] phi
        p[33] = 0.53;              // p[34] kdegTSH-HYPO
        p[34] = 0.226;             // p[35] VmaxTSH
        p[35] = 23.0;              // p[36] K50TSH
        p[36] = 0.058786935033;    // p[37] k3 (fitted)
        p[37] = 0.29;              // p[38] T4P-EU
        p[38] = 0.006;             // p[39] T3P-EU
        p[39] = 0.037;             // p[40] KdegT3B
        p[40] = 0.0034;            // p[41] KLAG-HYPO
        p[41] = 5.0;               // p[42] KLAG
        p[42] = 1.3;               // p[43] k4dissolve
        p[43] = 0.12;              // p[44] k4excrete
        p[44] = 1.78;              // p[45] k3dissolve
        p[45] = 0.12;              // p[46] k3excrete
        p[46] = 3.2;               // p[47] Vp (reference, will be overridden)
        p[47] = 5.2;               // p[48] Vtsh (reference, will be overridden)
        // Hill function parameters
        p[48] = 3.001011022378;    // p[49] K_circ
        p[49] = 3.094711690204;    // p[50] K_SR_tsh
        p[50] = 5.674773816316;    // p[51] n (hill exponent fCIRC)
        p[51] = 6.290803221796;    // p[52] m (hill exponent SRTSH)
        p[52] = 8.498343729591;    // p[53] K_f4
        p[53] = 14.36664496926;    // p[54] l (hill exponent f4)
        // Dosing (initialised to 0)
        p[54] = 0.0;               // p[55] T4 oral dose (µmol per dose event)
        p[55] = 0.0;               // p[56] T3 oral dose (µmol per dose event)
        // Dial parameters (default = healthy euthyroid)
        p[56] = 1.0;               // p[57] dial1 – T4 secretion scale
        p[57] = 0.88;              // p[58] dial2 – T4 absorption scale
        p[58] = 1.0;               // p[59] dial3 – T3 secretion scale
        p[59] = 0.88;              // p[60] dial4 – T3 absorption scale
        // Variance parameters (for fitting only, not used in simulation)
        p[60] = 5.003761571969437;    // p[61]
        p[61] = 0.11122955089297369;  // p[62]
        p[62] = 0.4;                  // p[63]
        p[63] = 0.1;                  // p[64]
        // Reference BMI values (fitted)
        p[64] = 21.82854404275587;    // p[65] male ref BMI
        p[65] = 22.99050845201536;    // p[66] female ref BMI
        // Vtsh scaling factor
        p[66] = 1.0;                  // p[67]
        // p[68] unused
        p[67] = 0.0;
        // Plasma volume ratio (will be computed per-patient)
        p[68] = 1.0;                  // p[69]
        // p[70..77] unused placeholders
        for (int i = 69; i < 77; i++) p[i] = 0.0;
        // Reference heights (fitted)
        p[77] = 1.7608716659237555;   // p[78] male ref height (m)
        p[78] = 1.6696106891941103;   // p[79] female ref height (m)
        // Male clearance scale
        p[79] = 1.0499391485135692;   // p[80]
        // Infusion rates (IV, default 0)
        p[80] = 0.0;                  // p[81] T4 IV infusion
        p[81] = 0.0;                  // p[82] T3 IV infusion
        return p;
    }

    public static void personaliseParameters(double[] p, boolean sex, double height, double weight) {
        // Reference BMI and heights from fitted parameters
        double refBMI  = sex ? p[64] : p[65];   // p[65]/p[66]
        double refH_M  = p[77];                  // p[78]
        double refH_F  = p[78];                  // p[79]

        // Compute reference Vp (average of male/female reference)
        double refVp = (referenceVp(refBMI, true, refH_M) + referenceVp(refBMI, false, refH_F)) / 2.0;

        // Patient Vp
        double patientVp = predictVp(height, weight, sex);

        // Scaled Vp (normalised to 3.2 L reference)
        double Vp_new = patientVp * 3.2 / refVp;

        // Vtsh = 5.2 + Vtsh_scale * (Vp_new - 3.2)
        double Vtsh_new = 5.2 + p[66] * (Vp_new - 3.2);  // p[67]

        // Plasma volume ratio for ODE scaling
        double Vp_ratio = patientVp / refVp;

        // k05: scale by male clearance factor if male
        double k05_base = 0.184972339613;  // p[29] base (female)
        double k05_new  = sex ? k05_base * p[79] : k05_base;  // p[80]

        // Write back
        p[46] = Vp_new;    // p[47]
        p[47] = Vtsh_new;  // p[48]
        p[68] = Vp_ratio;  // p[69]
        p[28] = k05_new;   // p[29]
    }

    public static double[] defaultInitialConditions() {
        return new double[]{
            0.322114215761171,   // q[1]  T4 plasma
            0.201296960359917,   // q[2]  T4 fast
            0.638967411907560,   // q[3]  T4 slow
            0.00663104034826483, // q[4]  T3 plasma
            0.0112595761822961,  // q[5]  T3 fast
            0.0652960640300348,  // q[6]  T3 slow
            1.78829584764370,    // q[7]  TSH plasma
            7.05727560072869,    // q[8]  T3B
            7.05714474742141,    // q[9]  T3B LAG
            0.0,                 // q[10] T4 PILL
            0.0,                 // q[11] T4 GUT
            0.0,                 // q[12] T3 PILL
            0.0,                 // q[13] T3 GUT
            3.34289716182018,    // q[14] delay1
            3.69277248068433,    // q[15] delay2
            3.87942133769244,    // q[16] delay3
            3.90061903207543,    // q[17] delay4
            3.77875734283571,    // q[18] delay5
            3.55364471589659     // q[19] delay6
        };
    }

    /**
     * Holds the output of a simulation run.
     * All hormone arrays are in standard clinical units:
     *   T4  µg/L,  T3  µg/L,  TSH  mU/L,  FT4  ng/L,  FT3  ng/L.
     * The time array unit matches the requested mode ("hours" or "days").
     */
    public static class SimResult {
        /** Time points (hours or days, depending on mode). */
        public final double[] time;
        /** Total T4 (µg/L). */
        public final double[] T4;
        /** Total T3 (µg/L). */
        public final double[] T3;
        /** TSH (mU/L). */
        public final double[] TSH;
        /** Free T4 (ng/L). */
        public final double[] FT4;
        /** Free T3 (ng/L). */
        public final double[] FT3;

        SimResult(double[] time, double[] T4, double[] T3,
                  double[] TSH, double[] FT4, double[] FT3) {
            this.time = time; this.T4 = T4; this.T3 = T3;
            this.TSH = TSH;   this.FT4 = FT4; this.FT3 = FT3;
        }

        /** Print a CSV header + rows to stdout (useful for testing). */
        public void printCSV() {
            System.out.println("time,T4_ugL,T3_ugL,TSH_mUL,FT4_ngL,FT3_ngL");
            for (int i = 0; i < time.length; i++) {
                System.out.printf("%.6f,%.6f,%.6f,%.6f,%.6f,%.6f%n",
                    time[i], T4[i], T3[i], TSH[i], FT4[i], FT3[i]);
            }
        }
    }
    

    public static class DoseEvent {
        /** Time of dose (hours from t=0). */
        public final double timeHours;
        /** T4 dose in µg. */
        public final double T4dose_ug;
        /** T3 dose in µg. */
        public final double T3dose_ug;

        public DoseEvent(double timeHours, double T4dose_ug, double T3dose_ug) {
            this.timeHours  = timeHours;
            this.T4dose_ug  = T4dose_ug;
            this.T3dose_ug  = T3dose_ug;
        }
    }

    public static List<DoseEvent> buildPeriodicSchedule(
            double T4dose_ug, double T3dose_ug,
            double intervalHours, int totalDays) {
        List<DoseEvent> events = new ArrayList<>();
        double end = totalDays * 24.0;
        for (double t = 0.0; t < end; t += intervalHours) {
            events.add(new DoseEvent(t, T4dose_ug, T3dose_ug));
        }
        return events;
    }


    // -----------------------------------------------------------------------
    // Main simulate() API
    // -----------------------------------------------------------------------

    /**
     * Simulate the p-THYROSIM model for a specific patient.
     *
     * @param sex            true = male, false = female
     * @param height         patient height in metres
     * @param weight         patient weight in kg
     * @param dial           double[4]: {RTF_T4, absorb_T4, RTF_T3, absorb_T3}
     *                       (typically {RTF, 0.88, RTF, 0.88})
     * @param doses          ordered list of {@link DoseEvent}s; may be empty
     * @param mode           "hours" or "days"
     * @param simulationDays simulation length in days (≤100 for hours, ≤1000 for days)
     * @param warmup         if true, run 30-day no-dose warmup first to find patient IC
     * @return               {@link SimResult} containing time + hormone arrays
     */
    public static SimResult simulate(
            boolean sex, double height, double weight,
            double[] dial, List<DoseEvent> doses,
            String mode, int simulationDays, boolean warmup) {

        if (mode.equals("hours") && simulationDays > 100) {
            throw new IllegalArgumentException("Hours mode supports at most 100 days.");
        }
        if (mode.equals("days") && simulationDays > 1000) {
            throw new IllegalArgumentException("Days mode supports at most 1000 days.");
        }

        // --- Build parameter array ---
        double[] p = defaultParameters();

        // Apply dials
        p[56] = dial[0]; // p[57] dial1 T4 secretion
        p[57] = dial[1]; // p[58] dial2 T4 absorption
        p[58] = dial[2]; // p[59] dial3 T3 secretion
        p[59] = dial[3]; // p[60] dial4 T3 absorption

        // Personalise Vp, Vtsh, k05
        personaliseParameters(p, sex, height, weight);

        // --- Initial conditions ---
        double[] ic = defaultInitialConditions();

        // Optional warmup: 30-day no-dose run to get patient-specific steady-state IC
        if (warmup) {
            ic = runWarmup(ic, p, 30);
        }

        // --- Integrate with dose events ---
        double endHours = simulationDays * 24.0;
        SimResult result = integrateWithDoses(ic, p, doses, endHours, mode);
        return result;
    }

    // -----------------------------------------------------------------------
    // Internal: warmup run (no doses)
    // -----------------------------------------------------------------------
    private static double[] runWarmup(double[] ic0, double[] p, int days) {
        double[] ic = Arrays.copyOf(ic0, ic0.length);
        Thyrosim ode = new Thyrosim(p);
        FirstOrderIntegrator integrator = makeIntegrator();

        // Simple step handler to capture final state
        final double[][] finalState = {null};
        integrator.addStepHandler(new StepHandler() {
            public void init(double t0, double[] y0, double t) {}
            public void handleStep(StepInterpolator interp, boolean isLast) {
                if (isLast) finalState[0] = interp.getInterpolatedState().clone();
            }
        });

        integrator.integrate(ode, 0.0, ic, days * 24.0, ic);
        return (finalState[0] != null) ? finalState[0] : ic;
    }

    // -----------------------------------------------------------------------
    // Internal: piecewise integration with dose events
    // -----------------------------------------------------------------------
    private static SimResult integrateWithDoses(
            double[] ic0, double[] p,
            List<DoseEvent> doses, double endHours, String mode) {

        // Collect all event times (sorted) and insert a sentinel at endHours
        List<Double> breakpoints = new ArrayList<>();
        for (DoseEvent de : doses) {
            if (de.timeHours >= 0 && de.timeHours < endHours) {
                breakpoints.add(de.timeHours);
            }
        }
        breakpoints.add(endHours);

        // Output accumulators
        List<Double> timeList = new ArrayList<>();
        List<double[]> stateList = new ArrayList<>();

        double[] state = Arrays.copyOf(ic0, ic0.length);
        double tCurrent = 0.0;
        int doseIdx = 0; // pointer into doses list

        // Advance through each segment
        for (double tNext : breakpoints) {
            if (tNext <= tCurrent) {
                // Apply any doses at this exact time before integrating
                state = applyDosesAt(state, p, doses, tCurrent);
                tCurrent = tNext;
                continue;
            }

            // Apply doses at tCurrent
            state = applyDosesAt(state, p, doses, tCurrent);

            // Integrate from tCurrent to tNext
            Thyrosim ode = new Thyrosim(p);
            FirstOrderIntegrator integrator = makeIntegrator();

            List<Double> segTime   = new ArrayList<>();
            List<double[]> segState = new ArrayList<>();

            integrator.addStepHandler(new StepHandler() {
                public void init(double t0, double[] y0, double t) {}
                public void handleStep(StepInterpolator interp, boolean isLast) {
                    segTime.add(interp.getCurrentTime());
                    segState.add(interp.getInterpolatedState().clone());
                }
            });

            double[] stateEnd = Arrays.copyOf(state, state.length);
            integrator.integrate(ode, tCurrent, state, tNext, stateEnd);

            // Append segment outputs (skip first point if not the very beginning to avoid duplicates)
            boolean isFirstSegment = (tCurrent == 0.0);
            for (int i = (isFirstSegment ? 0 : 1); i < segTime.size(); i++) {
                timeList.add(segTime.get(i));
                stateList.add(segState.get(i));
            }

            state = stateEnd;
            tCurrent = tNext;
        }

        // Convert accumulated outputs to clinical-unit arrays
        int n = timeList.size();
        double[] timeArr = new double[n];
        double[] T4arr   = new double[n];
        double[] T3arr   = new double[n];
        double[] TSHarr  = new double[n];
        double[] FT4arr  = new double[n];
        double[] FT3arr  = new double[n];

        double Vp   = p[46]; // p[47]
        double Vtsh = p[47]; // p[48]

        for (int i = 0; i < n; i++) {
            double tHrs = timeList.get(i);
            double[] y  = stateList.get(i);

            double q1 = y[0];
            double q4 = y[3];
            double q7 = y[6];

            // Unit conversions matching notebook output_equations + FT4/FT3 equations
            T4arr[i]  = MW_T4 * q1 / Vp;
            T3arr[i]  = MW_T3 * q4 / Vp;
            TSHarr[i] = TSH_CONV * q7 / Vtsh;

            // FT4, FT3 – notebook uses 1.1 and 1.05 assay-adjustment scalars
            double q1Sq = q1 * q1, q1Cu = q1Sq * q1;
            double A = p[6], B = p[7], C = p[8], D = p[9]; // p[7..10]
            double a = p[23], b = p[24], c = p[25], d = p[26]; // p[24..27]
            double ft4_raw = 0.45 * (A + B*q1 + C*q1Sq + D*q1Cu) * q1;
            double ft3_raw = 0.5  * (a + b*q1 + c*q1Sq + d*q1Cu) * q4;
            FT4arr[i] = 1.1 * 1000.0 * MW_T4 * ft4_raw / Vp;
            FT3arr[i] = 1.05 * 1000.0 * MW_T3 * ft3_raw / Vp;

            // Convert time axis to requested unit
            timeArr[i] = mode.equals("days") ? tHrs / 24.0 : tHrs;
        }

        return new SimResult(timeArr, T4arr, T3arr, TSHarr, FT4arr, FT3arr);
    }

    // Apply all dose events that fall exactly at time tCurrent
    private static double[] applyDosesAt(double[] state, double[] p,
                                          List<DoseEvent> doses, double t) {
        double[] s = Arrays.copyOf(state, state.length);
        for (DoseEvent de : doses) {
            if (Math.abs(de.timeHours - t) < 1e-9) {
                s[9]  += de.T4dose_ug / MW_T4; // T4 PILL (q[10] in 1-based)
                s[11] += de.T3dose_ug / MW_T3; // T3 PILL (q[12] in 1-based)
            }
        }
        return s;
    }

    // Shared integrator settings (DOP853, tolerances from original Thyrosim.java)
    private static FirstOrderIntegrator makeIntegrator() {
        return new DormandPrince853Integrator(1e-8, 100.0, 1e-10, 1e-10);
    }

    // -----------------------------------------------------------------------
    // Perl CGI integration: command-line entry point
    //
    // Argument layout (matches old Thyrosim.java and ajax_getplot.cgi):
    //   args[0-18]  : 19 initial conditions
    //   args[19]    : ODE start time (hours)
    //   args[20]    : ODE end time   (hours)
    //   args[21-24] : dial1-4 (T4 secretion, T4 absorption, T3 secretion, T3 absorption)
    //   args[25]    : inf1  – T4 IV infusion rate
    //   args[26]    : inf4  – T3 IV infusion rate
    //   args[27]    : thysim string (ignored – new kernel uses defaultParameters())
    //   args[28]    : "initic" (print final state only) or "noinit" (print all steps)
    //   args[29-77] : kdelay + p1-p48 (ignored – new kernel uses defaultParameters())
    //   args[78]    : height in metres  (optional, requires args[79-80])
    //   args[79]    : weight in kg      (optional)
    //   args[80]    : sex  "1"=male, "0"=female (optional)
    //
    // Output per line: t q[0] q[1] ... q[18] FT4p FT3p   (space-separated)
    // -----------------------------------------------------------------------
    public static void main(String[] args)
    {
        // --- Initial conditions ---
        double[] q = new double[19];
        for (int i = 0; i < 19; i++) {
            q[i] = Double.parseDouble(args[i]);
        }

        // --- Time bounds ---
        double t1 = Double.parseDouble(args[19]);
        double t2 = Double.parseDouble(args[20]);

        // --- Dials ---
        double dial1 = Double.parseDouble(args[21]);
        double dial2 = Double.parseDouble(args[22]);
        double dial3 = Double.parseDouble(args[23]);
        double dial4 = Double.parseDouble(args[24]);

        // --- IV infusions ---
        double inf1 = Double.parseDouble(args[25]); // T4
        double inf4 = Double.parseDouble(args[26]); // T3

        // args[27] = thysim string (ignored)
        final String initic = args[28];
        // args[29-77] = kdelay + p1-p48 (ignored)

        // --- Build parameter array and apply dials/infusions ---
        double[] p = defaultParameters();
        p[56] = dial1; // dial1 T4 secretion
        p[57] = dial2; // dial2 T4 absorption
        p[58] = dial3; // dial3 T3 secretion
        p[59] = dial4; // dial4 T3 absorption
        p[80] = inf1;  // T4 IV infusion rate
        p[81] = inf4;  // T3 IV infusion rate

        // --- Anthropometric personalisation (optional) ---
        if (args.length >= 81) {
            double  height = Double.parseDouble(args[78]);
            double  weight = Double.parseDouble(args[79]);
            boolean isMale = args[80].equals("1");
            personaliseParameters(p, isMale, height, weight);
        }

        // --- Integrate ---
        final Thyrosim ode = new Thyrosim(p);
        final double[] fp  = p;

        StepHandler stepHandler = new StepHandler() {
            public void init(double t0, double[] y0, double t) {}
            public void handleStep(StepInterpolator interpolator, boolean isLast) {
                double   t = interpolator.getCurrentTime();
                double[] y = interpolator.getInterpolatedState();
                if (initic.equals("initic")) {
                    if (isLast) System.out.println(getLine(t, y, fp));
                } else {
                    System.out.println(getLine(t, y, fp));
                }
            }
        };

        double[] qEnd = Arrays.copyOf(q, q.length);
        FirstOrderIntegrator foi = makeIntegrator();
        foi.addStepHandler(stepHandler);
        foi.integrate(ode, t1, q, t2, qEnd);
    }

    // Output one time-step line in the format the Perl CGI parser expects:
    //   t q[0..18] FT4p FT3p
    private static String getLine(double t, double[] y, double[] p) {
        StringBuilder sb = new StringBuilder();
        sb.append(t).append(" ");
        for (double v : y) sb.append(v).append(" ");

        // FT4p and FT3p use scaled plasma concentration (q1 = y[0] / Vp_ratio)
        double Vp_ratio = p[68]; // p[69]; defaults to 1.0 when not personalised
        double q1   = y[0] / Vp_ratio;
        double q4   = y[3] / Vp_ratio;
        double q1sq = q1 * q1, q1cu = q1sq * q1;
        double ft4  = (p[6] + p[7]*q1 + p[8]*q1sq + p[9]*q1cu) * q1;
        double ft3  = (p[23] + p[24]*q1 + p[25]*q1sq + p[26]*q1cu) * q4;
        sb.append(ft4).append(" ").append(ft3).append(" ");
        return sb.toString();
    }
}

