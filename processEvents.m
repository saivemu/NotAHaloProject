% Function to process Halo API Match Events files in .json format

% Output is Events, a massive structure with everything:

% playerEvents: each player's name, the games they played in, and the
% indices to all the events that related to them
%
% deathEvents: the usual

function [Events] = processEvents(fname)

%% FOR TESTING BEFORE COMMITTING TO FUNCTION FORM

% fname = 'C:\Users\Sarmad\Dropbox\Documents\OLAH\Data\test_multiple_plaza_sac_oneGameEvents.json';

%%

addpath('C:\Users\Sarmad\Dropbox\Documents\OLAH\parse_json_2009_07_23')

if ischar(fname)
    % if it's actually a filename
    data = parse_json(fileread(fname));
else
    % otherwise probably the actual variable to process
    data = fname;
end

% Insert time since start in seconds for each event
[data, foundCell] = formatTimeSinceStart(data);

%% Process Events

% Parse all the events and categorize them
fields = fieldnames(data);
numEvents = length(data.(fields{foundCell}));

% Get all event names
events = cell(numEvents,1);

for ii = 1:numEvents
    events{ii} = data.(fields{foundCell}){ii}.EventName;
end

%% %-------- RoundStart --------%

% It's possible (likely) that this file is for multiple games. Each game
% begins with a "RoundStart" event, but it's also possible that we're
% looking at a multi-round game mode (eg. Breakout), so note only the
% RoundStart events that have value RoundIndex = 0, as those events
% actually indicate a new game.

RoundStartIndx = find(strcmp('RoundStart',events));
numRounds = length(RoundStartIndx);

% Here, differentiate rounds from games. If it's Round 0, then it's a new
% game. Otherwise, it's just another round in the same game.
GameStartIndx = zeros(size(RoundStartIndx));
numGames = 0;

for ii = 1:numRounds
    % NOTE: The code below assumes a new game starts with Round 0. This
    % seems to be true for non-round-based games, but I'm not sure it's
    % true for something like Breakout, where I'm assuming the first round
    % is Round 1. But we're not looking at Breakout games, so whatevs.
    if ~data.(fields{foundCell}){RoundStartIndx(ii)}.RoundIndex
        numGames = numGames + 1;
        GameStartIndx(numGames) = RoundStartIndx(ii);
    end
end
GameStartIndx = GameStartIndx(GameStartIndx > 0);

% Go through all events and append the game number information
for ii = 1:numEvents
    data.(fields{foundCell}){ii}.GameNumber = find((ii - GameStartIndx) >=0,1,'last');
    % The code works by subtracting the current event index (ii) from the
    % game start indices, and finding the last positive value, meaning this
    % event occurs after that game starts, but before the next game starts,
    % so it is from that game.
end

Events.GameEvents = data.(fields{foundCell});

%% %-------- PlayerSpawn --------%

% Get players in the game by looking at spawn events

PlayerSpawnIndx = find(strcmp('PlayerSpawn',events));
numSpawns = length(PlayerSpawnIndx);
SpawnEvents = cell(numSpawns,3);

Players = cell(numGames,1); % list of players per game
numPlayers = zeros(numGames,1); % number of players per game

for ii = 1:numSpawns
    thisPlayer = data.(fields{foundCell}){PlayerSpawnIndx(ii)}.Player.Gamertag; % the player that spawned
    thisGame = data.(fields{foundCell}){PlayerSpawnIndx(ii)}.GameNumber; % the game the spawn took place in
    SpawnEvents(ii,:) = [{thisPlayer}, {thisGame}, {PlayerSpawnIndx(ii)}];
    % Check whether, for this game, this player has been listed before. If
    % not, list him, and increment the counter for the number of players in
    % this game.
    if ~any(strcmp(thisPlayer,Players(thisGame,:)))
        numPlayers(thisGame) = numPlayers(thisGame) + 1;
        Players{thisGame,numPlayers(thisGame)} = thisPlayer;
    end
