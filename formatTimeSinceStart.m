% function to extract timestamp (in seconds) from the API's "ISO 8601"
% duration

function [data, foundCell] = formatTimeSinceStart(data)

% Automatically find the field that has the cell with all the entries
% instead of passing in that field name (such as GameEvents). To do this,
% list all the fields of data, then go through each one until a cell is
% found. Assuming that the first cell will contain all the infomation.

fields = fieldnames(data);

foundCell = []; % the field number of the field that is the cell
ii = 1; % the current field number

% Until the cell is found, keep searching for it
while isempty(foundCell)
    if iscell(data.(fields{ii}))
        foundCell = ii; % if you've found the cell, note its field number
    end
    ii = ii + 1;
    if ii == length(fields)
        % if you reach the point where you've gone through all the fields
        % and haven't found a cell yet, break this while loop
        break;
    end
end

if isempty(foundCell)
    % if the cell was never found, report that and don't carry out the code
    disp('No cell found.')
else
    % if the cell was found, loop over every entry of the cell and carry
    % out the conversion from the timestamp to seconds
    for ii = 1:length(data.(fields{foundCell}))
        % store their time stamp
        isoTime = data.(fields{foundCell}){ii}.TimeSinceStart;
        isoTime(1:2) = []; % the first two letters, 'PT', are useless
        
        % need to account for whether there is a minutes entry or not. If
        % there is, need to add the minutes to the calculation. If not,
        % ignore.
        
        % find the location of the minute mark. If there are no minutes,
        % then this is empty.
        mLoc = strfind(isoTime,'M');
        
        m = 0; % default value for minutes
        s = 0; % default value for seconds
                
        if ~isempty(mLoc)
            % if the minute part is there, get the value of the minutes
            m = str2num(isoTime(1:mLoc-1)); 
            % it's the first value up to the value before the 'M'
        else
            % if there is no minute part, set the location of the 'M' as 0
            % to generalize the next calculation
            mLoc = 0;
        end
        
        % convert the rest of the timestamp to seconds
        s = str2double(isoTime(mLoc+1:end-1)); 
        % note that the last value of isoTime is 'S'. Ignore.
        
        % convert the time into seconds and put it in the structure
        data.(fields{foundCell}){ii}.seconds = 60*m + s;
    end
end
        