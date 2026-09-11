function IMDMetrics = ...
        MeasureADCIntermodulationPerformance( ...
        Signal, ToneFrequencies, Parameters, MeasurementSamplingFrequency)
%% ==============================================
%% MEASURE INTERMODULATION DISTORTION PERFORMANCE
%% ==============================================
% Measures second- and third-order intermodulation products from a
% real-valued signal containing two or more desired sinusoidal tones. An
% explicit sampling frequency may be supplied for pre-ADC/high-rate stages.
%
% The routine supports:
%   - two-tone tests using the conventional pairwise IM2 / IM3 products,
%   - multitone tests by evaluating pairwise products for every tone pair,
%   - third-order products involving three distinct desired tones.
%
% Product frequencies above the first Nyquist zone are folded to their
% sampled-output alias frequencies before measurement.
%
% Inputs:
%   Signal                       - Signal to characterize
%   ToneFrequencies              - Desired input-tone frequencies in Hz
%                                  (two or more)
%   Parameters                   - Parameter object containing Fs and DF
%   MeasurementSamplingFrequency - Optional explicit sampling frequency in Hz.
%                                  If omitted, Fs / DF is used for ADC-domain
%                                  measurements.
%
% Output:
%   IMDMetrics      - Structure containing tone and IMD measurements


    %% =====================
    %% VALIDATE INPUT SIGNAL
    %% =====================

    ValidSignal = ...
        isnumeric(Signal) && ...
        isreal(Signal) && ...
        isvector(Signal) && ...
        ~isempty(Signal) && ...
        all(isfinite(Signal(:)));

    if ~ValidSignal
        error("MeasureADCIntermodulationPerformance:InvalidSignal", ...
            "Signal must be a finite real-valued numeric vector.");
    end

    ValidTones = ...
        isnumeric(ToneFrequencies) && ...
        isreal(ToneFrequencies) && ...
        isvector(ToneFrequencies) && ...
        numel(ToneFrequencies) >= 2 && ...
        all(isfinite(ToneFrequencies(:)));

    if ~ValidTones
        error("MeasureADCIntermodulationPerformance:InvalidToneFrequencies", ...
            "ToneFrequencies must contain at least two finite real frequencies.");
    end


    %% ===========================
    %% FORCE COLUMN-VECTOR FORMAT
    %% ===========================

    Signal = double(Signal(:));
    ToneFrequencies = sort(double(ToneFrequencies(:)));

    if any(diff(ToneFrequencies) <= 0)
        error("MeasureADCIntermodulationPerformance:DuplicateToneFrequencies", ...
            "ToneFrequencies must contain distinct frequencies.");
    end


    %% ============================
    %% DETERMINE ADC SAMPLING RATE
    %% ============================

    if nargin < 4 || isempty(MeasurementSamplingFrequency)
        Fs = Parameters.getValue("Fs");
        DF = Parameters.getValue("DF");
        ADCSamplingFrequency = Fs / DF;
    else
        validateattributes( ...
            MeasurementSamplingFrequency, ...
            {'numeric'}, ...
            {'scalar', 'real', 'finite', 'positive'}, ...
            mfilename, ...
            'MeasurementSamplingFrequency');

        ADCSamplingFrequency = double(MeasurementSamplingFrequency);
    end

    NyquistFrequency = ADCSamplingFrequency / 2;

    if any(ToneFrequencies <= 0 | ToneFrequencies >= NyquistFrequency)
        error("MeasureADCIntermodulationPerformance:ToneOutsideNyquist", ...
            "Each desired tone must lie strictly inside the first Nyquist zone.");
    end


    %% ==========================
    %% HAMMING-WINDOW FFT RECORD
    %% ==========================

    N = numel(Signal);
    FrequencyResolution = ADCSamplingFrequency / N;

    Window = hamming(N, "periodic");
    WindowedSignal = Signal .* Window;

    X = fft(WindowedSignal);
    NumberPositiveBins = floor(N / 2) + 1;

    Magnitude = ...
        abs(X(1:NumberPositiveBins)) / sum(Window);

    if rem(N, 2) == 0
        if NumberPositiveBins > 2
            Magnitude(2:end-1) = 2 * Magnitude(2:end-1);
        end
    else
        if NumberPositiveBins > 1
            Magnitude(2:end) = 2 * Magnitude(2:end);
        end
    end

    Frequency = ...
        (0:NumberPositiveBins-1)' * ...
        ADCSamplingFrequency / N;

    SearchHalfWidth = 1.5 * FrequencyResolution;


    %% ============================
    %% MEASURE THE DESIRED CARRIERS
    %% ============================

    NumberTones = numel(ToneFrequencies);
    MeasuredToneFrequency = zeros(NumberTones, 1);
    ToneMagnitude = zeros(NumberTones, 1);

    for k = 1:NumberTones
        [MeasuredToneFrequency(k), ToneMagnitude(k)] = ...
            LocalMeasurePeak( ...
                Frequency, ...
                Magnitude, ...
                ToneFrequencies(k), ...
                SearchHalfWidth);
    end

    ToneLevel_dBV = ...
        20 * log10(max(ToneMagnitude, realmin("double")));

    ReferenceToneLevel_dBV = max(ToneLevel_dBV);

    ToneSummary = table( ...
        (1:NumberTones)', ...
        ToneFrequencies, ...
        MeasuredToneFrequency, ...
        ToneLevel_dBV, ...
        'VariableNames', { ...
            'ToneNumber', ...
            'ReferenceFrequency_Hz', ...
            'MeasuredFrequency_Hz', ...
            'Level_dBV'});


    %% ===================================
    %% GENERATE SECOND-ORDER IM PRODUCTS
    %% ===================================

    IM2Frequency = zeros(0,1);
    IM2Expression = strings(0,1);

    for i = 1:NumberTones-1
        for j = i+1:NumberTones

            CandidateFrequency = [ ...
                abs(ToneFrequencies(j) - ToneFrequencies(i)); ...
                ToneFrequencies(i) + ToneFrequencies(j)];

            CandidateExpression = [ ...
                string(sprintf("|f%d-f%d|", j, i)); ...
                string(sprintf("f%d+f%d", i, j))];

            IM2Frequency = [IM2Frequency; CandidateFrequency]; %#ok<AGROW>
            IM2Expression = [IM2Expression; CandidateExpression]; %#ok<AGROW>
        end
    end


    %% ==================================
    %% GENERATE THIRD-ORDER IM PRODUCTS
    %% ==================================

    IM3Frequency = zeros(0,1);
    IM3Expression = strings(0,1);

    % Conventional repeated-tone third-order products: 2fi +/- fj.
    for i = 1:NumberTones
        for j = 1:NumberTones
            if i == j
                continue
            end

            CandidateFrequency = [ ...
                abs(2 * ToneFrequencies(i) - ToneFrequencies(j)); ...
                2 * ToneFrequencies(i) + ToneFrequencies(j)];

            CandidateExpression = [ ...
                string(sprintf("|2f%d-f%d|", i, j)); ...
                string(sprintf("2f%d+f%d", i, j))];

            IM3Frequency = [IM3Frequency; CandidateFrequency]; %#ok<AGROW>
            IM3Expression = [IM3Expression; CandidateExpression]; %#ok<AGROW>
        end
    end

    % Three-distinct-tone third-order products: +/-fi +/-fj +/-fk.
    if NumberTones >= 3
        for i = 1:NumberTones-2
            for j = i+1:NumberTones-1
                for k = j+1:NumberTones

                    CandidateFrequency = [ ...
                        ToneFrequencies(i) + ToneFrequencies(j) + ToneFrequencies(k); ...
                        abs(ToneFrequencies(i) + ToneFrequencies(j) - ToneFrequencies(k)); ...
                        abs(ToneFrequencies(i) - ToneFrequencies(j) + ToneFrequencies(k)); ...
                        abs(-ToneFrequencies(i) + ToneFrequencies(j) + ToneFrequencies(k))];

                    CandidateExpression = [ ...
                        string(sprintf("f%d+f%d+f%d", i, j, k)); ...
                        string(sprintf("|f%d+f%d-f%d|", i, j, k)); ...
                        string(sprintf("|f%d-f%d+f%d|", i, j, k)); ...
                        string(sprintf("|-f%d+f%d+f%d|", i, j, k))];

                    IM3Frequency = [IM3Frequency; CandidateFrequency]; %#ok<AGROW>
                    IM3Expression = [IM3Expression; CandidateExpression]; %#ok<AGROW>
                end
            end
        end
    end


    %% =========================================
    %% FOLD PRODUCTS INTO FIRST NYQUIST ZONE
    %% =========================================

    IM2ObservedFrequency = ...
        LocalFoldToFirstNyquist(IM2Frequency, ADCSamplingFrequency);
    IM3ObservedFrequency = ...
        LocalFoldToFirstNyquist(IM3Frequency, ADCSamplingFrequency);


    %% =============================================
    %% REMOVE DC, CARRIER-COINCIDENT, AND DUPLICATES
    %% =============================================

    ExclusionTolerance = 2 * FrequencyResolution;

    [IM2Frequency, IM2ObservedFrequency, IM2Expression] = ...
        LocalCleanProducts( ...
            IM2Frequency, ...
            IM2ObservedFrequency, ...
            IM2Expression, ...
            ToneFrequencies, ...
            ExclusionTolerance);

    [IM3Frequency, IM3ObservedFrequency, IM3Expression] = ...
        LocalCleanProducts( ...
            IM3Frequency, ...
            IM3ObservedFrequency, ...
            IM3Expression, ...
            ToneFrequencies, ...
            ExclusionTolerance);


    %% =============================
    %% MEASURE INTERMODULATION PEAKS
    %% =============================

    IM2Summary = LocalMeasureProducts( ...
        2, ...
        IM2Expression, ...
        IM2Frequency, ...
        IM2ObservedFrequency, ...
        Frequency, ...
        Magnitude, ...
        SearchHalfWidth, ...
        ReferenceToneLevel_dBV);

    IM3Summary = LocalMeasureProducts( ...
        3, ...
        IM3Expression, ...
        IM3Frequency, ...
        IM3ObservedFrequency, ...
        Frequency, ...
        Magnitude, ...
        SearchHalfWidth, ...
        ReferenceToneLevel_dBV);


    %% ===============================
    %% SUMMARIZE WORST IMD PERFORMANCE
    %% ===============================

    WorstIM2_dBc = LocalWorstRelativeLevel(IM2Summary);
    WorstIM3_dBc = LocalWorstRelativeLevel(IM3Summary);

    CandidateWorst = [WorstIM2_dBc; WorstIM3_dBc];
    FiniteWorst = CandidateWorst(isfinite(CandidateWorst));

    if isempty(FiniteWorst)
        WorstIMD_dBc = NaN;
    else
        WorstIMD_dBc = max(FiniteWorst);
    end


    %% =================
    %% STORE IMD METRICS
    %% =================

    IMDMetrics.SamplingFrequency = ...
        ADCSamplingFrequency;
    % Retain the original field for compatibility with existing ADC code.
    IMDMetrics.ADCSamplingFrequency = ...
        ADCSamplingFrequency;
    IMDMetrics.FrequencyResolution = ...
        FrequencyResolution;
    IMDMetrics.ReferenceToneLevel_dBV = ...
        ReferenceToneLevel_dBV;
    IMDMetrics.ToneSummary = ...
        ToneSummary;
    IMDMetrics.IM2Summary = ...
        IM2Summary;
    IMDMetrics.IM3Summary = ...
        IM3Summary;
    IMDMetrics.WorstIM2_dBc = ...
        WorstIM2_dBc;
    IMDMetrics.WorstIM3_dBc = ...
        WorstIM3_dBc;
    IMDMetrics.WorstIMD_dBc = ...
        WorstIMD_dBc;
