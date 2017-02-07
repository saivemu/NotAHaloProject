% Test basic heatmap

% I've added the jsonlab folder to the default MATLAB path
clear all
close all

% fname = 'Map Overlays\Coordinate Mapping\zack_rig_deaths.json';
fname = 'Data\test2_stripped.json';

data = loadjson(fname);

[data, foundCell] = formatTimeSinceStart(data);
% foundCell is the cell # with all the events

% parse data and simultaneously assign death events to players

% not using any a priori information about players in the game, will
% instead just look for death events and add to the player list as we go
% along and encounter new players
% THIS WON'T WORK IF A PLAYER DOESN'T DIE, but it could work if we look
% for something else first (ie player spawns). Or could just go super
% official and use the match info data set

fields = fieldnames(data);
dataLen = length(data.(fields{foundCell}));

events = cell(dataLen,1);

for ii = 1:dataLen
    events{ii} = data.(fields{foundCell}){ii}.EventName;
end

deathEvents = find(strcmp('Death',events));

deathLen = length(deathEvents);
players = cell(1,8);
playersFound = 0;
deathEvents = [deathEvents zeros(deathLen,4)];
% rows correspond to entry in the data field that is a death, columns
% correspond to the player in players whose death it is, and then the x, y,
% and z coordinate of death

for ii = 1:deathLen
    % for some reason, sometimes the victim comes back as empty, with no
    % gamertag field. Idk what's going on there, but for the sake of the
    % code, skip this case. Keep an eye out for this stuff.
    if ~isempty(data.(fields{foundCell}){deathEvents(ii,1)}.Victim)
        playername = data.(fields{foundCell}){deathEvents(ii,1)}.Victim.Gamertag;
        
        % check against player names
        playerNum = find(strcmp(playername, players));
        if isempty(playerNum)
            playersFound = playersFound + 1;
            players{playersFound} = playername;
            playerNum = playersFound;
        end
        
        deathEvents(ii,2) = playerNum;
        
        deathEvents(ii,3) = data.(fields{foundCell}){deathEvents(ii,1)}.VictimWorldLocation.x;
        deathEvents(ii,4) = data.(fields{foundCell}){deathEvents(ii,1)}.VictimWorldLocation.y;
        deathEvents(ii,5) = data.(fields{foundCell}){deathEvents(ii,1)}.VictimWorldLocation.z;
    end
end

figure
plot(deathEvents(:,3),deathEvents(:,4),'rx')
title('All Deaths')
ylabel('y')
xlabel('x')

% real heatmap

% m = meters, pt = points as in MATLAB data entries (indices)

m2pt = 100; % 100 points per meter
mapWidth = 40; % width of the map in meters, x dimension
mapHeight = 20; % height of the map in meters, y dimension
mapX = -mapWidth/2*m2pt:mapWidth/2*m2pt;
mapY = -mapHeight/2*m2pt:mapHeight/2*m2pt;
mapDeaths = zeros(length(mapY),length(mapX));

% circle properties
R_pt = m2pt; % radius, in points, of the circle
x_circ = -R_pt:R_pt; % x coords of a circle with radius R_pt, in pts
y_circ = sqrt(R_pt^2 - x_circ.^2); % y coords of a ""
y_ceil = ceil(y_circ); % discretize the y coords

for jj = 1:deathLen
    %     x_pt = ceil(deathEvents(jj,3)*m2pt + length(mapDeaths)/2);
    %     y_pt = ceil(deathEvents(jj,4)*m2pt + length(mapDeaths)/2);
    [~,x_pt] = min(abs(deathEvents(jj,3)*m2pt - mapX)); % the current death point in pts
    [~,y_pt] = min(abs(deathEvents(jj,4)*m2pt - mapY));
    for ii = 1:length(x_circ)
        mapDeaths(((-y_ceil(ii):y_ceil(ii))+y_pt),x_circ(ii)+x_pt) = mapDeaths(((-y_ceil(ii):y_ceil(ii))+y_pt),x_circ(ii)+x_pt) + 1;
    end
end
% mapDeaths(mapDeaths == 0) = NaN;

figure
% surf(mapDeaths,'EdgeColor','None','facecolor','interp')
% view(2);
% contourf(mapDeaths)
maxColor = max(mapDeaths(:));
cmap = colormap(jet(maxColor));
% cmap(1,:) = 1;
cmap = [1 1 1; cmap];
colormap(cmap)
imagesc(mapDeaths)
axis equal

a = imread('Map Overlays\Images\Prima\the rig.jpg');
b = im2double(a);
figure, imshow(b), hold on
[X,Y] = meshgrid(mapX,mapY);
hImg = imagesc(interp2(mapX,mapY,mapDeaths,linspace(mapX(1),mapX(end),2085),linspace(mapY(1),mapY(end),1544)'));
set(hImg,'AlphaData',0.6)
axis equal


% per player heat maps

% animated heat maps