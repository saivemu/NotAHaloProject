% Function to load in .json files and output a structure based on player
% death events

function [deathEvents, deathLen, players, playerDeathEvents] = loadDeaths(fname)
% I've added the jsonlab folder to the default MATLAB path

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

jj = 1; % phantom events counter
kk = 1; % player events counter
emptyDeathEvents = [];
for ii = 1:deathLen
    % for some reason, sometimes the victim comes back as empty, with no
    % gamertag field. Idk what's going on there, but for the sake of the
    % code, skip this case. Keep an eye out for this stuff.
    if ~isempty(data.(fields{foundCell}){deathEvents(ii,1)}.Victim)
        playerDeathEvents{kk} = data.(fields{foundCell}){deathEvents(ii,1)}.Victim.Gamertag;
        % Sending out player names separately than playerNum because
        % deathEvents is just a matrix. Player names are strings, so would
        % have to change structure of deathEvents, and that's too much work
        % lol
        
        % check against player names
        playerNum = find(strcmp(playerDeathEvents{kk}, players));
        if isempty(playerNum)
            playersFound = playersFound + 1;
            players{playersFound} = playerDeathEvents{kk};
            playerNum = playersFound;
        end
        kk = kk + 1;
        
        deathEvents(ii,2) = playerNum;
        
        deathEvents(ii,3) = data.(fields{foundCell}){deathEvents(ii,1)}.VictimWorldLocation.x;
        deathEvents(ii,4) = data.(fields{foundCell}){deathEvents(ii,1)}.VictimWorldLocation.y;
        deathEvents(ii,5) = data.(fields{foundCell}){deathEvents(ii,1)}.VictimWorldLocation.z;
    else
        % If this is one of those phantom events, note it for later
        emptyDeathEvents(jj) = ii;
        jj = jj + 1;
    end
end

% Get rid of phantom death events.
deathEvents(emptyDeathEvents,:) = [];