end


function [MeasuredFrequency, PeakMagnitude] = ...
        LocalMeasurePeak(Frequency, Magnitude, TargetFrequency, SearchHalfWidth)
%% Measure the strongest FFT bin in a local frequency interval.

    SearchMask = ...
        abs(Frequency - TargetFrequency) <= SearchHalfWidth;

    if ~any(SearchMask)
        error("MeasureADCIntermodulationPerformance:EmptySearchBand", ...
            "No FFT bins lie inside an intermodulation search band.");
    end

    CandidateIndices = find(SearchMask);
    [PeakMagnitude, LocalIndex] = max(Magnitude(SearchMask));
    MeasuredFrequency = Frequency(CandidateIndices(LocalIndex));
end


function ObservedFrequency = ...
        LocalFoldToFirstNyquist(InputFrequency, SamplingFrequency)
%% Fold continuous-frequency products into the sampled first Nyquist zone.

    FoldedFrequency = mod(InputFrequency, SamplingFrequency);
    NyquistFrequency = SamplingFrequency / 2;

    AboveNyquist = FoldedFrequency > NyquistFrequency;
    FoldedFrequency(AboveNyquist) = ...
        SamplingFrequency - FoldedFrequency(AboveNyquist);

    ObservedFrequency = abs(FoldedFrequency);
