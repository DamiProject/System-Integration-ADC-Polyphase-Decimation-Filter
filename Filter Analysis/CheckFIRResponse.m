function [PassbandOK, StopbandOK, OverallOK, ...
    PassbandRipple_dB, StopbandAttenuation_dB, ...
    TransitionWidthHz, WorstStopbandFrequencyHz] = ...
    CheckFIRResponse(FilterCoefficients, Parameters, NPoint)
%% ======================================================
%% KAISER FIR LOW-PASS FREQUENCY RESPONSE VERIFICATION
%% ======================================================
%
% Verifies the realized FIR response against the DSP passband
% ripple and stopband attenuation specifications.
%
% This function does not redesign the FIR and does not recalculate
% the Kaiser beta or tap count. Those belong to WindowLPF.
%
% Inputs:
%   FilterCoefficients - realized floating-point FIR coefficients
%   Parameters         - DSPParameters object
%   NPoint             - optional frequency-response grid size
%
% Outputs:
%   PassbandOK
%   StopbandOK
%   OverallOK
%   PassbandRipple_dB
%   StopbandAttenuation_dB
%   TransitionWidthHz
%   WorstStopbandFrequencyHz

if nargin < 3 || isempty(NPoint)
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
%% VALIDATE FIR INPUT
%% =========================

ValidCoefficients = ...
    isnumeric(FilterCoefficients) && ...
    isreal(FilterCoefficients) && ...
    isvector(FilterCoefficients) && ...
    ~isempty(FilterCoefficients) && ...
    all(isfinite(FilterCoefficients(:)));

if ~ValidCoefficients
    error('CheckFIRResponse:InvalidCoefficients', ...
        ['FilterCoefficients must be a finite real ', ...
         'numeric vector.']);
end

FilterCoefficients = FilterCoefficients(:).';

if Fpass <= 0 || Fstop <= 0 || ...
        Fpass >= Fstop || ...
        Fstop >= Fs_DSP/2

    error('CheckFIRResponse:InvalidFrequencySpecification', ...
        'FIR LPF requires 0 < Fpass < Fstop < Fs_DSP/2.');
end

if Apass <= 0 || Astop <= 0
    error('CheckFIRResponse:InvalidAttenuationSpecification', ...
        'Apass and Astop must both be positive values in dB.');
end

%% ============================
%% TRANSITION WIDTH CALCULATION
%% ============================

TransitionWidthHz = Fstop - Fpass;

%% ==========================================
%% FREQUENCY RESPONSE VERIFICATION GRID
%% ==========================================
%
% Include the exact passband and stopband edges so the uniform
% frequency grid cannot skip the specification boundaries.

f = linspace(0, Fs_DSP/2, NPoint + 1);

f = unique([f, Fpass, Fstop]);

[H, f] = freqz( ...
    FilterCoefficients, ...
    1, ...
    f, ...
    Fs_DSP);

Magnitude_dB = ...
    20 * log10(max(abs(H), eps));

%% ============================
%% PASSBAND CHARACTERIZATION
%% ============================

PassbandRegion = (f <= Fpass);

Passband_dB = ...
    Magnitude_dB(PassbandRegion);

PassbandMaximum_dB = ...
    max(Passband_dB);

PassbandMinimum_dB = ...
    min(Passband_dB);

PassbandRipple_dB = ...
    PassbandMaximum_dB - PassbandMinimum_dB;

PassbandOK = ...
    PassbandRipple_dB <= Apass;

%% ============================
%% STOPBAND CHARACTERIZATION
%% ============================

StopbandRegion = (f >= Fstop);

Stopband_dB = ...
    Magnitude_dB(StopbandRegion);

StopbandFrequency = ...
    f(StopbandRegion);

[WorstStopbandLevel_dB, WorstStopbandIndex] = ...
    max(Stopband_dB);

StopbandAttenuation_dB = ...
    -WorstStopbandLevel_dB;

WorstStopbandFrequencyHz = ...
    StopbandFrequency(WorstStopbandIndex);

StopbandOK = ...
    StopbandAttenuation_dB >= Astop;

%% ============================
%% OVERALL SPECIFICATION CHECK
%% ============================

OverallOK = ...
    PassbandOK && StopbandOK;

%% ============================
%% COMMAND-WINDOW SUMMARY
%% ============================

fprintf('\nKaiser FIR Response Check\n');
fprintf('----------------------------------------\n');
fprintf('Passband edge             = %.6g Hz\n', Fpass);
fprintf('Stopband edge             = %.6g Hz\n', Fstop);
fprintf('Transition width          = %.6g Hz\n', ...
    TransitionWidthHz);

fprintf('Required passband ripple <= %.4f dB\n', ...
    Apass);
fprintf('Measured passband ripple  = %.4f dB\n', ...
    PassbandRipple_dB);

fprintf('Required stopband atten. >= %.4f dB\n', ...
    Astop);
fprintf('Measured stopband atten.  = %.4f dB\n', ...
    StopbandAttenuation_dB);
fprintf('Worst stopband frequency  = %.6g Hz\n', ...
    WorstStopbandFrequencyHz);

if PassbandOK
    fprintf('Passband requirement      = PASS\n');
else
    fprintf('Passband requirement      = FAIL\n');
end

if StopbandOK
    fprintf('Stopband requirement      = PASS\n');
else
    fprintf('Stopband requirement      = FAIL\n');
end

if OverallOK
    fprintf('Overall response           = PASS\n');
else
    fprintf('Overall response           = FAIL\n');
end

end
