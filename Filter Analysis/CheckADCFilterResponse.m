function [PassbandOK, StopbandOK, OverallOK, ...
    PassbandRipple_dB, WorstPassbandLoss_dB, ...
    StopbandAttenuation_dB, TransitionWidthHz, ...
    WorstStopbandFrequencyHz] = ...
    CheckADCFilterResponse(Parameters, FilterType, NPoint)
%% =========================================================
%% ADC BUTTERWORTH HPF / LPF FREQUENCY RESPONSE VERIFICATION
%% =========================================================
%
% Measures the realized ADC filter response against the explicit
% passband / stopband specifications stored in ADCParameters.
%
% FilterType:
%   "HPF" - ADC DC-removal high-pass filter
%   "LPF" - ADC anti-aliasing low-pass filter
%
% This function does not determine the required filter order.
% Use FindButterworthOrder.m for order justification.

if nargin < 3 || isempty(NPoint)
    NPoint = 16384;
end

validateattributes(NPoint, {'numeric'}, ...
    {'scalar', 'integer', 'finite', '>=', 16});

Fs = Parameters.getValue("Fs");

FilterType = upper(string(FilterType));

%% ===================================
%% RETRIEVE FILTER AND SPECIFICATIONS
%% ===================================

Filter = ADCFilter(Parameters);

switch FilterType

    case "HPF"
        [SOS, Gain] = Filter.DCRemoval();

        Fstop = Parameters.getValue("FstopHPF");
        Fpass = Parameters.getValue("FpassHPF");
        Apass = Parameters.getValue("ApassHPF");
        Astop = Parameters.getValue("AstopHPF");

        if Fstop >= Fpass
            error('CheckADCFilterResponse:InvalidHPFEdges', ...
                'HPF requires FstopHPF < FpassHPF.');
        end

    case "LPF"
        [SOS, Gain] = Filter.AAF();

        Fpass = Parameters.getValue("FpassLPF");
        Fstop = Parameters.getValue("FstopLPF");
        Apass = Parameters.getValue("ApassLPF");
        Astop = Parameters.getValue("AstopLPF");

        if Fpass >= Fstop
            error('CheckADCFilterResponse:InvalidLPFEdges', ...
                'LPF requires FpassLPF < FstopLPF.');
        end

    otherwise
        error('CheckADCFilterResponse:InvalidFilterType', ...
            'FilterType must be "HPF" or "LPF".');
end

%% ==========================================
%% VALIDATE FREQUENCY / ATTENUATION SETTINGS
%% ==========================================

if Fpass <= 0 || Fstop <= 0 || ...
        Fpass >= Fs/2 || Fstop >= Fs/2

    error('CheckADCFilterResponse:InvalidFrequencySpecification', ...
        ['Passband and stopband edge frequencies must be ', ...
         'positive and below the Nyquist frequency.']);
end

if Apass <= 0 || Astop <= 0
    error('CheckADCFilterResponse:InvalidAttenuationSpecification', ...
        'Apass and Astop must both be positive values in dB.');
end

%% ============================
%% TRANSITION WIDTH CALCULATION
%% ============================

TransitionWidthHz = abs(Fstop - Fpass);

%% ==========================================
%% FREQUENCY RESPONSE VERIFICATION GRID
%% ==========================================
%
% Include Fpass and Fstop explicitly so the exact specification
% boundaries cannot be missed by the uniform frequency grid.

f = linspace(0, Fs/2, NPoint + 1);
f = unique([f, Fpass, Fstop]);

[H, f] = freqz(SOS, f, Fs);

% Include the overall SOS cascade gain returned by ADCFilter.
H = Gain .* H;

Magnitude_dB = 20 * log10(max(abs(H), eps));

%% ==================================
%% PASSBAND / STOPBAND REGION MAPPING
%% ==================================

if FilterType == "HPF"
    PassbandRegion = (f >= Fpass);
    StopbandRegion = (f <= Fstop);
else
    PassbandRegion = (f <= Fpass);
    StopbandRegion = (f >= Fstop);
end

Passband_dB = Magnitude_dB(PassbandRegion);
Stopband_dB = Magnitude_dB(StopbandRegion);
StopbandFrequency = f(StopbandRegion);

%% ============================
%% PASSBAND CHARACTERIZATION
%% ============================

PassbandMaximum_dB = max(Passband_dB);
PassbandMinimum_dB = min(Passband_dB);

% Peak-to-peak variation across the specified passband.
PassbandRipple_dB = ...
    PassbandMaximum_dB - PassbandMinimum_dB;

% Butterworth passband specification is expressed as maximum
% attenuation from the nominal 0 dB passband level.
WorstPassbandLoss_dB = ...
    max(0, -PassbandMinimum_dB);

PassbandOK = ...
    WorstPassbandLoss_dB <= Apass;

%% ============================
%% STOPBAND CHARACTERIZATION
%% ============================

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

OverallOK = PassbandOK && StopbandOK;

%% ============================
%% COMMAND-WINDOW SUMMARY
%% ============================

fprintf('\n%s Butterworth Response Check\n', FilterType);
fprintf('----------------------------------------\n');
fprintf('Passband edge             = %.6g Hz\n', Fpass);
fprintf('Stopband edge             = %.6g Hz\n', Fstop);
fprintf('Transition width          = %.6g Hz\n', ...
    TransitionWidthHz);

fprintf('Required passband loss    <= %.4f dB\n', ...
    Apass);
fprintf('Measured passband loss     = %.4f dB\n', ...
    WorstPassbandLoss_dB);
fprintf('Measured passband ripple   = %.4f dB\n', ...
    PassbandRipple_dB);

fprintf('Required stopband atten.  >= %.4f dB\n', ...
    Astop);
fprintf('Measured stopband atten.   = %.4f dB\n', ...
    StopbandAttenuation_dB);
fprintf('Worst stopband frequency   = %.6g Hz\n', ...
    WorstStopbandFrequencyHz);

if PassbandOK
    fprintf('Passband requirement       = PASS\n');
else
    fprintf('Passband requirement       = FAIL\n');
end

if StopbandOK
    fprintf('Stopband requirement       = PASS\n');
else
    fprintf('Stopband requirement       = FAIL\n');
end

if OverallOK
    fprintf('Overall response            = PASS\n');
else
    fprintf('Overall response            = FAIL\n');
end

end
