function [pts] = divideLine(endpoints,segments)
%Returns the points that divide a line defined by endpoints into given number of segments in 2D space
%
%INPUT
%endpoints: numerical matrix containing two points defining the line, format [x1,y1;x2,y2]
%segments: integer defining number of segments
%
%OUTPUT
%pts: numerical matrix of x & y coordinates of midpoints of line segments (n segments x 2)

%% Check args
% TODO...

%% Calculate midpoints of segments
segStep = [endpoints(1,1)-endpoints(2,1),endpoints(1,2)-endpoints(2,2)]./(segments-1);

pts = zeros(segments,2);
pts(1,:) = endpoints(1,:);
pts(segments,:) = endpoints(2,:);

for i = 2:segments-1
    pts(i,:) = [(pts(1,1)-(segStep(1).*(i-1))), (pts(1,2)-(segStep(2).*(i-1)))];
end

end