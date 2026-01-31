function [fun,patchGrid] = MatchStandardFun(type)
%Matches a standard type with its associated measurement function & grid size
%   
%   Sandra Winters <sandra.winters@colorado.edu>
%   updated 27 Jan 2025

if strcmpi(type,'macbeth')
    fun = 'MeasureMacbeth';
    patchGrid = [6 4];
elseif strcmpi(type,'jolyon')
    fun = 'MeasureJolyonStandard';
    patchGrid = [2 1];
elseif strcmpi(type,'aviantech')
    fun = 'MeasureAvianTechStandard';
    patchGrid = [4 2];
elseif strcmpi(type,'nanomacbeth')
    fun = 'MeasureNanoMacbeth';
    patchGrid = [6 4];
else
    error('standard type not recognized')
end

end %function