end


function [UnaliasedFrequency, ObservedFrequency, Expression] = ...
        LocalCleanProducts( ...
        UnaliasedFrequency, ObservedFrequency, Expression, ...
        ToneFrequencies, Tolerance)
%% Remove products that cannot be distinguished from DC or desired carriers.

    KeepMask = ObservedFrequency > Tolerance;

    for k = 1:numel(ToneFrequencies)
        KeepMask = KeepMask & ...
            abs(ObservedFrequency - ToneFrequencies(k)) > Tolerance;
    end

    UnaliasedFrequency = UnaliasedFrequency(KeepMask);
    ObservedFrequency = ObservedFrequency(KeepMask);
    Expression = Expression(KeepMask);

    if isempty(ObservedFrequency)
        return
    end

    [ObservedFrequency, SortIndex] = sort(ObservedFrequency);
    UnaliasedFrequency = UnaliasedFrequency(SortIndex);
    Expression = Expression(SortIndex);

    UniqueMask = true(size(ObservedFrequency));
    for k = 2:numel(ObservedFrequency)
        if abs(ObservedFrequency(k) - ObservedFrequency(k-1)) <= Tolerance
            UniqueMask(k) = false;
        end
    end

    UnaliasedFrequency = UnaliasedFrequency(UniqueMask);
    ObservedFrequency = ObservedFrequency(UniqueMask);
    Expression = Expression(UniqueMask);
