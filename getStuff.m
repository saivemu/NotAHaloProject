% Going rogue, reading data
% function getStuff(mapname, gamesDesired)
% clear
mainTIC = tic;

addpath('C:\Users\Sarmad\Dropbox\Documents\OLAH\urlread2\')

elapsedTimes = struct('main',0,'matches',0,'events',0,'process',0,'heatmap',0);
GT = 'SacUsa';
if isempty(gamesDesired)    
    gamesDesired = 10;
end
if isempty(mapname)
    mapname = 'plaza';
end
%% Get matches
matchesTIC = tic;
% game number (for 'start') is 0 indexed, so last 25 games are games 0, 1,
% 2, ..., 24

% numGames = 100; % this for if just getting last 100
url = ['https://www.haloapi.com/stats/h5/players/' GT '/matches?']; % was string(__) in 2016
% opt = weboptions('HeaderFields',{'Ocp-Apim-Subscription-Key' 'ad15b8ce274b4028a62aef15e142766c'},'Timeout',30);
% opt2 = weboptions('HeaderFields',{'Ocp-Apim-Subscription-Key' 'a25c928ca938497aae3abb28a39d9ef2'},'Timeout',30);
% key2

%% IF USING URLREAD2

header1 = http_createHeader('Ocp-Apim-Subscription-Key','ad15b8ce274b4028a62aef15e142766c');
header2 = http_createHeader('Ocp-Apim-Subscription-Key','a25c928ca938497aae3abb28a39d9ef2');
% params = {'start', '1', 'count', '2'};
% queryString = http_paramsToString(params,1);
% [outputJSON,extras] = urlread2([url queryString],'GET',[],header);
% output = parse_json(outputJSON);


%%
% Finding games on specific maps
mapIDs.plaza = 'caacb800-f206-11e4-81ab-24be05e24f7e'; % Plaza
mapIDs.coliseum = 'cebd854f-f206-11e4-b46e-24be05e24f7e'; % Coliseum
mapIDs.eden = 'cd844200-f206-11e4-9393-24be05e24f7e';
mapIDs.empire = 'cdb934b0-f206-11e4-8810-24be05e24f7e';
mapIDs.fathom = 'cc040aa1-f206-11e4-a3e0-24be05e24f7e';
mapIDs.regret = 'cdee4e70-f206-11e4-87a2-24be05e24f7e';
mapIDs.the_rig = 'cb914b9e-f206-11e4-b447-24be05e24f7e';
mapIDs.truth = 'ce1dc2de-f206-11e4-a646-24be05e24f7e';


mapID = mapIDs.(mapname);
desiredMatchIds = cell(gamesDesired,1);

% numIter = numGames/25;
% countLast = (numIter - floor(numIter))*25;
% if countLast == 0
%     countLast = 25;
% end
% numIter = ceil(numIter);

startNum = 0;

% Requesting just 100 games
% for ii = 1:numIter
%     if ii == numIter
%         countNum = countLast;
%     else
%         countNum = 25;
%     end
%     data(ii) = webread(url,'start',startNum,'count',countNum,opt);
%
%
%     startNum = startNum + 25;
% end

% Looking for specific map only
ii = 1;
gamesFound = 0;
gamesFoundCnt = 1;
tElapsed = 0;
while gamesFound < gamesDesired
    countNum = 25;
    pause(1 - tElapsed)
    params = {'start', num2str(startNum), 'count', '2'};
    queryString = http_paramsToString(params,1);
    tic
    try
        dataPreJSON = urlread2([url 'start=' num2str(startNum) '&count=' num2str(countNum)],'GET',[],header1);
        data(ii) = parse_json(dataPreJSON);
%         data(ii) = webread(url,'start',startNum,'count',countNum,opt);
    catch
        pause(1)
        dataPreJSON = urlread2([url 'start=' num2str(startNum) '&count=' num2str(countNum)],'GET',[],header2);
        data(ii) = parse_json(dataPreJSON);
%         data(ii) = webread(url,'start',startNum,'count',countNum,opt2);
    end
    
    if isempty(data(ii).Results)
        % That's it, no more games to show
        break
    end
    
%     matchedMatches = find(strcmp({data(ii).Results.MapId},mapID));    
% looks like data.Results went from a structure in 2016 (from webread) to a
% cell in 2013 with urlread2, so need to process a little differently
    mapIds = cell(data(ii).ResultCount,1);
    for kk = 1:length(mapIds)
        mapIds{kk} = data(ii).Results{kk}.MapId;
    end
    matchedMatches = find(strcmp(mapIds,mapID));


    gamesFound = gamesFound + length(matchedMatches);
    for jj = 1:length(matchedMatches)
        desiredMatchIds{gamesFoundCnt} = data(ii).Results{matchedMatches(jj)}.Id.MatchId;
        disp(['Found ' num2str(gamesFoundCnt) '/' num2str(gamesDesired) ' matched matches.'])
        gamesFoundCnt = gamesFoundCnt + 1
    end
    
    startNum = startNum + 25;
    ii = ii + 1;
    tElapsed = toc
end
elapsedTimes.matches = toc(matchesTIC);
disp(['Took ' num2str(elapsedTimes.matches) ' sec to find ' num2str(gamesFound) ' matched matches.'])
%% Get MatchEvents
eventsTIC = tic;
tElapsed = 0;
skippedGames = 0;
% sometimes, a game is found in a player's matches, but no game events for
% that game are found, in this case, skip that game. Currently, we don't
% pre-allocate matchData (lol) so we can get away without having to remove
% an entry from matchData, just keep track of the number of skipped games
for jj = 1:gamesFound
    pause(1-tElapsed) % minimize pause time (1 sec per request), pause(negativenumber) is no pause
    url2 = ['https://www.haloapi.com/stats/h5/matches/' desiredMatchIds{jj} '/events'];
    tic
    try
        matchDataPreJSON = urlread2(url2,'GET',[],header1);
        matchData(jj - skippedGames) = parse_json(matchDataPreJSON);
%         matchData(jj - skippedGames) = webread(url2,opt);
    catch me
        if strcmp(me.identifier,'MATLAB:webservices:HTTP429StatusCodeError')
            % If too many requests, wait 5 seconds and try again
            pause(5)
            disp('Sent too many requests. Waiting 5 seconds and retrying.')
        elseif strcmp(me.identifier,'MATLAB:webservices:HTTP404StatusCodeError')
            % match not found, for whatever reason, 404 error
            skippedGames = skippedGames + 1;
            disp('Couldn''t find match. Skipping to next match.')
            continue
        elseif strcmp(me.identifier,'MATLAB:webservices:HTTP503StatusCodeError')
            % If server unresponsive, wait longer, 30 seconds
            disp('Server unresponsive. Waiting 30 seconds and retrying.')
            pause(30)
        end
        % now try again
        try
            matchDataPreJSON = urlread2(url2,'GET',[],header1);
            matchData(jj - skippedGames) = parse_json(matchDataPreJSON);
%             matchData(jj - skippedGames) = webread(url2,opt);
        catch me
            if strcmp(me.identifier,'MATLAB:webservices:HTTP404StatusCodeError')
                % match not found, for whatever reason, 404 error
                skippedGames = skippedGames + 1;
                disp('Couldn''t find match. Skipping to next match.')
                continue
            else
                % otherwise assuming server unavailable, try one more time
                % after a minute, if it don't work, not much else to do
                disp('Server STILL unresponsive. Waiting 60 seconds and retrying for last time.')
                pause(60)
                matchDataPreJSON = urlread2(url2,'GET',[],header2);
                matchData(jj - skippedGames) = parse_json(matchDataPreJSON);
%                 matchData(jj - skippedGames) = webread(url2,opt2);
            end
        end
    end
    
    disp(['Loaded game ' num2str(jj) '/' num2str(gamesFound) '.'])
    tElapsed = toc
end
gamesFoundAdj = jj - skippedGames;
elapsedTimes.events = toc(eventsTIC);
disp(['Took ' num2str(elapsedTimes.events) ' sec to download ' num2str(gamesFoundAdj) ' match events files.'])

%% Get equivalent deathEvents
processTIC = tic;
allEvents = [];
allEventsDeath.DeathEvents = [];
allEventsDeath.DeathEventsList = [];
% Looped over the loadDeaths.m code, without the loading of the file
% For each game loaded, running the loadDeaths code. Can probably be
% greatly optimized.
for ll = 1:gamesFoundAdj
    tic
    
    % copied code
    
    
    
%     data = matchData(ll); % set the data for this game
%     [data, foundCell] = formatTimeSinceStart(data);
%     if isempty(foundCell)
%         % if for whatever reason foundCell is empty (apparently cuz the
%         % GameEvents was only 1 event and thus not a cell), then skip this
%         % game
%         continue;
%     end
%     % foundCell is the cell # with all the events
%     
%     % parse data and simultaneously assign death events to players
%     
%     % not using any a priori information about players in the game, will
%     % instead just look for death events and add to the player list as we go
%     % along and encounter new players
%     % THIS WON'T WORK IF A PLAYER DOESN'T DIE, but it could work if we look
%     % for something else first (ie player spawns). Or could just go super
%     % official and use the match info data set
%     
%     fields = fieldnames(data);
%     dataLen = length(data.(fields{foundCell}));
%     
%     events = cell(dataLen,1);
%     
%     for ii = 1:dataLen
%         events{ii} = data.(fields{foundCell}){ii}.EventName;
%     end
%     deathEvents = find(strcmp('Death',events));
%     
%     
%     deathLen = length(deathEvents);
%     players = cell(1,8);
%     playersFound = 0;
%     deathEvents = [deathEvents zeros(deathLen,4)];
%     % rows correspond to entry in the data field that is a death, columns
%     % correspond to the player in players whose death it is, and then the x, y,
%     % and z coordinate of death
%     
%     jj = 1; % phantom events counter
%     kk = 1; % player events counter
%     emptyDeathEvents = [];
%     for ii = 1:deathLen
%         % for some reason, sometimes the victim comes back as empty, with no
%         % gamertag field. Idk what's going on there, but for the sake of the
%         % code, skip this case. Keep an eye out for this stuff.
%         if ~isempty(data.(fields{foundCell}){deathEvents(ii,1)}.Victim)
%             playerDeathEvents{kk} = data.(fields{foundCell}){deathEvents(ii,1)}.Victim.Gamertag;
%             % Sending out player names separately than playerNum because
%             % deathEvents is just a matrix. Player names are strings, so would
%             % have to change structure of deathEvents, and that's too much work
%             % lol
%             
%             % check against player names
%             playerNum = find(strcmp(playerDeathEvents{kk}, players));
%             if isempty(playerNum)
%                 playersFound = playersFound + 1;
%                 players{playersFound} = playerDeathEvents{kk};
%                 playerNum = playersFound;
%             end
%             kk = kk + 1;
%             
%             deathEvents(ii,2) = playerNum;
%             
%             deathEvents(ii,3) = data.(fields{foundCell}){deathEvents(ii,1)}.VictimWorldLocation.x;
%             deathEvents(ii,4) = data.(fields{foundCell}){deathEvents(ii,1)}.VictimWorldLocation.y;
%             deathEvents(ii,5) = data.(fields{foundCell}){deathEvents(ii,1)}.VictimWorldLocation.z;
%         else
%             % If this is one of those phantom events, note it for later
%             emptyDeathEvents(jj) = ii;
%             jj = jj + 1;
%         end
%     end
%     
%     % Get rid of phantom death events.
%     deathEvents(emptyDeathEvents,:) = [];
    
    
    % end copied
    
    Events = processEvents(matchData(ll)); 
    allEvents = [allEvents; Events];
    allEventsDeath.DeathEvents = [allEventsDeath.DeathEvents Events.Death.DeathEvents];
    allEventsDeath.DeathEventsList = [allEventsDeath.DeathEventsList; Events.Death.DeathEventsList];
    disp(['Processed ' num2str(ll) '/' num2str(gamesFound) ' games'' death events.'])
    toc
end
elapsedTimes.process = toc(processTIC);
disp(['Took ' num2str(elapsedTimes.process) ' sec to process ' num2str(gamesFoundAdj) ' games'' death events.'])

%% Save
mkdir('Output');
savename = ['DeathAndPlayerEvents_' GT '_' mapname '_' num2str(gamesFoundAdj) 'games.mat'];
save(['Output\' savename],'allEvents','allEventsDeath');

%% heatmap
tic
heatmaps(allEventsDeath,mapname,{})
elapsedTimes.heatmap = toc;
disp(['Took ' num2str(elapsedTimes.heatmap) ' sec to create heatmap.'])

elapsedTimes.main = toc(mainTIC);
disp(['Took ' num2str(elapsedTimes.main) ' sec to complete all.'])