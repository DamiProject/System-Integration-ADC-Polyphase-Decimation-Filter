function [MinimumOrder, MinimumCutoffHz, TransitionWidthHz, ...
    ConfiguredOrder, OrderOK, RollOff_dBPerOctave, ...
    RollOff_dBPerDecade] = ...
    FindButterworthOrder(Parameters, FilterType)
%% ============================================================
%% BUTTERWORTH HPF / LPF MINIMUM ORDER AND ROLL-OFF ESTIMATION
%% ============================================================
%
% Determines the minimum Butterworth order required to satisfy the
% configured ADC passband / stopband specifications.
%
% FilterType:
%   "HPF" - ADC DC-removal high-pass filter
%   "LPF" - ADC anti-aliasing low-pass filter
%
% This function does not redesign the ADC filter. It characterizes
% whether the filter order already selected in ADCParameters is at
% least the minimum order required by the specified response.

Fs = Parameters.getValue("Fs");

FilterType = upper(string(FilterType));

switch FilterType

    case "HPF"
        %% ==========================
        %% HIGH-PASS SPECIFICATIONS
        %% ==========================
        Fstop = Parameters.getValue("FstopHPF");
        Fpass = Parameters.getValue("FpassHPF");
        Apass = Parameters.getValue("ApassHPF");
        Astop = Parameters.getValue("AstopHPF");

        ConfiguredOrder = Parameters.getValue("nHpf");

        % HPF stopband must lie below its passband edge.
        if Fstop >= Fpass
            error('FindButterworthOrder:InvalidHPFEdges', ...
                'HPF requires FstopHPF < FpassHPF.');
        end

    case "LPF"
        %% =========================
        %% LOW-PASS SPECIFICATIONS
        %% =========================
        Fpass = Parameters.getValue("FpassLPF");
        Fstop = Parameters.getValue("FstopLPF");
        Apass = Parameters.getValue("ApassLPF");
        Astop = Parameters.getValue("AstopLPF");

        ConfiguredOrder = Parameters.getValue("nLpf");

        % LPF passband must lie below its stopband edge.
        if Fpass >= Fstop
            error('FindButterworthOrder:InvalidLPFEdges', ...
                'LPF requires FpassLPF < FstopLPF.');
        end

    otherwise
        error('FindButterworthOrder:InvalidFilterType', ...
            'FilterType must be "HPF" or "LPF".');
end

%% ==========================================
%% VALIDATE FREQUENCY / ATTENUATION SETTINGS
%% ==========================================

if Fpass <= 0 || Fstop <= 0 || ...
        Fpass >= Fs/2 || Fstop >= Fs/2

    error('FindButterworthOrder:InvalidFrequencySpecification', ...
        ['Passband and stopband edge frequencies must be ', ...
         'positive and below the Nyquist frequency.']);
end

if Apass <= 0 || Astop <= 0
    error('FindButterworthOrder:InvalidAttenuationSpecification', ...
        'Apass and Astop must both be positive values in dB.');
end

%% ============================
%% TRANSITION WIDTH CALCULATION
%% ============================

TransitionWidthHz = abs(Fstop - Fpass);

%% =========================================
%% NORMALIZE BAND EDGES FOR BUTTERWORTH ORDER
%% =========================================

Wpass = Fpass / (Fs/2);
Wstop = Fstop / (Fs/2);

%% ======================================
%% MINIMUM REQUIRED BUTTERWORTH FILTER ORDER
%% ======================================

[MinimumOrder, MinimumCutoffNormalized] = ...
    buttord(Wpass, Wstop, Apass, Astop);

% Convert normalized Butterworth cutoff returned by buttord into Hz.
MinimumCutoffHz = MinimumCutoffNormalized * (Fs/2);

%% ==============================
%% CONFIGURED ORDER VERIFICATION
%% ==============================

OrderOK = ConfiguredOrder >= MinimumOrder;

%% =====================================
%% BUTTERWORTH ASYMPTOTIC ROLL-OFF RATE
%% =====================================
%
% Each Butterworth order contributes approximately:
%   6.0206 dB/octave
%   20 dB/decade
%
% The reported roll-off is based on the implemented filter order.

RollOff_dBPerOctave = ...
    6.020599913279624 * ConfiguredOrder;

RollOff_dBPerDecade = ...
    20 * ConfiguredOrder;

%% ============================
%% COMMAND-WINDOW SUMMARY
%% ============================

fprintf('\n%s Butterworth Order Analysis\n', FilterType);
fprintf('----------------------------------------\n');
fprintf('Transition width          = %.6g Hz\n', TransitionWidthHz);
fprintf('Minimum required order    = %d\n', MinimumOrder);
fprintf('Configured filter order   = %d\n', ConfiguredOrder);
fprintf('Minimum-order cutoff      = %.6g Hz\n', MinimumCutoffHz);
fprintf('Roll-off                  = %.4f dB/octave\n', ...
    RollOff_dBPerOctave);
fprintf('Roll-off                  = %.4f dB/decade\n', ...
    RollOff_dBPerDecade);

if OrderOK
    fprintf('Order requirement          = PASS\n');
else
    fprintf('Order requirement          = FAIL\n');
end
end
