function orderlayers
ch = get(gca,'Children');
spl = [];
layers = [];
for i =1:length(ch)
  tag = get(ch(i),'Tag');
  if strncmp(tag, 'spline', 6);
    spl(end+1) = i;
    ud = get(ch(i),'UserData');
    layers(end+1) = ud.layer;
  end
end
[y_, ord] = sort(layers);
ch(spl) = ch(spl(ord));
set(gca,'Children',ch);
