function [NumberTaps, FilterOrder, HasOddTapCount, ...
    IsSymmetric, SymmetryError, FIRType, ...
    TheoreticalGroupDelaySamples] = ...
    CheckFIRStructure(FilterCoefficients, SymmetryTolerance)
%% ==============================================
%% FIR TYPE-I STRUCTURE AND SYMMETRY VERIFICATION
%% ==============================================
%
% Verifies the structural properties of the realized FIR filter.
%
% A Type-I linear-phase FIR requires:
%   1. Odd number of taps
%   2. Symmetric coefficients
%
% Inputs:
%   FilterCoefficients - realized FIR coefficient vector
%   SymmetryTolerance  - optional absolute symmetry tolerance
%
% Outputs:
%   NumberTaps
%   FilterOrder
%   HasOddTapCount
%   IsSymmetric
%   SymmetryError
%   FIRType
%   TheoreticalGroupDelaySamples

if nargin < 2 || isempty(SymmetryTolerance)
    SymmetryTolerance = 1e-12;
end

validateattributes(SymmetryTolerance, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});

%% =========================
%% VALIDATE FIR COEFFICIENTS
%% =========================

ValidCoefficients = ...
    isnumeric(FilterCoefficients) && ...
    isreal(FilterCoefficients) && ...
    isvector(FilterCoefficients) && ...
    ~isempty(FilterCoefficients) && ...
    all(isfinite(FilterCoefficients(:)));

if ~ValidCoefficients
    error('CheckFIRStructure:InvalidCoefficients', ...
        ['FilterCoefficients must be a finite real ', ...
         'numeric vector.']);
end

FilterCoefficients = ...
    FilterCoefficients(:).';

%% =========================
%% FIR LENGTH / ORDER
%% =========================

NumberTaps = ...
    numel(FilterCoefficients);

FilterOrder = ...
    NumberTaps - 1;

HasOddTapCount = ...
    mod(NumberTaps, 2) == 1;

%% =========================
%% SYMMETRY VERIFICATION
%% =========================

SymmetryError = ...
    max(abs( ...
    FilterCoefficients - ...
    fliplr(FilterCoefficients)));

IsSymmetric = ...
    SymmetryError <= SymmetryTolerance;

%% =========================
%% FIR TYPE CLASSIFICATION
%% =========================

if HasOddTapCount && IsSymmetric
    FIRType = "Type I";

    % Constant group delay for a Type-I linear-phase FIR.
    TheoreticalGroupDelaySamples = ...
        (NumberTaps - 1) / 2;
else
    FIRType = "Not Type I";
    TheoreticalGroupDelaySamples = NaN;
end

%% ============================
%% COMMAND-WINDOW SUMMARY
%% ============================

fprintf('\nFIR Structure Check\n');
fprintf('----------------------------------------\n');
fprintf('Number of taps              = %d\n', ...
    NumberTaps);
fprintf('Filter order                = %d\n', ...
    FilterOrder);

if HasOddTapCount
    fprintf('Odd tap count               = PASS\n');
else
    fprintf('Odd tap count               = FAIL\n');
end

fprintf('Maximum symmetry error      = %.6g\n', ...
    SymmetryError);

if IsSymmetric
    fprintf('Coefficient symmetry        = PASS\n');
else
    fprintf('Coefficient symmetry        = FAIL\n');
end

fprintf('FIR classification          = %s\n', ...
    FIRType);

if ~isnan(TheoreticalGroupDelaySamples)
    fprintf('Theoretical group delay     = %.6g samples\n', ...
        TheoreticalGroupDelaySamples);
else
    fprintf('Theoretical group delay     = N/A\n');
end

end
