function CodeMetrics = ...
        MeasureADCCodeUsage(SampledSignal, Indices, Parameters)
%% ==================================
%% MEASURE ADC OUTPUT CODE UTILIZATION
%% ==================================
% Measures how the ADC output-code range is exercised by the sampled input.
%
% Inputs:
%   SampledSignal - ADC sampled signal before quantization
%   Indices       - Quantizer output indices
%   Parameters    - ADC parameter object containing Vfs and NumBits
%
% Output:
%   CodeMetrics   - Structure containing ADC code-usage measurements


    %% ======================
    %% VALIDATE INPUT SIGNALS
    %% ======================

    ValidSampledSignal = ...
        isnumeric(SampledSignal) && ...
        isreal(SampledSignal) && ...
        (isvector(SampledSignal) || isempty(SampledSignal)) && ...
        all(isfinite(SampledSignal(:)));

    ValidIndices = ...
        isnumeric(Indices) && ...
        isreal(Indices) && ...
        (isvector(Indices) || isempty(Indices)) && ...
        all(isfinite(Indices(:)));

    if ~ValidSampledSignal || ~ValidIndices
        error("MeasureADCCodeUsage:InvalidInput", ...
            "SampledSignal and Indices must be finite real-valued vectors.");
    end


    %% ===========================
    %% FORCE COLUMN-VECTOR FORMAT
    %% ===========================

    SampledSignal = double(SampledSignal(:));
    Indices = double(Indices(:));

    N = numel(SampledSignal);

    if numel(Indices) ~= N
        error("MeasureADCCodeUsage:LengthMismatch", ...
            "SampledSignal and Indices must have equal lengths.");
    end


    %% ===========================
    %% READ ADC CODE PARAMETERS
    %% ===========================

    Vfs = Parameters.getValue("Vfs");
    NumBits = Parameters.getValue("NumBits");

    NumberAvailableCodes = 2^NumBits;
    MinimumAvailableCode = 0;
    MaximumAvailableCode = NumberAvailableCodes - 1;

    MinimumInputLevel = -(abs(Vfs) / 2);
    MaximumInputLevel =  (abs(Vfs) / 2);


    %% ============================
    %% VALIDATE QUANTIZER INDICES
    %% ============================

    if any(Indices ~= floor(Indices))
        error("MeasureADCCodeUsage:NonIntegerIndices", ...
            "ADC quantizer indices must contain integer-valued codes.");
    end

    if any(Indices < MinimumAvailableCode | ...
            Indices > MaximumAvailableCode)

        error("MeasureADCCodeUsage:IndexOutOfRange", ...
            "ADC quantizer indices exceed the available code range.");
    end


    %% ================================
    %% HANDLE EMPTY SIGNALS CLEANLY
    %% ================================

    if N == 0

        CodeMetrics = struct( ...
            "NumberAvailableCodes", NumberAvailableCodes, ...
            "MinimumAvailableCode", MinimumAvailableCode, ...
            "MaximumAvailableCode", MaximumAvailableCode, ...
            "MinimumCodeUsed", NaN, ...
            "MaximumCodeUsed", NaN, ...
            "UniqueCodesUsed", 0, ...
            "CodeUtilizationPercentage", NaN, ...
            "CodeSpan", 0, ...
            "CodeSpanPercentage", NaN, ...
            "OverloadSampleCount", 0, ...
            "OverloadPercentage", NaN, ...
            "MinimumInputLevel", MinimumInputLevel, ...
            "MaximumInputLevel", MaximumInputLevel);

        return
    end


    %% ============================
    %% MEASURE ADC CODE UTILIZATION
    %% ============================

    MinimumCodeUsed = min(Indices);
    MaximumCodeUsed = max(Indices);

    UniqueCodesUsed = numel(unique(Indices));

    CodeUtilizationPercentage = ...
        100 * UniqueCodesUsed / NumberAvailableCodes;

    % Span between the lowest and highest exercised codes, including both
    % endpoints. This is distinct from the number of unique codes used.
    CodeSpan = ...
        MaximumCodeUsed - MinimumCodeUsed + 1;

    CodeSpanPercentage = ...
        100 * CodeSpan / NumberAvailableCodes;


    %% ================================
    %% MEASURE ADC INPUT OVERLOAD
    %% ================================

    % Samples outside the nominal bipolar ADC full-scale input range are
    % treated as overload samples.
    OverloadMask = ...
        SampledSignal < MinimumInputLevel | ...
        SampledSignal > MaximumInputLevel;

    OverloadSampleCount = sum(OverloadMask);

    OverloadPercentage = ...
        100 * OverloadSampleCount / N;


    %% ==========================
    %% STORE ADC CODE MEASUREMENTS
    %% ==========================

    CodeMetrics.NumberAvailableCodes = ...
        NumberAvailableCodes;

    CodeMetrics.MinimumAvailableCode = ...
        MinimumAvailableCode;

    CodeMetrics.MaximumAvailableCode = ...
        MaximumAvailableCode;

    CodeMetrics.MinimumCodeUsed = ...
        MinimumCodeUsed;

    CodeMetrics.MaximumCodeUsed = ...
        MaximumCodeUsed;

    CodeMetrics.UniqueCodesUsed = ...
        UniqueCodesUsed;

    CodeMetrics.CodeUtilizationPercentage = ...
        CodeUtilizationPercentage;

    CodeMetrics.CodeSpan = ...
        CodeSpan;

    CodeMetrics.CodeSpanPercentage = ...
        CodeSpanPercentage;

    CodeMetrics.OverloadSampleCount = ...
        OverloadSampleCount;

    CodeMetrics.OverloadPercentage = ...
        OverloadPercentage;

    CodeMetrics.MinimumInputLevel = ...
        MinimumInputLevel;

    CodeMetrics.MaximumInputLevel = ...
        MaximumInputLevel;
end
