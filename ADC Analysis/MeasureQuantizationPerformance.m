function QuantizationMetrics = ...
        MeasureQuantizationPerformance(SampledSignal, QuantizedSignal, Parameters)
%% ==========================================
%% MEASURE ADC QUANTIZATION PERFORMANCE
%% ==========================================
% Measures the time-domain performance of the ADC quantizer by comparing
% the sampled input signal against the corresponding quantized signal.
%
% ADC measurements such as SNR, SINAD, THD, SFDR,
% and ENOB are handled separately.
%
% Inputs:
%   SampledSignal   - ADC sampled signal before quantization
%   QuantizedSignal - ADC signal after quantization
%   Parameters      - ADC parameter object containing Vfs and NumBits
%
% Output:
%   QuantizationMetrics - Structure containing quantization measurements


    %% ======================
    %% VALIDATE INPUT SIGNALS
    %% ======================

    ValidSampledSignal = ...
        isnumeric(SampledSignal) && ...
        isreal(SampledSignal) && ...
        (isvector(SampledSignal) || isempty(SampledSignal)) && ...
        all(isfinite(SampledSignal(:)));

    ValidQuantizedSignal = ...
        isnumeric(QuantizedSignal) && ...
        isreal(QuantizedSignal) && ...
        (isvector(QuantizedSignal) || isempty(QuantizedSignal)) && ...
        all(isfinite(QuantizedSignal(:)));

    if ~ValidSampledSignal || ~ValidQuantizedSignal
        error("MeasureQuantizationPerformance:InvalidSignal", ...
            "Input signals must be finite real-valued numeric vectors.");
    end


    %% ===========================
    %% FORCE COLUMN-VECTOR FORMAT
    %% ===========================

    SampledSignal = double(SampledSignal(:));
    QuantizedSignal = double(QuantizedSignal(:));

    N = numel(SampledSignal);

    if numel(QuantizedSignal) ~= N
        error("MeasureQuantizationPerformance:LengthMismatch", ...
            "SampledSignal and QuantizedSignal must have equal lengths.");
    end


    %% ==============================
    %% READ ADC QUANTIZER PARAMETERS
    %% ==============================

    Vfs = Parameters.getValue("Vfs");
    NumBits = Parameters.getValue("NumBits");

    QuantizationStep = Vfs / 2^NumBits;

    % Ideal uniform-quantizer noise-power model.
    TheoreticalQuantizationNoisePower = ...
        QuantizationStep^2 / 12;


    %% ================================
    %% HANDLE EMPTY SIGNALS CLEANLY
    %% ================================

    if N == 0

        QuantizationMetrics = struct( ...
            "QuantizationStep", QuantizationStep, ...
            "MeanQuantizationError", NaN, ...
            "RMSQuantizationError", NaN, ...
            "MaximumAbsoluteQuantizationError", NaN, ...
            "QuantizationNoisePower", NaN, ...
            "TheoreticalQuantizationNoisePower", ...
                TheoreticalQuantizationNoisePower, ...
            "SignalPower", NaN, ...
            "SQNR", NaN);

        return
    end


    %% ==========================
    %% CALCULATE QUANTIZATION ERROR
    %% ==========================

    % Match the sign convention used by ADC.Midtread() and ADC.Midrise():
    %
    %       Error = QuantizedSignal - SampledSignal
    %
    QuantizationError = ...
        QuantizedSignal - SampledSignal;


    %% ===============================
    %% QUANTIZATION ERROR MEASUREMENTS
    %% ===============================

    MeanQuantizationError = ...
        mean(QuantizationError);

    RMSQuantizationError = ...
        sqrt(mean(QuantizationError.^2));

    MaximumAbsoluteQuantizationError = ...
        max(abs(QuantizationError));


    %% =================================
    %% QUANTIZATION NOISE / SIGNAL POWER
    %% =================================

    % Mean-square quantization error is treated as quantization-noise power.
    QuantizationNoisePower = ...
        mean(QuantizationError.^2);

    SignalPower = ...
        mean(SampledSignal.^2);


    %% ==================================
    %% SIGNAL-TO-QUANTIZATION-NOISE RATIO
    %% ==================================

    if SignalPower == 0

        SQNR = NaN;

    elseif QuantizationNoisePower == 0

        SQNR = Inf;

    else

        SQNR = ...
            10*log10(SignalPower / QuantizationNoisePower);
    end


    %% ========================================
    %% STORE ADC QUANTIZATION PERFORMANCE DATA
    %% ========================================

    QuantizationMetrics.QuantizationStep = ...
        QuantizationStep;

    QuantizationMetrics.MeanQuantizationError = ...
        MeanQuantizationError;

    QuantizationMetrics.RMSQuantizationError = ...
        RMSQuantizationError;

    QuantizationMetrics.MaximumAbsoluteQuantizationError = ...
        MaximumAbsoluteQuantizationError;

    QuantizationMetrics.QuantizationNoisePower = ...
        QuantizationNoisePower;

    QuantizationMetrics.TheoreticalQuantizationNoisePower = ...
        TheoreticalQuantizationNoisePower;

    QuantizationMetrics.SignalPower = ...
        SignalPower;

    QuantizationMetrics.SQNR = ...
        SQNR;
end
