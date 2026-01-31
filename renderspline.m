% Sets the knots of the current spline.
function renderspline(hs,ud)
X = ud.X; closed = ud.closed;
polyline = ud.polyline;

if isempty(X)
  return
end



if polyline
  if closed
    Xi = [X X(:,1)];
  else
    Xi = X;
  end
else
  if closed
    pp = cscvn([X, X(:,1)]);
  else
    pp = cscvn(X);
  end
  Xi = fnplt(pp);
end

set(hs,'XData',Xi(1,:), 'YData', Xi(2,:));

if size(X,2) == 1
  set(hs,'Marker','x','MarkerSize',1);
else
  set(hs,'Marker','none');
end