end


function ProductSummary = ...
        LocalMeasureProducts( ...
        Order, Expression, UnaliasedFrequency, ObservedFrequency, ...
        Frequency, Magnitude, SearchHalfWidth, ReferenceToneLevel_dBV)
%% Measure all retained products and express them relative to strongest tone.

    NumberProducts = numel(ObservedFrequency);

    if NumberProducts == 0
        ProductSummary = table( ...
            zeros(0,1), ...
            strings(0,1), ...
            zeros(0,1), ...
            zeros(0,1), ...
            zeros(0,1), ...
            zeros(0,1), ...
            zeros(0,1), ...
            'VariableNames', { ...
                'Order', ...
                'Product', ...
                'UnaliasedFrequency_Hz', ...
                'ObservedTargetFrequency_Hz', ...
                'MeasuredFrequency_Hz', ...
                'Level_dBV', ...
                'RelativeToStrongestTone_dBc'});
        return
    end

    MeasuredFrequency = zeros(NumberProducts, 1);
    ProductMagnitude = zeros(NumberProducts, 1);

    for k = 1:NumberProducts
        [MeasuredFrequency(k), ProductMagnitude(k)] = ...
            LocalMeasurePeak( ...
                Frequency, ...
                Magnitude, ...
                ObservedFrequency(k), ...
                SearchHalfWidth);
    end

    ProductLevel_dBV = ...
        20 * log10(max(ProductMagnitude, realmin("double")));

    RelativeLevel_dBc = ...
        ProductLevel_dBV - ReferenceToneLevel_dBV;

    ProductSummary = table( ...
        repmat(Order, NumberProducts, 1), ...
        Expression, ...
        UnaliasedFrequency, ...
        ObservedFrequency, ...
        MeasuredFrequency, ...
        ProductLevel_dBV, ...
        RelativeLevel_dBc, ...
        'VariableNames', { ...
            'Order', ...
            'Product', ...
            'UnaliasedFrequency_Hz', ...
            'ObservedTargetFrequency_Hz', ...
            'MeasuredFrequency_Hz', ...
            'Level_dBV', ...
            'RelativeToStrongestTone_dBc'});
end


function WorstRelativeLevel = LocalWorstRelativeLevel(ProductSummary)
%% Return the strongest retained intermodulation product in dBc.

    if isempty(ProductSummary)
        WorstRelativeLevel = NaN;
        return
    end

    WorstRelativeLevel = ...
        max(ProductSummary.RelativeToStrongestTone_dBc);
end
