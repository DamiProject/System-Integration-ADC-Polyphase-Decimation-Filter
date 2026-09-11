classdef SpectrumAnalyzer < handle
    %% ===========================
    %% FREQUENCY SPECTRUM ANALYZER
    %% ===========================
    properties
        Parameters
    end

    properties (SetAccess = private)
        SamplingFrequency
    end

    methods
        function obj = SpectrumAnalyzer(P, SamplingFrequency)
            %% ===============================================
            %% FREQUENCY SPECTRUM ANALYZER INSTANCE CONSTRUCTOR
            %% ===============================================
            obj.Parameters = P;

            % Preserve the original behavior when no separate
            % stage sampling frequency is supplied.
            if nargin < 2 || isempty(SamplingFrequency)
                SamplingFrequency = P.getValue("Fs");
            end

            validateattributes( ...
                SamplingFrequency, ...
                {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'}, ...
                mfilename, ...
                'SamplingFrequency');

            obj.SamplingFrequency = double(SamplingFrequency);
        end

        function [SigFreq, SigMag] = RectFFT(obj, Input)
           %% =============================================================
           %% RECTANGULAR-WINDOW SINGLE-SIDED MAGNITUDE SPECTRUM ANALYZER
           %% =============================================================
            
            % Force the time-domain input signal into a column vector
            Input = Input(:); 
            
            % Number of samples in the input signal
            L = numel(Input); 
         
            N = obj.Parameters.getValue("N"); % FFT Length

            % Ensure the FFT does not truncate the input signal
            if N < L
                error("FFT length N must be greater than or " + ...
                    "equal to the input signal length.");
            end
            
            % Compute the N-point discrete Fourier transform of the 
            % input signal 
            Input = fft(Input, N); 
            
            % Normalize the FFT magnitude by the input signal length
            SigMag = abs(Input/L);
            
            % Retain the non-negative frequency bins for the 
            % single-sided spectrum
            SigMag = SigMag(1:floor(N/2)+1);

            % Double the non-DC and non-Nyquist bins to 
            % preserve single-sided amplitude
            if rem(N,2) == 0
                SigMag(2:end-1) = ...
                    2*SigMag(2:end-1);
            else
                SigMag(2:end) = ...
                    2*SigMag(2:end);
            end

            Fs = obj.SamplingFrequency; % Sampling Frequency

            % Construct the single-sided frequency-bin vector in Hz
            SigFreq= Fs*(0:floor(N/2))'/N; 
        end

        function [SigFreq, SigMag] = HammingFFT(obj, Input)
            %% =======================================================
            %% HAMMING-WINDOW SINGLE-SIDED MAGNITUDE SPECTRUM ANALYZER
            %% =======================================================

            % Force the time-domain input signal into a column vector
            Input = Input(:);

            % Number of samples in the input signal and Hamming window
            L = numel(Input);

            % A Hamming window requires at least one input sample
            if L == 0
                error("Input signal must contain at least one sample.");
            end

            N = obj.Parameters.getValue("N"); % FFT Length

            % Ensure the FFT does not truncate the input signal
            if N < L
                error("FFT length N must be greater than or " + ...
                    "equal to the input signal length.");
            end

            % Generate the symmetric Hamming window from its definition
            if L == 1
                HammingWindow = 1;
            else
                n = (0:L-1)';
                HammingWindow = 0.54 - ...
                    0.46*cos(2*pi*n/(L-1));
            end

            % Apply the Hamming window sample by sample
            WindowedInput = Input.*HammingWindow;

            % Compute the N-point discrete Fourier transform of the
            % windowed input signal
            WindowedSpectrum = fft(WindowedInput, N);

            % Normalize by the window sum to compensate for the
            % Hamming window's coherent gain
            SigMag = abs(WindowedSpectrum/sum(HammingWindow));

            % Retain the non-negative frequency bins for the
            % single-sided spectrum
            SigMag = SigMag(1:floor(N/2)+1);

            % Double the non-DC and non-Nyquist bins to
            % preserve single-sided amplitude
            if rem(N,2) == 0
                SigMag(2:end-1) = ...
                    2*SigMag(2:end-1);
            else
                SigMag(2:end) = ...
                    2*SigMag(2:end);
            end

            Fs = obj.SamplingFrequency; % Sampling Frequency

            % Construct the single-sided frequency-bin vector in Hz
            SigFreq = Fs*(0:floor(N/2))'/N;
        end

        function [STFTSpectrum, STFTFreq, STFTTime] = ...
                HammingSTFT(obj, Input)
            %% =====================================================
            %% HAMMING-WINDOW ONE-SIDED SHORT-TIME FOURIER TRANSFORM
            %% =====================================================

            % Force the complete time-domain signal into a column vector
            Input = Input(:);

            % Number of samples in the complete input signal
            InputLength = numel(Input);

            Fs = obj.SamplingFrequency;
            WindowLength = ...
                obj.Parameters.getValue("STFTWindowLength");
            OverlapLength = ...
                obj.Parameters.getValue("STFTOverlapLength");
            FFTLength = ...
                obj.Parameters.getValue("STFTFFTLength");

            % Ensure at least one complete STFT analysis window is present
            if InputLength < WindowLength
                error("Input signal length must be greater than or " + ...
                    "equal to STFTWindowLength.");
            end

            % Adjacent windows must advance by at least one sample
            if OverlapLength >= WindowLength
                error("STFTOverlapLength must be less than " + ...
                    "STFTWindowLength.");
            end

            % Prevent truncation of each windowed signal segment
            if FFTLength < WindowLength
                error("STFTFFTLength must be greater than or " + ...
                    "equal to STFTWindowLength.");
            end

            % A one-sided spectrum is valid only for real-valued signals
            if ~isreal(Input)
                error("The one-sided STFT requires a real-valued " + ...
                    "input signal.");
            end

            % Generate a periodic Hamming window for spectral analysis
            HammingWindow = hamming(WindowLength, "periodic");

            % Divide the complete signal into overlapping windows and
            % calculate the complex one-sided STFT of every window
            [STFTSpectrum, STFTFreq, STFTTime] = stft( ...
                Input, Fs, ...
                Window=HammingWindow, ...
                OverlapLength=OverlapLength, ...
                FFTLength=FFTLength, ...
                FrequencyRange="onesided");
        end

        function [PSDFreq, PSD] = HammingPSD(obj, Input)
            %% =====================================================
            %% HAMMING-WINDOW WELCH POWER SPECTRAL DENSITY ESTIMATOR
            %% =====================================================

            % Force the complete time-domain signal into a column vector
            Input = Input(:);

            % Number of samples in the complete input signal
            InputLength = numel(Input);

            Fs = obj.SamplingFrequency;
            WindowLength = ...
                obj.Parameters.getValue("PSDWindowLength");
            OverlapLength = ...
                obj.Parameters.getValue("PSDOverlapLength");
            FFTLength = ...
                obj.Parameters.getValue("PSDFFTLength");

            % Ensure at least one complete Welch analysis segment is present
            if InputLength < WindowLength
                error("Input signal length must be greater than or " + ...
                    "equal to PSDWindowLength.");
            end

            % Adjacent Welch segments must advance by at least one sample
            if OverlapLength >= WindowLength
                error("PSDOverlapLength must be less than " + ...
                    "PSDWindowLength.");
            end

            % Prevent truncation of each windowed Welch segment
            if FFTLength < WindowLength
                error("PSDFFTLength must be greater than or " + ...
                    "equal to PSDWindowLength.");
            end

            % A one-sided PSD is valid only for real-valued signals
            if ~isreal(Input)
                error("The one-sided PSD requires a real-valued " + ...
                    "input signal.");
            end

            % Generate a periodic Hamming window for Welch PSD estimation
            HammingWindow = hamming(WindowLength, "periodic");

            % Estimate the one-sided power spectral density using Welch's
            % method. PSD is returned in power/Hz (for example, V^2/Hz).
            [PSD, PSDFreq] = pwelch( ...
                Input, ...
                HammingWindow, ...
                OverlapLength, ...
                FFTLength, ...
                Fs, ...
                "onesided");
        end

        function [SigFreq, SigPhase] = PhaseSpectrum( ...
                obj, Input, PhaseMode, WindowType)
            %% =========================================================
            %% ONE-SIDED WRAPPED/UNWRAPPED SIGNAL PHASE SPECTRUM ANALYZER
            %% =========================================================

            % Force the complete time-domain signal into a column vector
            Input = Input(:);

            % Number of samples in the input signal
            L = numel(Input);

            if L == 0
                error("Input signal must contain at least one sample.");
            end

            % A one-sided phase spectrum is defined here for real signals
            if ~isreal(Input)
                error("The one-sided phase spectrum requires a " + ...
                    "real-valued input signal.");
            end

            % Default to wrapped phase and a Hamming analysis window
            if nargin < 3 || isempty(PhaseMode)
                PhaseMode = "wrapped";
            end

            if nargin < 4 || isempty(WindowType)
                WindowType = "hamming";
            end

            PhaseMode = lower(string(PhaseMode));
            WindowType = lower(string(WindowType));

            % Validate the requested phase representation
            if ~ismember(PhaseMode, ["wrapped", "unwrapped"])
                error("PhaseMode must be either ""wrapped"" or " + ...
                    """unwrapped"".");
            end

            % Select the analysis window
            switch WindowType
                case "rectangular"
                    AnalysisInput = Input;

                case "hamming"
                    if L == 1
                        HammingWindow = 1;
                    else
                        n = (0:L-1)';
                        HammingWindow = 0.54 - ...
                            0.46*cos(2*pi*n/(L-1));
                    end

                    AnalysisInput = Input .* HammingWindow;

                otherwise
                    error("WindowType must be either ""rectangular"" " + ...
                        "or ""hamming"".");
            end

            N = obj.Parameters.getValue("N"); % FFT Length

            % Ensure the FFT does not truncate the input signal
            if N < L
                error("FFT length N must be greater than or " + ...
                    "equal to the input signal length.");
            end

            % Compute the N-point complex spectrum
            ComplexSpectrum = fft(AnalysisInput, N);

            % Retain the non-negative frequency bins
            ComplexSpectrum = ...
                ComplexSpectrum(1:floor(N/2)+1);

            % Extract the wrapped phase angle in radians
            SigPhase = angle(ComplexSpectrum);

            % Remove +/-pi discontinuities when unwrapped phase is requested
            if PhaseMode == "unwrapped"
                SigPhase = unwrap(SigPhase);
            end

            Fs = obj.SamplingFrequency; % Sampling Frequency

            % Construct the one-sided frequency-bin vector in Hz
            SigFreq = Fs*(0:floor(N/2))'/N;
        end

        function Results = MeasureComponentPowerAmplitude( obj, Pxx, F, ...
                WelchWindowLength, TargetFrequencies, TargetNames)
            % ============================================================
            % MeasureComponentPowerAmplitude
            %
            % Measures the power and corresponding amplitude of known
            % sinusoidal components from a Welch PSD.
            %
            % Pxx               : One-sided PSD [V^2/Hz]
            % F                 : Frequency vector [Hz]
            % WelchWindowLength : Length of Hamming window used by pwelch
            % TargetFrequencies : Frequencies to measure [Hz]
            % TargetNames       : Names of components
            %
            % ============================================================

            Pxx = Pxx(:);
            F   = F(:);

            Fs = obj.SamplingFrequency;

            if any(TargetFrequencies < 0) || ...
                    any(TargetFrequencies > Fs/2)

                error( ...
                    "Target frequencies must lie between DC and Nyquist.");

            end

            TargetFrequencies = TargetFrequencies(:);

            NumComponents = numel(TargetFrequencies);

            if numel(TargetNames) ~= NumComponents
                error(['TargetNames and TargetFrequencies must have ' ...
                    'the same number of elements.']);
            end

            % ------------------------------
            % PSD frequency-bin spacing
            % ------------------------------

            dF = F(2) - F(1);

            % ------------------------------------------------------------
            % Hamming-window main-lobe width
            %
            % Null-to-null width is approximately:
            %
            %       4*Fs / WelchWindowLength
            %
            % Therefore integrate approximately +/- 2*Fs/L
            % around each component.
            % ------------------------------------------------------------

            HalfMainLobeWidth = ...
                2 * Fs / WelchWindowLength;

            % ------------------------------------------------------------
            % Verify that requested components can be independently
            % resolved by the current Hamming-Welch analysis window
            % ------------------------------------------------------------

            MainLobeWidth = ...
                2 * HalfMainLobeWidth;

            SortedFrequencies = ...
                sort(TargetFrequencies);

            if numel(SortedFrequencies) > 1

                FrequencySeparations = ...
                    diff(SortedFrequencies);

                if any(FrequencySeparations < MainLobeWidth)

                    error( ...
                        "Target components are too closely spaced for " + ...
                        "independent power measurement with the current " + ...
                        "PSDWindowLength. Increase the Welch window length.");

                end
            end

            % ------------------------------------------------------------
            % Output storage
            % ------------------------------------------------------------

            ComponentPower = zeros(NumComponents,1);
            NoisePower     = zeros(NumComponents,1);
            RMSAmplitude   = zeros(NumComponents,1);
            EquivalentPeakAmplitude  = zeros(NumComponents,1);

            MeasuredFrequency = zeros(NumComponents,1);

            % ============================================================
            % COMPONENT-BY-COMPONENT MEASUREMENT
            % ============================================================

            for k = 1:NumComponents

                TargetFrequency = TargetFrequencies(k);

                % --------------------------------------------------------
                % Tone integration region
                % --------------------------------------------------------

                ToneMask = ...
                    abs(F - TargetFrequency) <= HalfMainLobeWidth;

                ToneIndices = find(ToneMask);

                [~, LocalPeakIndex] = ...
                    max(Pxx(ToneMask));

                PeakIndex = ...
                    ToneIndices(LocalPeakIndex);

                MeasuredFrequency(k) = ...
                    F(PeakIndex);

                % --------------------------------------------------------
                % Noise estimation region
                %
                % Use neighboring PSD bins outside the Hamming main lobe.
                % --------------------------------------------------------

                NoiseInnerEdge = ...
                    1.5 * HalfMainLobeWidth;

                NoiseOuterEdge = ...
                    3.0 * HalfMainLobeWidth;

                LeftNoiseMask = ...
                    F >= (TargetFrequency - NoiseOuterEdge) & ...
                    F <= (TargetFrequency - NoiseInnerEdge);

                RightNoiseMask = ...
                    F >= (TargetFrequency + NoiseInnerEdge) & ...
                    F <= (TargetFrequency + NoiseOuterEdge);

                NoiseMask = LeftNoiseMask | RightNoiseMask;

                % --------------------------------------------------------
                % Prevent another known component from contaminating
                % the local noise estimate
                % --------------------------------------------------------

                for m = 1:NumComponents

                    if m ~= k

                        OtherFrequency = TargetFrequencies(m);

                        OtherToneMask = ...
                            abs(F - OtherFrequency) <= ...
                            HalfMainLobeWidth;

                        NoiseMask(OtherToneMask) = false;

                    end
                end

                % --------------------------------------------------------
                % Total measured power around tone
                % --------------------------------------------------------

                MeasuredBandPower = ...
                    sum(Pxx(ToneMask)) * dF;


                % --------------------------------------------------------
                % Local noise PSD estimate
                % --------------------------------------------------------

                if any(NoiseMask)

                    LocalNoisePSD = ...
                        mean(Pxx(NoiseMask));

                else

                    LocalNoisePSD = 0;

                end

                % --------------------------------------------------------
                % Noise power contained inside tone bandwidth
                % --------------------------------------------------------

                ToneBandwidth = ...
                    sum(ToneMask) * dF;

                NoisePower(k) = ...
                    LocalNoisePSD * ToneBandwidth;

                % --------------------------------------------------------
                % Noise-corrected component power
                % --------------------------------------------------------

                ComponentPower(k) = ...
                    max(MeasuredBandPower - NoisePower(k), 0);

                % --------------------------------------------------------
                % Convert component power to RMS amplitude
                %
                % Since integrated PSD gives mean-square voltage:
                %
                %       P = Vrms^2
                % --------------------------------------------------------

                RMSAmplitude(k) = ...
                    sqrt(ComponentPower(k));

                % --------------------------------------------------------
                % Convert RMS amplitude to peak amplitude
                %
                % Sinusoid:
                %
                %       Apeak = sqrt(2) * Vrms
                %
                % DC is different:
                %
                %       ADC = Vrms
                % --------------------------------------------------------

                if TargetFrequency == 0

                    EquivalentPeakAmplitude(k) = ...
                        RMSAmplitude(k);

                else

                    EquivalentPeakAmplitude(k) = ...
                        sqrt(2) * RMSAmplitude(k);

                end

            end

            % ============================================================
            % RETURN RESULTS
            % ============================================================

            Results = table( ...
                string(TargetNames(:)), ...
                TargetFrequencies, ...
                MeasuredFrequency, ...
                ComponentPower, ...
                NoisePower, ...
                RMSAmplitude, ...
                EquivalentPeakAmplitude, ...
                'VariableNames', ...
                { ...
                'Component', ...
                'DetectedFrequency_Hz', ...
                'MeasuredFrequency_Hz', ...
                'ComponentPower_V2', ...
                'NoisePower_V2', ...
                'RMSAmplitude_V', ...
                'EquivalentPeakAmplitude_V' ...
                });
        end

        function Results = MeasureSTFTMaximumAmplitude( ...
        obj, STFTSpectrum, STFTFreq, STFTTime, ...
        TargetFrequencies, TargetNames)

            % ============================================================
            % MeasureSTFTMaximumAmplitude
            %
            % Measures the maximum time-localized amplitude of known
            % deterministic components from the Hamming STFT.
            %
            % STFTSpectrum     : Complex one-sided STFT matrix
            % STFTFreq         : STFT frequency vector [Hz]
            % STFTTime         : STFT time vector [s]
            % TargetFrequencies: Frequencies already identified by analysis [Hz]
            % TargetNames      : Component names
            %
            % ============================================================

            Fs = obj.SamplingFrequency;

            WindowLength = ...
                obj.Parameters.getValue("STFTWindowLength");


            % ------------------------------------------------------------
            % Hamming window used by HammingSTFT
            % ------------------------------------------------------------

            HammingWindow = ...
                hamming(WindowLength, "periodic");

            WindowSum = ...
                sum(HammingWindow);

            STFTFreq = STFTFreq(:);
            STFTTime = STFTTime(:);

            TargetFrequencies = ...
                TargetFrequencies(:);

            NumComponents = ...
                numel(TargetFrequencies);

            if numel(TargetNames) ~= NumComponents

                error( ...
                    "TargetNames and TargetFrequencies must have " + ...
                    "the same number of elements.");

            end

            % ------------------------------------------------------------
            % Frequency validity
            % ------------------------------------------------------------

            if any(TargetFrequencies < 0) || ...
                    any(TargetFrequencies > Fs/2)

                error( ...
                    "Target frequencies must lie between DC and Nyquist.");

            end

            % ------------------------------------------------------------
            % Storage
            % ------------------------------------------------------------

            MeasuredFrequency = ...
                zeros(NumComponents, 1);

            MaximumLocalAmplitude = ...
                zeros(NumComponents, 1);

            TimeOfMaximum = ...
                zeros(NumComponents, 1);

            MaximumFrameIndex = ...
                zeros(NumComponents, 1);

            % ============================================================
            % COMPONENT-BY-COMPONENT STFT AMPLITUDE MEASUREMENT
            % ============================================================

            for k = 1:NumComponents

                TargetFrequency = ...
                    TargetFrequencies(k);


                % --------------------------------------------------------
                % Locate STFT frequency bin nearest the previously
                % identified component frequency.
                % --------------------------------------------------------

                [~, FrequencyBinIndex] = ...
                    min(abs(STFTFreq - TargetFrequency));

                MeasuredFrequency(k) = ...
                    STFTFreq(FrequencyBinIndex);


                % --------------------------------------------------------
                % Correct STFT magnitude for Hamming-window coherent gain
                % --------------------------------------------------------

                LocalAmplitude = ...
                    abs(STFTSpectrum(FrequencyBinIndex, :)) / ...
                    WindowSum;


                % --------------------------------------------------------
                % Convert two-sided sinusoidal amplitude to one-sided
                % amplitude.
                %
                % DC and Nyquist are not doubled.
                % --------------------------------------------------------

                if MeasuredFrequency(k) > 0 && ...
                        MeasuredFrequency(k) < Fs/2

                    LocalAmplitude = ...
                        2 * LocalAmplitude;

                end

                % --------------------------------------------------------
                % Maximum amplitude over all STFT time frames
                % --------------------------------------------------------

                [MaximumLocalAmplitude(k), MaximumFrameIndex(k)] = ...
                    max(LocalAmplitude);

                TimeOfMaximum(k) = ...
                    STFTTime(MaximumFrameIndex(k));

            end


            % ============================================================
            % RESULTS
            % ============================================================

            Results = table( ...
                string(TargetNames(:)), ...
                TargetFrequencies, ...
                MeasuredFrequency, ...
                MaximumLocalAmplitude, ...
                TimeOfMaximum, ...
                MaximumFrameIndex, ...
                'VariableNames', { ...
                'Component', ...
                'TargetFrequency_Hz', ...
                'MeasuredFrequency_Hz', ...
                'MaximumLocalAmplitude_V', ...
                'TimeOfMaximum_s', ...
                'STFTFrameIndex' ...
                });
           end              
      end
 end