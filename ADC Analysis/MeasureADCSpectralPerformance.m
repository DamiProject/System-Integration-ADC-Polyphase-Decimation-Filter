function SpectralMetrics = ...
        MeasureADCSpectralPerformance(QuantizedSignal, Parameters)
%% ========================================
%% MEASURE ADC SPECTRAL PERFORMANCE
%% ========================================
% Measures ADC spectral performance from a real-valued quantized output
% signal obtained during a single-sinusoid test.
%
% For two-tone and multitone intermodulation measurements, use
% MeasureADCIntermodulationPerformance instead.
%
% Inputs:
%   QuantizedSignal - Quantized ADC output signal
%   Parameters      - ADC parameter object containing Fs and DF
%
% Output:
%   SpectralMetrics - Structure containing ADC spectral measurements


    %% =====================
    %% VALIDATE INPUT SIGNAL
    %% =====================

    ValidSignal = ...
        isnumeric(QuantizedSignal) && ...
        isreal(QuantizedSignal) && ...
        isvector(QuantizedSignal) && ...
        ~isempty(QuantizedSignal) && ...
        all(isfinite(QuantizedSignal(:)));

    if ~ValidSignal
        error("MeasureADCSpectralPerformance:InvalidSignal", ...
            "QuantizedSignal must be a finite real-valued numeric vector.");
    end


    %% ===========================
    %% FORCE COLUMN-VECTOR FORMAT
    %% ===========================

    QuantizedSignal = double(QuantizedSignal(:));


    %% ============================
    %% DETERMINE ADC SAMPLING RATE
    %% ============================

    Fs = Parameters.getValue("Fs");
    DF = Parameters.getValue("DF");

    ADCSamplingFrequency = Fs / DF;


    %% ============================
    %% SIGNAL-TO-NOISE RATIO
    %% ============================

    SNR = snr( ...
        QuantizedSignal, ...
        ADCSamplingFrequency);


    %% =============================================
    %% SIGNAL-TO-NOISE-AND-DISTORTION RATIO
    %% =============================================

    SINAD = sinad( ...
        QuantizedSignal, ...
        ADCSamplingFrequency);

    % SNDR is another commonly used name for the same ratio.
    SNDR = SINAD;


    %% =========================
    %% TOTAL HARMONIC DISTORTION
    %% =========================

    [THD, HarmonicPower, HarmonicFrequency] = ...
        thd( ...
            QuantizedSignal, ...
            ADCSamplingFrequency);


    %% ===========================
    %% SPURIOUS-FREE DYNAMIC RANGE
    %% ===========================

    [SFDR, LargestSpurPower, LargestSpurFrequency] = ...
        sfdr( ...
            QuantizedSignal, ...
            ADCSamplingFrequency);


    %% ========================
    %% EFFECTIVE NUMBER OF BITS
    %% ========================

    ENOB = ...
        (SINAD - 1.76) / 6.02;


    %% ============================
    %% FUNDAMENTAL SIGNAL FREQUENCY
    %% ============================

    if isempty(HarmonicFrequency)

        FundamentalFrequency = NaN;
        FundamentalPower = NaN;

    else

        FundamentalFrequency = HarmonicFrequency(1);
        FundamentalPower = HarmonicPower(1);
    end


    %% ======================================
    %% STORE ADC SPECTRAL PERFORMANCE METRICS
    %% ======================================

    SpectralMetrics.ADCSamplingFrequency = ...
        ADCSamplingFrequency;

    SpectralMetrics.FundamentalFrequency = ...
        FundamentalFrequency;

    SpectralMetrics.FundamentalPower = ...
        FundamentalPower;

    SpectralMetrics.SNR = ...
        SNR;

    SpectralMetrics.SINAD = ...
        SINAD;

    SpectralMetrics.SNDR = ...
        SNDR;

    SpectralMetrics.THD = ...
        THD;

    SpectralMetrics.SFDR = ...
        SFDR;

    SpectralMetrics.LargestSpurPower = ...
        LargestSpurPower;

    SpectralMetrics.LargestSpurFrequency = ...
        LargestSpurFrequency;

    SpectralMetrics.ENOB = ...
        ENOB;

    SpectralMetrics.HarmonicPower = ...
        HarmonicPower;

    SpectralMetrics.HarmonicFrequency = ...
        HarmonicFrequency;
end
