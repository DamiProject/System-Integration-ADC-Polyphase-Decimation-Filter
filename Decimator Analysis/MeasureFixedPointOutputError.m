function Metrics = MeasureFixedPointOutputError( ...
    FloatingOutput, FixedOutput)
%% =================================================
%% MEASURE FLOATING-VERSUS-FIXED DECIMATOR ERROR
%% =================================================
%
% FloatingOutput and FixedOutput must use the same physical scale.

    ValidateRealVector(FloatingOutput, 'FloatingOutput');
    ValidateRealVector(FixedOutput, 'FixedOutput');

    FloatingOutput = double(FloatingOutput(:));
    FixedOutput = double(FixedOutput(:));

    if numel(FloatingOutput) ~= numel(FixedOutput)
        error('MeasureFixedPointOutputError:LengthMismatch', ...
            ['FloatingOutput and FixedOutput must contain the ', ...
             'same number of samples.']);
    end

    OutputError = FixedOutput - FloatingOutput;

    ReferencePower = mean(FloatingOutput.^2);
    ErrorPower = mean(OutputError.^2);

    Metrics.NumberOutputSamples = numel(OutputError);
    Metrics.MaximumAbsoluteError = max(abs(OutputError));
    Metrics.RMSError = sqrt(ErrorPower);
    Metrics.MeanError = mean(OutputError);

    if ErrorPower == 0
        if ReferencePower == 0
            Metrics.ErrorSNRdB = NaN;
        else
            Metrics.ErrorSNRdB = Inf;
        end
    else
        Metrics.ErrorSNRdB = ...
            10 * log10(ReferencePower / ErrorPower);
    end
end

function ValidateRealVector(InputVector, VariableName)
%% ==========================================
%% VALIDATE FINITE REAL NUMERIC VECTOR
%% ==========================================

    ValidVector = ...
        isnumeric(InputVector) && ...
        isreal(InputVector) && ...
        isvector(InputVector) && ...
        ~isempty(InputVector) && ...
        all(isfinite(InputVector(:)));

    if ~ValidVector
        error('MeasureFixedPointOutputError:InvalidVector', ...
            '%s must be a finite real numeric vector.', ...
            VariableName);
    end
end
