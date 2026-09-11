function [CoefficientRMSE, MaxAbsCoefficientError, ...
    MaxComplexResponseError, ...
    FloatPassbandRipple_dB, FixedPassbandRipple_dB, ...
    PassbandRippleChange_dB, ...
    FloatStopbandAttenuation_dB, FixedStopbandAttenuation_dB, ...
    StopbandAttenuationChange_dB, ...
    FixedPassbandOK, FixedStopbandOK, FixedOverallOK] = ...
    CompareFIRResponses( ...
    FloatingCoefficients, FixedCoefficientCodes, ...
    CoefficientScale, Parameters, NPoint)
%% ============================================================
%% FLOATING-POINT VS FIXED-POINT FIR RESPONSE CHARACTERIZATION
%% ============================================================
%
% Compares the original floating-point FIR coefficients against the
% represented fixed-point FIR coefficients reconstructed from integer
% coefficient codes and their scale factor.
%
% This function answers:
%   1. How much coefficient quantization error was introduced?
%   2. How much did the FIR frequency response change?
%   3. Did passband ripple degrade?
%   4. Did stopband attenuation degrade?
%   5. Does the fixed-point FIR still satisfy the DSP specifications?
%
% Inputs:
%   FloatingCoefficients - original floating-point FIR coefficients
%   FixedCoefficientCodes - integer fixed-point coefficient codes
%   CoefficientScale      - coefficient scale, normally 2^CoeffFWL
%   Parameters            - DSPParameters object
%   NPoint                - optional frequency-response grid size
%
% Outputs:
%   CoefficientRMSE
%   MaxAbsCoefficientError
%   MaxComplexResponseError
%   FloatPassbandRipple_dB
%   FixedPassbandRipple_dB
%   PassbandRippleChange_dB
%   FloatStopbandAttenuation_dB
%   FixedStopbandAttenuation_dB
%   StopbandAttenuationChange_dB
%   FixedPassbandOK
%   FixedStopbandOK
%   FixedOverallOK

if nargin < 5 || isempty(NPoint)
    NPoint = 16384;
end

validateattributes(NPoint, {'numeric'}, ...
    {'scalar', 'integer', 'finite', '>=', 16});

%% =========================
%% RETRIEVE DSP PARAMETERS
%% =========================

Fs_DSP = Parameters.getValue("Fs_DSP");
Fpass  = Parameters.getValue("Fpass");
Fstop  = Parameters.getValue("Fstop");
Apass  = Parameters.getValue("Apass");
Astop  = Parameters.getValue("Astop");

%% =========================
%% VALIDATE COEFFICIENT INPUTS
%% =========================

ValidFloatingCoefficients = ...
    isnumeric(FloatingCoefficients) && ...
    isreal(FloatingCoefficients) && ...
    isvector(FloatingCoefficients) && ...
    ~isempty(FloatingCoefficients) && ...
    all(isfinite(FloatingCoefficients(:)));

if ~ValidFloatingCoefficients
    error('CompareFIRResponses:InvalidFloatingCoefficients', ...
        ['FloatingCoefficients must be a finite real ', ...
         'numeric vector.']);
end

ValidFixedCodes = ...
    isnumeric(FixedCoefficientCodes) && ...
    isreal(FixedCoefficientCodes) && ...
    isvector(FixedCoefficientCodes) && ...
    ~isempty(FixedCoefficientCodes) && ...
    all(isfinite(double(FixedCoefficientCodes(:))));

if ~ValidFixedCodes
    error('CompareFIRResponses:InvalidFixedCoefficientCodes', ...
        ['FixedCoefficientCodes must be a finite real ', ...
         'numeric vector.']);
end

validateattributes(CoefficientScale, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});

