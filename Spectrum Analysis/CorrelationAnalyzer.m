classdef CorrelationAnalyzer < handle
    %% =======================================================
    %% CORRELATION ANALYZER
    %% =======================================================
    % Performs lag-domain correlation analysis and converts correlation
    % sequences to the frequency domain.
    %
    % Autocorrelation:
    %   Examines similarity between a signal and delayed versions of itself.
    %
    % Cross-correlation:
    %   Examines similarity between an observed signal and a known reference.
    %
    % CorrelationSpectrum:
    % Uses the Fourier-transform relationship between correlation and
    % spectral power. For autocorrelation this is the Wiener-Khinchin
    % relationship; for cross-correlation this produces the cross spectrum.

    properties (SetAccess = private)
        Parameters
        SamplingFrequency
    end

    methods
        %% ==========================================
        %% CONSTRUCTOR
        %% ==========================================
        function obj = CorrelationAnalyzer(P, SamplingFrequency)

            if nargin < 1
                P = [];
            end

            obj.Parameters = P;

            if nargin >= 2 && ~isempty(SamplingFrequency)

                validateattributes( ...
                    SamplingFrequency, ...
                    {'numeric'}, ...
                    {'scalar', 'real', 'finite', 'positive'});

                obj.SamplingFrequency = SamplingFrequency;

            elseif ~isempty(P)

                obj.SamplingFrequency = ...
                    P.getValue("Fs");

            else

                obj.SamplingFrequency = [];

            end
        end


        %% ==========================================
        %% AUTOCORRELATION
        %% ==========================================
        function [Correlation, Lags, LagTime] = ...
                AutoCorrelation(obj, Signal, MaxLag, Normalization)

            Signal = Signal(:);

            if isempty(Signal)
                error( ...
                    "CorrelationAnalyzer:EmptySignal", ...
                    "Signal must not be empty.");
            end

            if nargin < 3 || isempty(MaxLag)
                MaxLag = length(Signal) - 1;
            end

            if nargin < 4 || isempty(Normalization)
                Normalization = "coeff";
            end

            validateattributes( ...
                MaxLag, ...
                {'numeric'}, ...
                {'scalar', 'integer', 'nonnegative'});

            if MaxLag >= length(Signal)
                error( ...
                    "CorrelationAnalyzer:InvalidMaxLag", ...
                    "MaxLag must be smaller than the signal length.");
            end

            obj.ValidateNormalization(Normalization);

            [Correlation, Lags] = ...
                xcorr( ...
                    Signal, ...
                    MaxLag, ...
                    Normalization);

            LagTime = obj.ConvertLagToTime(Lags);
        end


        %% ==========================================
        %% CROSS-CORRELATION
        %% ==========================================
        function [Correlation, Lags, LagTime, ...
                PeakCorrelation, DetectedLag, DetectedDelay] = ...
                CrossCorrelation( ...
                    obj, ...
                    ObservedSignal, ...
                    ReferenceSignal, ...
                    MaxLag, ...
                    Normalization)

            ObservedSignal = ObservedSignal(:);
            ReferenceSignal = ReferenceSignal(:);

            if isempty(ObservedSignal) || isempty(ReferenceSignal)
                error( ...
                    "CorrelationAnalyzer:EmptySignal", ...
                    "ObservedSignal and ReferenceSignal must not be empty.");
            end

            MaximumAvailableLag = ...
                max(length(ObservedSignal), ...
                    length(ReferenceSignal)) - 1;

            if nargin < 4 || isempty(MaxLag)
                MaxLag = MaximumAvailableLag;
            end

            if nargin < 5 || isempty(Normalization)
                Normalization = "coeff";
            end

            validateattributes( ...
                MaxLag, ...
                {'numeric'}, ...
                {'scalar', 'integer', 'nonnegative'});

            if MaxLag > MaximumAvailableLag
                error( ...
                    "CorrelationAnalyzer:InvalidMaxLag", ...
                    "MaxLag exceeds the available correlation lag.");
            end

            obj.ValidateNormalization(Normalization);

            [Correlation, Lags] = ...
                xcorr( ...
                    ObservedSignal, ...
                    ReferenceSignal, ...
                    MaxLag, ...
                    Normalization);

            LagTime = obj.ConvertLagToTime(Lags);

            [~, PeakIndex] = ...
                max(abs(Correlation));

            PeakCorrelation = ...
                Correlation(PeakIndex);

            DetectedLag = ...
                Lags(PeakIndex);

            if isempty(obj.SamplingFrequency)
                DetectedDelay = [];
            else
                DetectedDelay = ...
                    DetectedLag / obj.SamplingFrequency;
            end
        end


        %% ==========================================
        %% CORRELATION SPECTRUM
        %% ==========================================
        function [Frequency, Spectrum] = ...
                CorrelationSpectrum(obj, Correlation, NFFT)

            Correlation = Correlation(:);

            if isempty(Correlation)
                error( ...
                    "CorrelationAnalyzer:EmptyCorrelation", ...
                    "Correlation must not be empty.");
            end

            if isempty(obj.SamplingFrequency)
                error( ...
                    "CorrelationAnalyzer:MissingSamplingFrequency", ...
                    "SamplingFrequency is required for the frequency axis.");
            end

            if nargin < 3 || isempty(NFFT)
                NFFT = 2^nextpow2(length(Correlation));
            end

            validateattributes( ...
                NFFT, ...
                {'numeric'}, ...
                {'scalar', 'integer', 'positive'});

            if NFFT < length(Correlation)
                error( ...
                    "CorrelationAnalyzer:InvalidNFFT", ...
                    "NFFT must be at least the correlation-sequence length.");
            end

            % xcorr() returns lags ordered from negative to positive.
            % Move zero lag to the first sample before taking the DFT.
            ZeroLagFirst = ...
                ifftshift(Correlation);

            FullSpectrum = ...
                fft(ZeroLagFirst, NFFT);

            PositiveLength = ...
                floor(NFFT / 2) + 1;

            Spectrum = ...
                FullSpectrum(1:PositiveLength);

            Frequency = ...
                (0:PositiveLength - 1)' * ...
                (obj.SamplingFrequency / NFFT);
        end
    end
    
    methods (Access = private)
        %% ==========================================
        %% CONVERT SAMPLE LAGS TO TIME
        %% ==========================================
        function LagTime = ConvertLagToTime(obj, Lags)

            if isempty(obj.SamplingFrequency)

                LagTime = [];
                return;
            end

            LagTime = ...
                Lags / obj.SamplingFrequency;
        end


        %% ==========================================
        %% VALIDATE XCORR NORMALIZATION
        %% ==========================================
        function ValidateNormalization(~, Normalization)

            ValidNormalization = [ ...
                "none", ...
                "biased", ...
                "unbiased", ...
                "coeff"];

            if ~any(string(Normalization) == ValidNormalization)
                error( ...
                    "CorrelationAnalyzer:InvalidNormalization", ...
                    "Normalization must be none, biased, unbiased, or coeff.");
            end
        end
    end
end
