function [AliasProtectionOK, StopbandPlacementOK, ...
    AliasAttenuationOK, OutputSampleRateHz, OutputNyquistHz, ...
    StopbandEdgeHz, AliasBandAttenuation_dB, ...
    WorstAliasFrequencyHz] = ...
    CheckDecimatorAliasProtection( ...
    FilterCoefficients, Parameters, NPoint)
%% ==================================================
%% POLYPHASE DECIMATOR ANTI-ALIAS PROTECTION CHECK
%% ==================================================
%
% Verifies that the FIR used before downsampling provides sufficient
% attenuation across the frequencies that lie above the output Nyquist
% frequency and would therefore fold into the decimated spectrum.
%
% This function is intentionally decimator-specific. Generic FIR
% passband / stopband compliance belongs to CheckFIRResponse.m.
%
% Inputs:
%   FilterCoefficients - realized FIR prototype coefficients
%   Parameters         - DSPParameters object
%   NPoint             - optional frequency-response grid size
%
% Outputs:
%   AliasProtectionOK
%   StopbandPlacementOK
%   AliasAttenuationOK
%   OutputSampleRateHz
%   OutputNyquistHz
%   StopbandEdgeHz
%   AliasBandAttenuation_dB
%   WorstAliasFrequencyHz

if nargin < 3 || isempty(NPoint)
    NPoint = 16384;
end

validateattributes(NPoint, {'numeric'}, ...
    {'scalar', 'integer', 'finite', '>=', 16});

%% =========================
%% RETRIEVE DSP PARAMETERS
%% =========================

Fs_DSP = Parameters.getValue("Fs_DSP");
DcF    = Parameters.getValue("DcF");
Fstop  = Parameters.getValue("Fstop");
Astop  = Parameters.getValue("Astop");

%% =========================
%% VALIDATE INPUTS
%% =========================

ValidCoefficients = ...
    isnumeric(FilterCoefficients) && ...
    isreal(FilterCoefficients) && ...
    isvector(FilterCoefficients) && ...
    ~isempty(FilterCoefficients) && ...
    all(isfinite(FilterCoefficients(:)));

if ~ValidCoefficients
    error('CheckDecimatorAliasProtection:InvalidCoefficients', ...
        ['FilterCoefficients must be a finite real ', ...
         'numeric vector.']);
end

FilterCoefficients = FilterCoefficients(:).';

validateattributes(DcF, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive', 'integer'});

if Fstop <= 0 || Fstop >= Fs_DSP/2
    error('CheckDecimatorAliasProtection:InvalidStopbandEdge', ...
        'Fstop must satisfy 0 < Fstop < Fs_DSP/2.');
end

if Astop <= 0
    error('CheckDecimatorAliasProtection:InvalidAttenuation', ...
        'Astop must be a positive value in dB.');
end

%% ==================================
%% DECIMATED SAMPLE-RATE CALCULATION
%% ==================================

OutputSampleRateHz = ...
    Fs_DSP / DcF;

OutputNyquistHz = ...
    OutputSampleRateHz / 2;

%% =====================================
%% STOPBAND PLACEMENT RELATIVE TO FOLDING
%% =====================================
%
% Frequencies above the output Nyquist frequency cannot be represented
% uniquely after decimation and will fold into the output spectrum.
%
% For full-band anti-alias protection, the specified FIR stopband should
% therefore already be established by the output Nyquist boundary.

StopbandEdgeHz = Fstop;

StopbandPlacementOK = ...
    Fstop <= OutputNyquistHz;

%% ==========================================
%% FREQUENCY RESPONSE VERIFICATION GRID
%% ==========================================
%
% Explicitly include both Fstop and the output Nyquist frequency.

f = linspace(0, Fs_DSP/2, NPoint + 1);

f = unique([ ...
    f, ...
    Fstop, ...
    OutputNyquistHz]);

[H, f] = freqz( ...
    FilterCoefficients, ...
    1, ...
    f, ...
    Fs_DSP);

Magnitude_dB = ...
    20 * log10(max(abs(H), eps));

%% ============================
%% ALIAS-BAND CHARACTERIZATION
%% ============================
%
% Every input frequency above the new output Nyquist frequency lies in
% a folding region after downsampling.

AliasBandRegion = ...
    (f >= OutputNyquistHz);

AliasBand_dB = ...
    Magnitude_dB(AliasBandRegion);

AliasBandFrequency = ...
    f(AliasBandRegion);

[WorstAliasLevel_dB, WorstAliasIndex] = ...
    max(AliasBand_dB);

AliasBandAttenuation_dB = ...
    -WorstAliasLevel_dB;

WorstAliasFrequencyHz = ...
    AliasBandFrequency(WorstAliasIndex);

AliasAttenuationOK = ...
    AliasBandAttenuation_dB >= Astop;

%% ============================
%% OVERALL ANTI-ALIAS CHECK
%% ============================

AliasProtectionOK = ...
    StopbandPlacementOK && ...
    AliasAttenuationOK;

%% ============================
%% COMMAND-WINDOW SUMMARY
%% ============================

fprintf('\nDecimator Alias-Protection Check\n');
fprintf('----------------------------------------\n');
fprintf('Input sample rate           = %.6g Hz\n', ...
    Fs_DSP);
fprintf('Decimation factor           = %d\n', ...
    DcF);
fprintf('Output sample rate          = %.6g Hz\n', ...
    OutputSampleRateHz);
fprintf('Output Nyquist frequency    = %.6g Hz\n', ...
    OutputNyquistHz);
fprintf('FIR stopband edge           = %.6g Hz\n', ...
    StopbandEdgeHz);

if StopbandPlacementOK
    fprintf('Stopband placement          = PASS\n');
else
    fprintf('Stopband placement          = FAIL\n');
end

fprintf('Required alias attenuation >= %.4f dB\n', ...
    Astop);
fprintf('Measured alias attenuation  = %.4f dB\n', ...
    AliasBandAttenuation_dB);
fprintf('Worst alias frequency       = %.6g Hz\n', ...
    WorstAliasFrequencyHz);

if AliasAttenuationOK
    fprintf('Alias attenuation           = PASS\n');
else
    fprintf('Alias attenuation           = FAIL\n');
end

if AliasProtectionOK
    fprintf('Overall alias protection    = PASS\n');
else
    fprintf('Overall alias protection    = FAIL\n');
end

end
