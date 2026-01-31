
% prg is a semi-automated outlining program on an image. This program enable the user to manually select points on the
% image to form an outline. The user left click on the image once to make the image active and then left clicks on the 
% region forming an outline. Once outline is completed the user doubleclicks on the last point and all the points are joined
% using spline interpolation. User then have a option to left click on any point and drag them to make outline perfect. 

% In order to make program work save all the files in the work folder of the Matlab.

function varargout = prg(varargin)


if nargin == 0  % LAUNCH GUI

	fig = openfig(mfilename,'reuse');

	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
	guidata(fig, handles);
   
    flag = 0;
    save temp_flag.mat flag %quick hack
    
	if nargout > 0
		varargout{1} = fig;
	end

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

	try
		if (nargout)
			[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
		else
			feval(varargin{:}); % FEVAL switchyard
		end
	catch
		disp(lasterr);
	end

end


% --------------------------------------------------------------------
function varargout = pushbutton2_Callback(h, eventdata, handles, varargin)


%%%% Browse for the file on which ouline has to be drawn
%[fname,pname] = uigetfile('*.*','Select the file');
% pname = 'C:\Users\Anthro 47S05v1\Documents\MATLAB\Zoo photo preliminaries\PRG\'
 
%hacky load the name 
load temp.mat

I= gTIFFcrop;
set(handles.image,'HandleVisibility','ON')
axes(handles.image);
imshow(I); title(face_path)

%%%% Call spltool2 to draw the outline
%%%% First 'init' is passed as the argument to initialize the outline drawing
%%%% Second 'bgimg' is passed as an argument along with the image on which outline needs to be drawn
%%%% 'bgimg' sets the current handle on the image passed along
 spltool2('init')
 spltool2('bgimg',I)

 % --- Executes on button press in pushbutton3.
function pushbutton3_Callback(h, eventdata, handles,varargin)
    
    pushbutton2_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = pushbutton1_Callback(h, eventdata, handles, varargin)

%%%  Save the points of the outline
[ud,splx,sply] = savesplines;
  r=ud; 
  g=splx ;
  b=sply;
  rr = r.X;
  rr=rr';
  xy = [g{1,1}',b{1,1}'];
  varargout{1} =xy;
  load temp_flag.mat
  
  save ('temp_res','rr','xy','flag')
  close

%%% The code below assigns a knot on the image, and then enable us to move the knot anywhere onthe image in order
%%% to make outline perfect
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

% Adds a new knot to control the current spline.
% Normal case is initial knot assignment
% Extend case is moving the knot
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

% New knot assignment
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

% Delete old handles while dragging the knot
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

% Delete old spline curve as the knots are moved
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

% Modify the spline curve according to knot location
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
  X = ud.X;
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





% --- Executes on button press in flag.
function flag_Callback(hObject, eventdata, handles)
if (get(hObject,'Value') == get(hObject,'Max'))
flag = 1;
save temp_flag.mat flag
else
    
flag = 0;
save temp_flag.mat flag
 % Checkbox is not checked-take appropriate action
end
