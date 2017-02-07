% Script to map map overlay images to coordinate values

clear
close all

%% Load Data
mapname = 'plaza';
fname = ['Map Overlays\Coordinate Mapping\zack_' mapname '_deaths.json'];
[deathEvents, deathLen, players] = loadDeaths(fname);

%% Identify points corresponding to coordinates

% the_rig
% deathNames = {'Sniper Spawn','Plasma Caster Spawn','Bunker SW Corner','Plasma Caster NW Corner','Docking Stairs SW Corner'};

% fathom
% deathNames = {'Top Mid Camo','Blue BR Corner NW','Red BR Corner SE','Bottom Mid Rail'};

% Coliseum
% deathNames = {'Sniper Spawn','Rocket Spawn','Red Fountain Center','Blue Fountain Center','Blue Elbow South Corner','Red Elbow South Corner'};

% eden
% deathNames = {'Sniper Spawn','Rocket Spawn','Red Yard Security NW Corner','Blue Back Alley NE Corner','Red Basement NW Corner Above STairs'};

% plaza
% deathNames = {'Sniper Spawn', 'Ovi Spawn', 'Hotel SE Corner', 'Bottom Lift NE Corner', 'South Side Center of Café Pillar'};
deathNames = {'Sniper Spawn','Hotel SE Corner','Tram NW Corner','Cafe SW Corner','Plaza NE Corner under sneaky'};

% truth
% deathNames = {'Top Mid - Fuel Rod', 'Bottom Mid - Hydra', 'Sword Spawn', 'Invis Spawn', 'SE Side of SE Dorito between Blue base and Carbine (Blue Bend)', 'NW Side of NW Dorito next to Red Street. Mislabeled "Red Steel"'};
% deathNames = {'top mid', 'blue side bubble, back right (NW on TRUE map) corner of PILLAR in bubble', 'same for red side', 'all the way back in blue base, N on true map', 'same for red side', 'p2 frag grenades wall (E on true)', 'same for car, all the way against the furthest west wall, in the lift'};

% regret
% deathNames = {'Plasma Caster Spawn','Ovi/Bottom Mid','Blue Base Back Point','Red Base Back Point','Arch Top - Middle Point'};

mapnameF = ['Map Overlays\Images\Prima\' mapname '.jpg'];
a = imread(mapnameF);
b = im2double(a);
figure(1)
imshow(b)

%%
% deathLocs = [1190.070537	987.603167
% 903.9333013	369.3066219
% 445.7135317	1285.746161
% 793.8805182	179.2154511
% 341.6636276	1085.650192];

%%
deathLocs = zeros(length(deathNames),2); % [x, y]
for ii = 1:length(deathNames)
    disp(['Select location on map corresponding to ' deathNames{ii}])
    [deathLocs(ii,1), deathLocs(ii,2)] = ginput(1);
end

%% 
players_to_plot = 1;

% heatmaps(deathEvents,mapname,players_to_plot)

% copied and modified form heatmaps
deathsFiltered = [];
for ii = 1:length(players_to_plot)
    deathsFiltered = [deathsFiltered find(deathEvents(:,2) == players_to_plot(ii))'];
end

deathsFilteredLocs = [deathEvents(deathsFiltered,3) deathEvents(deathsFiltered,4)];

% manual_events = [2, 3]; % the only two deaths I want to look at
% Ax = b, x = A\b : coordsXY*transformCoefs = mapXY

% using all data points, second order least squares fit
coordsXY = zeros(2*length(deathsFilteredLocs),6);
mapXY = zeros(2*length(deathsFilteredLocs),1);
for ii = 1:length(deathsFilteredLocs) 
   coordsXY(2*ii-1,1:3) = [deathsFilteredLocs(ii,1)^2 deathsFilteredLocs(ii,1) 1];
   coordsXY(2*ii,4:6) = [deathsFilteredLocs(ii,2)^2 deathsFilteredLocs(ii,2) 1];
   mapXY((2*ii-1):2*ii) = [deathLocs(ii,1); deathLocs(ii,2)];
end
% coordsXY = [deathsFilteredLocs(2,1) 1 0 0; 0 0 deathsFilteredLocs(2,2) 1; deathsFilteredLocs(3,1) 1 0 0; 0 0 deathsFilteredLocs(3,2) 1];
% mapXY = [deathLocs(2,1); deathLocs(2,2); deathLocs(3,1); deathLocs(3,2)];
format longg
transformCoefs = coordsXY\mapXY

transformedCoords = [deathsFilteredLocs(:,1).^2*transformCoefs(1) + deathsFilteredLocs(:,1)*transformCoefs(2) + transformCoefs(3), deathsFilteredLocs(:,2).^2*transformCoefs(4) + deathsFilteredLocs(:,2)*transformCoefs(5) + transformCoefs(6)];
%% see if it worked
figure(1)
hold on
for ii = 1:length(deathNames)
    plot(transformedCoords(ii,1),transformedCoords(ii,2),'r.','markersize',20)
    text(transformedCoords(ii,1)+5,transformedCoords(ii,2)+5,num2str(ii),'Color','red','FontSize',28);
end