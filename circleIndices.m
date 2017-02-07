R_pt = 10;
x = -R_pt:R_pt;
y = sqrt(R_pt^2 - x.^2);
map0 = zeros(5*R_pt);
y_ceil = ceil(y);

x_pt = length(map0)/2;
y_pt = length(map0)/2;

for ii = 1:length(x)
    map0(x(ii)+x_pt,((-y_ceil(ii):y_ceil(ii))+y_pt)) = map0(x(ii)+x_pt,((-y_ceil(ii):y_ceil(ii))+y_pt)) + 1;
end

figure
surf(map0,'EdgeColor','None','facecolor','interp')
view(2);
axis equal