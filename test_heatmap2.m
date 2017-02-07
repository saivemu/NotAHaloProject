% test heatmap, 2

clear
close all

%% Load Data
mapname = 'plaza';
% fname = ['Map Overlays\Coordinate Mapping\zack_' mapname '_deaths.json'];
fname = 'C:\Users\Sarmad\Dropbox\Documents\OLAH\Data\test_multiple_plaza_sac_oneGameEvents.json';
[deathEvents, deathLen, players, playerDeathEvents] = loadDeaths(fname);

%% Identify points corresponding to coordinates

heatmaps(deathEvents,mapname,playerDeathEvents,{})