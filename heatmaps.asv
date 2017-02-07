% Function to generate heatmap from deathEvents dataset

function heatmaps(EventsDeath,mapname,players_to_plot)

% figure
% plot(deathEvents(:,3),deathEvents(:,4),'rx')
% title('All Deaths')
% ylabel('y')
% xlabel('x')

% real heatmap
map.types = {'Deaths','Kills','KDspread'};
VictimKiller = {'Victim','Killer'};
% filter only players to plot
if isempty(players_to_plot)
    % If not specifying which players to plot, plot them all
    filtered.Deaths = 1:length(EventsDeath.DeathEventsList(:,1));
    filtered.Kills = filtered.Deaths;
else
    filtered.Deaths = [];
    filtered.Kills = [];
    for ii = 1:length(players_to_plot)
        filtered.Deaths = [filtered.Deaths find(strcmp(EventsDeath.DeathEventsList(:,1),players_to_plot(ii)))'];
        filtered.Kills = [filtered.Kills find(strcmp(EventsDeath.DeathEventsList(:,2),players_to_plot(ii)))'];
    end
    
end
% m = meters, pt = points as in MATLAB data entries (indices)

% Load Map props
mapPath = ['Map Overlays\Images\Prima\' mapname '.jpg'];
% b = imread(mapPath);
b = im2double(imread(mapPath));

% replace with auto load of transformcoefs
% transformCoefs = [40.09222824	1311.98395	-38.3124554	1241.421393]'; % rig, first order
% transformCoefs = [-0.232129357746820;31.1098260248596;1227.81872104742;-0.00754257950615764;-37.8515906754108;1238.82674928239]; % rig, second order
transformCoefs = loadTransCoefs(mapname);

%% OLD METHOD, unreliable due to multiple roots, also just the wrong way to approach problem
% Determine map X and Y coordinates by solving the inverse equations

% % linear transformation
% mapX = ([1:size(b,2)] - transformCoefs(2))/transformCoefs(1);
% mapY = ([1:size(b,1)] - transformCoefs(4))/transformCoefs(3);
% second order
% mapX = zeros(1,size(b,2));
% for ii = 1:size(b,2)
%     mapX(ii) = min(roots([transformCoefs(1), transformCoefs(2), transformCoefs(3)-ii]));
% end
% mapY = zeros(1,size(b,1));
% for ii = 1:size(b,1)
%     mapY(ii) = max(roots([transformCoefs(4), transformCoefs(5), transformCoefs(6)-ii]));
% end
% BRUTE FORCE MIN/MAX OF THE ROOTS, NOT ANALYTICAL, MIGHT FAIL 
% mapY = min(roots) for Fathom fails. mas(roots) works. Need solution to
% this. One option is to brute force all the maps and then store the mapX
% and mapY solutions for them, since the transformCoefs and pictures won't
% change.

%%


% circle properties
R_pt = 50; % radius, in points, of the circle
x_circ = -R_pt:R_pt; % x coords of a circle with radius R_pt, in pts
y_circ = sqrt(R_pt^2 - x_circ.^2); % y coords of a ""
y_ceil = ceil(y_circ); % discretize the y coords

% Limits that any point needs to be within so that the circle drawn around
% the point will not exceed the dimensions of the map image
x_pt_limits = [1+R_pt size(b,2)-R_pt];
y_pt_limits = [1+R_pt size(b,1)-R_pt];

for kk = 1:2
    map.(map.types{kk}) = zeros(size(b,1),size(b,2));
    for jj = filtered.(map.types{kk})
        % old method
    %     [~,x_pt] = min(abs(deathEvents(jj,3) - mapX)); % the current death point in pts
    %     [~,y_pt] = min(abs(deathEvents(jj,4) - mapY));

        % new, correct method
        x_coord = EventsDeath.DeathEvents(jj).([VictimKiller{kk} 'WorldLocation']).x; % x-coordinate of current event        
        y_coord = EventsDeath.DeathEvents(jj).([VictimKiller{kk} 'WorldLocation']).y; % y-coordinate of current event
        % Use the transformCoefs to convert the coordinate into a point value,
        % rounding to the nearest whole point
        x_pt = round(x_coord^2*transformCoefs(1) + x_coord*transformCoefs(2) + transformCoefs(3));
        y_pt = round(y_coord^2*transformCoefs(4) + y_coord*transformCoefs(5) + transformCoefs(6));

        % Protect against the point value (and circle) being outside of the size of the
        % image. It's divided by [1 -1], because, in the case where it's within
        % the limit interval, the subtraction will be [+num -num]. If outside
        % of the limit, one of those will be the reverse, and the < 0 check
        % will see if the division returns a negative value, indicating
        % violation.
        x_pt_exceeds = ((x_pt - x_pt_limits)./[1 -1]) < 0;
        if any(x_pt_exceeds) % overly complicated if statement to avoid writing more than one
            x_pt = x_pt_limits(x_pt_exceeds); % If the limit is exceeded, set the value to the limit that was exceeded
            warning('Event would result in circle outside of image. Shifting event point to limits.')
        end
        y_pt_exceeds = ((y_pt - y_pt_limits)./[1 -1]) < 0;
        if any(y_pt_exceeds) % overly complicated if statement to avoid writing more than one
            y_pt = y_pt_limits(y_pt_exceeds); % If the limit is exceeded, set the value to the limit that was exceeded
            warning('Event would result in circle outside of image. Shifting event point to limits.')
        end

        % Add circle of 1's to the map at the event point
        for ii = 1:length(x_circ)
            map.(map.types{kk})(((-y_ceil(ii):y_ceil(ii))+y_pt),x_circ(ii)+x_pt) = map.Deaths(((-y_ceil(ii):y_ceil(ii))+y_pt),x_circ(ii)+x_pt) + 1;
        end
    end
end

% Construct the KD spread map by subtracting

map.KDspread = map.Kills - map.Deaths;


% mapDeaths(mapDeaths == 0) = NaN;

% figure
% surf(mapDeaths,'EdgeColor','None','facecolor','interp')
% view(2);
% contourf(mapDeaths)
% imagesc(mapDeaths)
% axis equal

%% 

for kk = 1:3
    figure
    imshow(b)
    hold on
    % [X,Y] = meshgrid(mapX,mapY);
    % hImg = imagesc(interp2(mapX,mapY,mapDeaths,linspace(mapX(1),mapX(end),2085),linspace(mapY(1),mapY(end),1544)'));
    hImg = imagesc(map.(map.types{kk}));
    axis equal

    % handling the colormap and transparency
%     maxColor = max(map.(map.types{kk})(:)) - min(map.(map.types{kk})(:))
%     cmap = colormap(jet(maxColor));
    cmap = colormap(jet)
    cmap = [1 1 1; cmap]; % this sets the minimum value as white, and shifts the entire colormap 
    
    if kk == 3
        cmap = colormap(flipdim(jet,1));
    end
    % the minimum value right now are all the 0s that have no data, so this
    % makes them white.

    % default colormap, some transparency, so there is blue all over the map
    % set(hImg,'AlphaData',0.6)

    % modified colormap, 0s transparent, the rest has some transparency, not
    % covering overlay
    set(hImg,'AlphaData',0.6*(map.(map.types{kk})~=0))
    colormap(cmap)
    title(map.types{kk})
end