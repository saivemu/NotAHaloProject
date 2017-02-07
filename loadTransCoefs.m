% Function to read the transformCoefs from a data file
% Data file written as tab-delimted, header with map name, transformCoefs
% in columns under their map

function transformCoefs = loadTransCoefs(mapname)

filePath = 'C:\Users\Sarmad\Dropbox\Documents\OLAH\Map Overlays\Coordinate Mapping\transformCoefs_2ndOrder.dat';

fid = fopen(filePath,'r');
if fid == -1
    error('transformCoefs file not found.')
end

headerLine = fgetl(fid);
header = strsplit(headerLine,'\t');

mapInd = strcmp(header,mapname);
if isempty(mapInd)
    error(['No data for ' mapname '.'])
end

formatSpec = repmat('%f',1,length(header));
allData = textscan(fid,formatSpec,'Delimiter','\t');

transformCoefs = allData{mapInd};