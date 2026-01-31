function [o1,o2,o3] = spltool2(cmd,varargin)

switch cmd
 case 'init',
  set(gcf,'ButtonDownFcn', @spleditorButton);
   set(gcf,'DoubleBuffer','on');
   set(gcf,'KeyPressFcn',@keypress);

 case 'quit',
  quitspltool;

 case 'key',
  key = varargin{1};
  handle_keypress(key);

 case 'bgimg',
  img = varargin{1};
  try delete(findobj('Tag','bgimg')), catch,end;
  
  h = imshow(img);
 
%   axis auto; 
  set(h,'HitTest','off','Tag','bgimg');

 case 'modify',
  ud = varargin{1};

  deleteallsplines;

  for i=1:length(ud)
    hs = newspline(ud(i));
  end
  if length(ud)>0
      activateSpline(hs);
  end

 case 'save',
  [ud,splx,sply] = savesplines;
  o1=ud;
  o2=splx;
  o3=sply;
  

 otherwise,
  error(sprintf('Unrecognized command to spltool: ''%s''', cmd));
end



function [ud,splx,sply] = savesplines(ax)
if nargin<1
  ax = gca;
end

splx = {}; sply = {};
ud = [];
ch = get(ax,'Children');
for i =1:length(ch)
  if strncmp(get(ch(i),'Tag'), 'spline', 6);
    ud = [ud get(ch(i),'UserData')];
    splx{end+1} = get(ch(i),'XData');
    sply{end+1} = get(ch(i),'YData');
  end
end




% function keypress(src,event)
% key = get(gcf,'CurrentCharacter');
% handle_keypress(key);
% 
% % Handles keypresses in window.
% function handle_keypress(key)
% switch key
%   % ESC stops editing.
%  case 27,
%   noedit
%   % Toggle open or closed curve.
%  case 'c',
%   togglespline_closure;
%   % Toggle whether it's a polyline or a spline.
%  case 's',
%   togglespline_polyline;
%   % delete the last knot.
%  case 8,
%   X = getspline_X;
%   if ~isempty(X)
%     updatespline_X(X(:,1:end-1));
%     hs = findobj(gca,'Tag','spline');
%     activateSpline(hs);
%   end
%   % pick a color
%  case 'p',
%   setcolor(uisetcolor);
%   % toggle filling
%  case 'f',
%   togglespline_filling;
%  case '+',
%   modifyspline_layer(+1);
%  case '-',
%   modifyspline_layer(-1);
%  case {'0','1','2','3','4','5','6','7','8','9'},
%   modifyspline_layer(key);
%  case 'q',
%   quitspltool;
% end


function quitspltool
set(gca,'ButtonDownFcn', []);
set(gcf,'KeyPressFcn',[]);
uiresume(gcf);



% Adds a new knot to control the current spline.
function spleditorButton(src,event)
  switch get(gcf,'SelectionType')
  case 'normal',
  [xi, yi ] = getpts(gca) ;
  c = xi(1);
  d = yi(1);
   xi =cat(1,xi,xi(1));
   yi =cat(1,yi,yi(1));
  n=size(xi);
  e = xi(n(1,1));
  f= yi(n(1,1));
  for k=1:n(1,1)
      x =[xi(k),yi(k)];
      newknot(x);
  end
 
case 'extend',
 x = get(gca,'CurrentPoint');
 x = [x(1,1); x(1,2)];
   moveall(x);
end

function newknot(x)
hkc = findobj(gca,'Tag','knotcurve');
if isempty(hkc)
  newspline;
  hold on
  hkc = plot(x(1),x(2),'r.');
  hold off
  set(hkc,'Tag','knotcurve');
else
  set(hkc,'XData', [get(hkc,'XData') x(1)]);
  set(hkc,'YData', [get(hkc,'YData') x(2)]);
end
X = [get(hkc,'XData');
     get(hkc,'YData')];
hold on; hk = plot(x(1),x(2),'ro-'); hold off;
set(hk, 'Tag', 'knot', 'ButtonDownFcn',{@knotselector, size(X,2)}, ...
        'MarkerSize',1, 'LineWidth',4);
updatespline_X(X);



function deletehandles
try
  delete(findobj(gca,'Tag','knotcurve'));
  delete(findobj(gca,'Tag', 'knot'));
catch, end;


function noedit
deletehandles;
hs = findobj(gca,'Tag','spline');
if ~isempty(hs)
  set(hs,'Tag','spline-dormant');
end

function deletecurrentspline
fprintf('deleteing the spline\n');
deletehandles;
hs = findobj(gca,'Tag','spline');
delete(hs);

function deleteallsplines
deletehandles;
objs=findobj('-regexp','Tag','spline.*');
try delete(objs), catch,end;

function setcolor(col)
if length(col)==1
  return
end
hs = findobj(gca,'Tag','spline');
if isempty(hs)
  return
end
ud = get(hs,'UserData');
if ud.filled
  set(hs,'FaceColor',col);
else
  set(hs,'Color',col);
end
ud.color = col;
set(hs,'UserData',ud);



function modifyspline_layer(mod)
hs = findobj(gca,'Tag','spline');
if isempty(hs)
  warning('No current spline.');
  return
