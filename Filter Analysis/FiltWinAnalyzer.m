classdef FiltWinAnalyzer < handle
    %% =====================================================
    %% FILTER AND WINDOW VISUALIZATION / BUILT-IN ANALYSIS
    %% =====================================================
    %
    % Thin integration-side wrapper around MATLAB's:
    %   1. Filter Analyzer
    %   2. Window Visualization Tool (WVTool)
    
    methods
        function obj = FiltWinAnalyzer()
            %% ============================
            %% ANALYZER INSTANCE CONSTRUCTOR
            %% ============================
        end

        function [AnalyzerHandle, DisplayNumbers] = ...
                AnalyzeSOSFilter(~, SOS, Gain, Fs, FilterName)
            %% ============================================
            %% ANALYZE IIR / SOS FILTER IN FILTER ANALYZER
            %% ============================================

            if nargin < 5 || strlength(string(FilterName)) == 0
                FilterName = "SOS Filter";
            end

            validateattributes(SOS, {'numeric'}, ...
                {'2d', 'real', 'finite', 'nonempty'});

            if size(SOS, 2) ~= 6
                error('FiltWinAnalyzer:InvalidSOS', ...
                    'SOS must contain six columns per biquad section.');
            end

            validateattributes(Gain, {'numeric'}, ...
                {'real', 'finite', 'nonempty'});

            validateattributes(Fs, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});

            % Convert the SOS cascade, including its overall gain, into
            % cascaded transfer-function coefficients accepted by
            % Filter Analyzer.

            [B, A] = sos2ctf(SOS, Gain);

            DisplayName = string(FilterName);

            ValidFilterName = string( ...
                matlab.lang.makeValidName(char(DisplayName)));

            [AnalyzerHandle, DisplayNumbers] = filterAnalyzer( ...
                B, A, ...
                FilterNames =  ValidFilterName, ...
                LegendStrings = DisplayName, ...
                SampleRates = Fs, ...
                CTFAnalysisMode = "cumulative");
        end

        function [AnalyzerHandle, DisplayNumbers] = ...
                AnalyzeFIRFilter(~, FilterCoefficients, Fs, FilterName)
            %% ============================================
            %% ANALYZE FIR FILTER IN FILTER ANALYZER
            %% ============================================

            if nargin < 4 || strlength(string(FilterName)) == 0
                FilterName = "FIR Filter";
            end

            FiltWinAnalyzer.ValidateRealVector( ...
                FilterCoefficients, "FilterCoefficients");

            validateattributes(Fs, {'numeric'}, ...
                {'scalar', 'real', 'finite', 'positive'});

            B = double(FilterCoefficients(:).');
            A = 1;

            DisplayName = string(FilterName);

            ValidFilterName = string( ...
                matlab.lang.makeValidName(char(DisplayName)));

            [AnalyzerHandle, DisplayNumbers] = filterAnalyzer( ...
                B, A, ...
                FilterNames =   ValidFilterName, ...
                LegendStrings = DisplayName, ...
                SampleRates = Fs);
        end

        function WindowHandle = AnalyzeWindow(~, WindowVector)
            %% ==========================================
            %% ANALYZE EXISTING WINDOW VECTOR WITH WVTOOL
            %% ==========================================
            %
            % Use this for windows already created by the project.
            % Window Designer is intentionally not used.

            FiltWinAnalyzer.ValidateRealVector( ...
                WindowVector, "WindowVector");

            WindowHandle = wvtool(double(WindowVector(:)));
        end
    end

    methods (Access = private, Static)
        function ValidateRealVector(InputVector, VariableName)
            %% ==========================
            %% VALIDATE ANALYZER VECTOR
            %% ==========================

            ValidVector = ...
                isnumeric(InputVector) && ...
                isreal(InputVector) && ...
                isvector(InputVector) && ...
                ~isempty(InputVector) && ...
                all(isfinite(InputVector(:)));

            if ~ValidVector
                error('FiltWinAnalyzer:InvalidVector', ...
                    '%s must be a finite real numeric vector.', ...
                    VariableName);
            end
        end
    end
end
