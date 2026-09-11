classdef DecimatorAnalyzer < handle
    %% ==========================================
    %% POLYPHASE DECIMATOR DESIGN CHARACTERIZATION
    %% ==========================================
    %
    % This analyzer answers two implementation questions:
    %
    %   1. Why are the selected fixed-point formats numerically suitable?
    %   2. What computation and storage tradeoffs result from using the
    %      polyphase decimator architecture?
    %
    % Functional correctness, filter-response measurements, and signal-
    % domain demonstrations remain owned by the project tests,
    % FiltWinAnalyzer, and the system demonstration respectively.

    properties (SetAccess = private)
        Parameters
    end

    methods
        function obj = DecimatorAnalyzer(P)
            %% =============================
            %% ANALYZER INSTANCE CONSTRUCTOR
            %% =============================

            if nargin < 1 || isempty(P) || ...
                    ~isobject(P) || ...
                    ~ismethod(P, 'getValue')

                error('DecimatorAnalyzer:InvalidParameters', ...
                    ['P must be a parameter object that provides ', ...
                     'the getValue method.']);
            end

            obj.Parameters = P;
        end

        function Metrics = CharacterizeFixedPointDesign( ...
                obj, FloatingOutput, FixedOutput, FixedDecimator, ...
                InputFormat, MACFormat, MACData)
            %% =========================================
            %% CHARACTERIZE FIXED-POINT DESIGN DECISIONS
            %% =========================================
            %
            % FloatingOutput and FixedOutput must already use the same
            % physical scale. For the ADC integration path, multiply the
            % FixedToRealConverter output by the ADC voltage step before
            % calling this method.

            Metrics = MeasureFixedPointDesign( ...
                FloatingOutput, ...
                FixedOutput, ...
                FixedDecimator, ...
                InputFormat, ...
                MACFormat, ...
                MACData, ...
                obj.Parameters);
        end

        function Metrics = CharacterizePolyphaseArchitecture( ...
                obj, Decimator)
            %% ==========================================
            %% CHARACTERIZE POLYPHASE IMPLEMENTATION COST
            %% ==========================================

            Metrics = MeasurePolyphaseArchitecture( ...
                Decimator, obj.Parameters);
        end
    end
end