FloatingCoefficients = ...
    double(FloatingCoefficients(:).');

FixedCoefficientCodes = ...
    double(FixedCoefficientCodes(:).');

if numel(FloatingCoefficients) ~= ...
        numel(FixedCoefficientCodes)

    error('CompareFIRResponses:CoefficientLengthMismatch', ...
        ['FloatingCoefficients and FixedCoefficientCodes ', ...
         'must contain the same number of coefficients.']);
end

if Fpass <= 0 || Fstop <= 0 || ...
        Fpass >= Fstop || Fstop >= Fs_DSP/2

    error('CompareFIRResponses:InvalidFrequencySpecification', ...
        'FIR LPF requires 0 < Fpass < Fstop < Fs_DSP/2.');
end

if Apass <= 0 || Astop <= 0
    error('CompareFIRResponses:InvalidAttenuationSpecification', ...
        'Apass and Astop must both be positive values in dB.');
end

%% =====================================
%% RECONSTRUCT FIXED-POINT COEFFICIENTS
%% =====================================

FixedCoefficients = ...
    FixedCoefficientCodes / CoefficientScale;

%% =========================
%% COEFFICIENT ERROR
%% =========================

CoefficientError = ...
    FixedCoefficients - FloatingCoefficients;

CoefficientRMSE = ...
    sqrt(mean(CoefficientError.^2));

MaxAbsCoefficientError = ...
    max(abs(CoefficientError));

%% ==========================================
%% FREQUENCY RESPONSE VERIFICATION GRID
%% ==========================================
%
% Include the exact specification boundaries so neither response
% comparison can miss Fpass or Fstop.

f = linspace(0, Fs_DSP/2, NPoint + 1);

f = unique([f, Fpass, Fstop]);

[HFloat, f] = freqz( ...
    FloatingCoefficients, ...
    1, ...
    f, ...
    Fs_DSP);

[HFixed, ~] = freqz( ...
    FixedCoefficients, ...
    1, ...
    f, ...
    Fs_DSP);

%% =========================
%% COMPLEX RESPONSE ERROR
%% =========================
%
% This captures both magnitude and phase differences without relying on
% dB subtraction around deep spectral nulls.

MaxComplexResponseError = ...
    max(abs(HFixed - HFloat));

%% ======================================
%% FLOATING-POINT RESPONSE CHARACTERIZATION
%% ======================================

[FloatPassbandRipple_dB, ...
    FloatStopbandAttenuation_dB] = ...
    MeasureResponse( ...
    HFloat, ...
    f, ...
    Fpass, ...
    Fstop);

%% ===================================
%% FIXED-POINT RESPONSE CHARACTERIZATION
%% ===================================

[FixedPassbandRipple_dB, ...
    FixedStopbandAttenuation_dB] = ...
    MeasureResponse( ...
    HFixed, ...
    f, ...
    Fpass, ...
    Fstop);

%% =========================
%% RESPONSE DEGRADATION
%% =========================

PassbandRippleChange_dB = ...
    FixedPassbandRipple_dB - ...
    FloatPassbandRipple_dB;

StopbandAttenuationChange_dB = ...
    FixedStopbandAttenuation_dB - ...
    FloatStopbandAttenuation_dB;

%% ====================================
%% FIXED-POINT SPECIFICATION COMPLIANCE
%% ====================================

FixedPassbandOK = ...
    FixedPassbandRipple_dB <= Apass;

FixedStopbandOK = ...
    FixedStopbandAttenuation_dB >= Astop;

FixedOverallOK = ...
    FixedPassbandOK && FixedStopbandOK;

%% ============================
%% COMMAND-WINDOW SUMMARY
%% ============================

fprintf('\nFloating vs Fixed FIR Comparison\n');
fprintf('----------------------------------------\n');

fprintf('Coefficient RMSE               = %.6g\n', ...
    CoefficientRMSE);

fprintf('Maximum coefficient error      = %.6g\n', ...
    MaxAbsCoefficientError);

fprintf('Maximum complex response error = %.6g\n', ...
    MaxComplexResponseError);

fprintf('\nPassband Ripple\n');
fprintf('Floating-point                 = %.4f dB\n', ...
    FloatPassbandRipple_dB);
fprintf('Fixed-point                    = %.4f dB\n', ...
    FixedPassbandRipple_dB);
fprintf('Change                         = %.4f dB\n', ...
    PassbandRippleChange_dB);

fprintf('\nStopband Attenuation\n');
fprintf('Floating-point                 = %.4f dB\n', ...
    FloatStopbandAttenuation_dB);
fprintf('Fixed-point                    = %.4f dB\n', ...
    FixedStopbandAttenuation_dB);
fprintf('Change                         = %.4f dB\n', ...
    StopbandAttenuationChange_dB);

if FixedPassbandOK
    fprintf('\nFixed passband requirement     = PASS\n');
else
    fprintf('\nFixed passband requirement     = FAIL\n');
end

if FixedStopbandOK
    fprintf('Fixed stopband requirement     = PASS\n');
else
    fprintf('Fixed stopband requirement     = FAIL\n');
end

if FixedOverallOK
    fprintf('Fixed FIR specifications       = PASS\n');
else
    fprintf('Fixed FIR specifications       = FAIL\n');
end

%% ============================================
%% LOCAL FREQUENCY RESPONSE MEASUREMENT FUNCTION
%% ============================================

    function [PassbandRipple_dB, ...
            StopbandAttenuation_dB] = ...
            MeasureResponse( ...
            H, Frequency, PassbandEdge, StopbandEdge)

        Magnitude_dB = ...
            20 * log10(max(abs(H), eps));

        PassbandRegion = ...
            Frequency <= PassbandEdge;

        StopbandRegion = ...
            Frequency >= StopbandEdge;

        Passband_dB = ...
            Magnitude_dB(PassbandRegion);

        Stopband_dB = ...
            Magnitude_dB(StopbandRegion);

        PassbandRipple_dB = ...
            max(Passband_dB) - ...
            min(Passband_dB);

        WorstStopbandLevel_dB = ...
            max(Stopband_dB);

        StopbandAttenuation_dB = ...
            -WorstStopbandLevel_dB;
    end

end