end
ud = get(hs,'UserData');
if mod<=1
  ud.layer = ud.layer + mod;
else
  ud.layer = mod-'0';
end
set(hs,'UserData',ud);
xlabel(sprintf('Layer = %d', ud.layer));
orderlayers



function togglespline_closure
hs = findobj(gca,'Tag','spline');
if isempty(hs)
  warning('No current spline.');
  return
end
ud = get(hs,'UserData');
ud.closed = ~ud.closed;
set(hs,'UserData',ud);
renderspline(hs,ud);


function togglespline_polyline
hs = findobj(gca,'Tag','spline');
if isempty(hs)
  warning('No current spline.');
  return
end
ud = get(hs,'UserData');
ud.polyline = ~ud.polyline;
set(hs,'UserData',ud);
renderspline(hs,ud);

% redraw the spline using the appropriate primitive.
function togglespline_filling
hs = findobj(gca,'Tag','spline');
if isempty(hs)
  warning('No current spline.');
  return
end
ud = get(hs,'UserData');

deletecurrentspline
ud.filled = ~ud.filled;
activateSpline(newspline(ud));



function X = getspline_X
hs = findobj(gca,'Tag','spline');
if isempty(hs)
  X = []; return
end
ud = get(hs,'UserData');
X = ud.X;


function hsn = newspline(ud)
noedit
if nargin<1 | isempty(ud)
  ud.closed = 0;
  ud.polyline = 0;
  ud.filled = 0;
  ud.color = 'w';
  ud.layer = 0;
  ud.X = [];
else
  X = ud.X
end
hsn = drawspline(ud);
set(hsn,'ButtonDownFcn', @handleClickSpline);
orderlayers


function updatespline_X(X)
hs = findobj(gca,'Tag','spline');
if isempty(hs)
  return
end

if isempty(X)
  deletecurrentspline
else
  ud = get(hs,'UserData');
  ud.X = X;
  set(hs,'UserData',ud);
  renderspline(hs,ud);
end


function moveall(oldpos)
noedit
[olduds,oldsplx,oldsply] = savesplines;

set(gcf,'WindowButtonMotionFcn',...
        {@moveAllMoveMouse,olduds,oldpos,oldsplx,oldsply},...
        'WindowButtonUpFcn', @knotSelectorButtonUp);

function moveAllMoveMouse(src,event, olduds, oldpos, oldsplx, oldsply)
x = get(gca,'CurrentPoint');
x = [x(1,1); x(1,2)];
dpos = x-oldpos;
ch = get(gca,'Children');
for i =1:length(ch)
  if strncmp(get(ch(i),'Tag'), 'spline', 6);
    ud = get(ch(i),'UserData');
    ud.X = olduds(i).X + repmat(dpos,1, size(olduds(i).X, 2));
    set(ch(i),'UserData', ud, ...
              'XData', oldsplx{i}+dpos(1), ...
              'YData', oldsply{i}+dpos(2));
  end
end


function handleClickSpline(src,event)
hs = findobj(gca,'Tag','spline');

isactive = (~isempty(hs) &  (hs == src));
switch get(gcf,'SelectionType')
 case 'normal',
  if ~isactive
    activateSpline(src);
  end
 case 'alt',
  noedit;
  movespline(src);
end


function movespline(hs)
x = get(gca,'CurrentPoint');
x = [x(1,1); x(1,2)];
ud = get(hs,'UserData');
splx = get(hs,'XData');
sply = get(hs,'YData');
set(gcf,'WindowButtonMotionFcn', ...
        {@moveSplineMoveMouse,hs,x,ud,splx,sply},...
        'WindowButtonUpFcn', @knotSelectorButtonUp);

function moveSplineMoveMouse(src,event,hs,oldpos,oldud,oldsplx,oldsply)
x = get(gca,'CurrentPoint');
x = [x(1,1); x(1,2)];
dpos = x-oldpos;

ud = oldud;
ud.X = oldud.X + repmat(dpos,1, size(oldud.X, 2));
set(hs,'UserData', ud, ...
       'XData', oldsplx+dpos(1), ...
       'YData', oldsply+dpos(2));



% Sets up handlers for dragging a knot.
function knotselector(src,event,i)
hknots = findobj(gca,'Tag','knotcurve');
if isempty(hknots)
  warning('Got an event on a knot, but there is no control curve.');
  return
end
set(gcf,'WindowButtonMotionFcn', {@knotSelectorMoveMouse, i,src,hknots}, ...
		'WindowButtonUpFcn', @knotSelectorButtonUp);


% Drags a knot.
function knotSelectorMoveMouse(src,event,i,knot,hknotcurve)
x = get(gca,'CurrentPoint');
x = [x(1,1); x(1,2)];

set(knot,'XData', x(1), 'YData', x(2));
xk = get(hknotcurve,'XData');
xk(i) = x(1);
set(hknotcurve, 'XData', xk);
yk = get(hknotcurve,'YData');
yk(i) = x(2);
set(hknotcurve, 'YData', yk);
updatespline_X([xk; yk]);




% Stops dragging a knot.
function knotSelectorButtonUp(src,event)
set(gcf,'WindowButtonMotionFcn', [],...
		'WindowButtonUpFcn', []);