end

% Track all events for each player

PlayerEvents = unique(Players(~cellfun(@isempty,Players))); % a list of all players
if numGames == 1
    % If only 1 game, then PlayerEvents is a row vector, but we want it to
    % be a column.
    PlayerEvents = PlayerEvents';
end
numUniquePlayers = length(PlayerEvents);

% As of now, track: games, spawns, kills, deaths
PlayerEvents = [PlayerEvents cell(numUniquePlayers,4)]; % add columns for all the events to track

% Track games and spawns
for ii = 1:numUniquePlayers
    matchedSpawnEvents = strcmp(PlayerEvents(ii,1),SpawnEvents(:,1));
    matchedSpawnEventsIndx = find(matchedSpawnEvents);
    PlayerEvents{ii,2} = unique([SpawnEvents{matchedSpawnEvents,2}]); % tracking games
    for jj = 1:length(PlayerEvents{ii,2})
        curGame = PlayerEvents{ii,2}(jj);
        PlayerEvents{ii,3}{jj} = [SpawnEvents{matchedSpawnEventsIndx([SpawnEvents{matchedSpawnEventsIndx,2}] == curGame),3}]; % tracking spawns, per game
    end
end


% Store Output
Events.Player.PlayerEvents = PlayerEvents;
Events.Player.SpawnEvents = SpawnEvents;

% The rest of the things to track will have to happen when their events are
% processed. For example, next are death events, so player kills and deaths
% can be tracked.

%% %-------- Death --------%

% The death event is the most data rich event of them all. Instead of
% trying to dumb it down into a cell form, just send the whole structure
% out, and let the downstream scripts perform whatever analysis they want.

DeathEventsIndx = find(strcmp('Death',events)); % indices for death events
numDeaths = length(DeathEventsIndx);
DeathEvents = [data.(fields{foundCell}){DeathEventsIndx}]; % store the entire structure

DeathEventsForMatching = cell(numDeaths,4);
for ii = 1:numDeaths
    % It's possible that the victim or killer is null, and thus the
    % gamertag field doesn't exist, so prepare for that.
    if isfield(DeathEvents(ii).Victim,'Gamertag')
        thisVictim = DeathEvents(ii).Victim.Gamertag;
    else
        thisVictim = 'NULL';
    end
    if isfield(DeathEvents(ii).Killer,'Gamertag')
        thisKiller = DeathEvents(ii).Killer.Gamertag;
    else
        thisKiller = 'NULL';
    end
    DeathEventsForMatching(ii,:) = [{thisVictim}, {thisKiller}, {DeathEvents(ii).GameNumber}, {DeathEventsIndx(ii)}];
end

for ii = 1:numUniquePlayers
    % Find this player's kills
    matchedKillEvents = strcmp(PlayerEvents(ii,1),DeathEventsForMatching(:,2));
    matchedKillEventsIndx = find(matchedKillEvents);
    
    % Find this player's deaths
    matchedKilledEvents = strcmp(PlayerEvents(ii,1),DeathEventsForMatching(:,1));
    matchedKilledEventsIndx = find(matchedKilledEvents);    
    
    % Store the indices of these events in the PlayerEvents master cell
    for jj = 1:length(PlayerEvents{ii,2})
        curGame = PlayerEvents{ii,2}(jj);
        PlayerEvents{ii,4}{jj} = [DeathEventsForMatching{matchedKillEventsIndx([DeathEventsForMatching{matchedKillEventsIndx,3}] == curGame),4}]; % tracking kills, per game
        PlayerEvents{ii,5}{jj} = [DeathEventsForMatching{matchedKilledEventsIndx([DeathEventsForMatching{matchedKilledEventsIndx,3}] == curGame),4}]; % tracking deaths, per game
    end
end
    
Events.Death.DeathEvents = DeathEvents;
Events.Death.DeathEventsList = DeathEventsForMatching;

%% %-------- WeaponPickup --------%

%% %-------- WeaponDrop --------%

