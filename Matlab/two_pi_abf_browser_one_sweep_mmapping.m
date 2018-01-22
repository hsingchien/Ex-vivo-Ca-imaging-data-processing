function two_pi_abf_browser_one_sweep( varargin )
% This function allows user to have a preliminary exploration in the 2pi
% raw data. 
% Use sliders to shift between frames and sweeps, corresponding information
% and images are laid out. 


hax = figure('Name', '2 photon image abf browser', 'NumberTitle', 'off', 'Position', [271 54 1024 768], 'Visible','off', 'Resize', 'off');


appdatadefault(hax, 'current_file', 1);
appdatadefault(hax, 'current_frame', 1);
appdatadefault(hax, 'current_sweep', 1);
appdatadefault(hax, 'numsweep', 9);
appdatadefault(hax, 'redrange', [0000, 2^14-1]);
appdatadefault(hax, 'greenrange', [0000, 2^14-1]);
appdatadefault(hax, 'bluerange', [0000, 2^14-1]);
appdatadefault(hax, 'dfch', 1);
appdatadefault(hax, 'filelist', {});
appdatadefault(hax, 'files', {});
appdatadefault(hax, 'xpix', 512);
appdatadefault(hax, 'ypix', 512);
appdatadefault(hax, 'chlist', '');
appdatadefault(hax, 'dispinfo', '');
appdatadefault(hax, 'rawimg', []);
appdatadefault(hax, 'framesum', []);
appdatadefault(hax, 'bgimg', []);
appdatadefault(hax, 'bglist', {});
appdatadefault(hax, 'offset', 0);
appdatadefault(hax, 'maxframe', 10);
InitFig(hax);
set(hax, 'Visible','on');
        




end

function AddFile(hObject, callbackdata)
hax = gcf;
handles = getappdata(hax,'handles');
%% read new abf file and raw file
[abfFile, abfPath] = uigetfile('.abf','select abf file you want to look');
    if ~abfFile
        error('unable to open this file');
        return;
    end
    data = abf2datastruct(strcat(abfPath,abfFile));
    datapoints = data.points;
    %%%%%%%%%%%%%%PUT INPUT CHECK HERE %%%%%%%%%%%%%%%%
    % [pts_per_sweep * num_input * num_run] 
    % Input: rec\stim\frame\position
    infostruct = AbfExtract(data); %include 'timep', 'framep', 'positionp', 'stim_points_boundary'
[rawFile, rawPath] = uigetfile('.raw','select raw file you want to look');
    
    setappdata(hax,'filepath',rawPath);
    header = xml2struct(strcat(rawPath, 'Experiment.xml')); % read xml header file
    [xpix, ypix, fieldsize, framenum] = ReadHeader(header);
    chs = 4; %size(rawimg.Data.img,1)/xpix/ypix/framenum; % number of channels
    rawimg = memmapfile(strcat(rawPath, rawFile),'Format',{'uint16',[xpix, ypix, chs, framenum],'img'}); % memory mapping
    setappdata(hax,'rawimg',rawimg);
    %%%%%%%%%%%%%PUT INPUT CHECK HERE%%%%%%%%%%%%%%%%%%%%%%
    if isempty(getappdata(hax,'chlist'))
        chlist = {};
        for i = 1:chs
            chlist = [chlist, num2str(i)];
        end
        chlist = [chlist, 'None'];
        setappdata(hax, 'chlist', chlist);
    end
%% 

% because frame & sweep don't match perfectly, build the frame-sweep look up
% table
framep = infostruct.framep;
timep = infostruct.timep;
frametime=timep(framep);
framep = reshape(framep, 2,[size(framep,2)/2])';
frametime=reshape(frametime,2,[size(frametime,2)/2])';
meantime=1/2*(frametime(:,1)+frametime(:,2));
frametime=[frametime,meantime];
csvwrite(strcat(rawPath,'frametime.csv'),frametime);
framesum = size(framep,1); % total number of valid frames in this file
setappdata(hax, 'framesum', [getappdata(hax,'framesum'), framesum]); % keep a record of total frame number for each file
setappdata(hax, 'maxframe', sum(getappdata(hax, 'framesum'))); % total frame number across all files
ptspersweep = infostruct.ptspersweep;
singlesweepsum = [0];
end_position_index = [0];
for i = 1:size(datapoints,3)
    time_range = [(i-1)*ptspersweep, i*ptspersweep-1];
    maxframe = sum(framep(:,1)>=time_range(1) & framep(:,1) <= time_range(2));
    singlesweepsum = [singlesweepsum, maxframe];
    end_position_index = [end_position_index, maxframe+end_position_index(end)]; %the array of end frame number of each sweep
end
setappdata(hax, 'sweepsum', singlesweepsum); % lookup table as sweepsum (number of frames for each sweep)
setappdata(hax, 'numsweep', infostruct.numsweep);
%finish data input. rawimage is shaped as [xpix, ypix, channel#, frame],
%experiment protocol is stored in data(original file) and infostruct
%include 'timep', 'framep', 'stim_points_boundary'
%% file info stored as struct in a cell 'files'
file = struct('datapoints', data.points, 'framep',infostruct.framep,...
    'timep', infostruct.timep, 'meanframetime', meantime,...
    'stimp', infostruct.stimp, 'sweepsum', singlesweepsum, ...
    'ptspersweep', infostruct.ptspersweep, 'odor_list', infostruct.odor_list);
setappdata(hax, 'file', file);

%% set general info
filelist = getappdata(hax, 'filelist');
if size(filelist,1) == 0;
setappdata(hax, 'inter', data.s_interval); 
setappdata(hax, 'xpix', xpix);
setappdata(hax, 'ypix', ypix);
setappdata(hax, 'dispinfo', '');
setappdata(hax, 'fieldsize', fieldsize);
setappdata(hax, 'current_frame', 1);

end
%%  store newly added information into hax
filelist = [filelist, rawFile];
setappdata(hax, 'filelist', filelist);
UpdateGUI(hax);
UpdateImg();
end

function UpdateGUI(hax)
handles = getappdata(hax, 'handles');
sweepsum = getappdata(hax, 'sweepsum');
maxframe = sweepsum(2);
numsweep = getappdata(hax, 'numsweep');
if maxframe > 1
    set(handles.frame_slider, 'Max', maxframe, 'SliderStep', [1/(maxframe-1), 4/(maxframe-1)]);
else
    set(handles.frame_slider, 'Max', 1, 'SliderStep', [1,1]); %file is empty
end
set(handles.sweep_slider, 'Max', numsweep, 'SliderStep', [1/(numsweep-1), 4/(numsweep-1)]);
set(handles.imgax, 'XLim', [0,getappdata(hax,'xpix')], 'YLim', [0,getappdata(hax,'ypix')]);
chlist = getappdata(hax,'chlist');
set(handles.redch, 'String', chlist);
set(handles.greench, 'String', chlist);
set(handles.bluech, 'String', chlist);
set(handles.dfch, 'String', chlist(1:end-1));
set(handles.filelist, 'String', getappdata(hax,'filelist'), 'Value', size(getappdata(hax,'filelist'),2));

end

function [xpix, ypix, fieldsize, framenum]=ReadHeader(header)
header = header.Children;
    for(i = 1:size(header,2))
        if isequal(header(i).Name, 'LSM')
            break;
        end
    end
    LSM = header(i).Attributes; 
    for(i = 1:size(LSM,2))
        if isequal(LSM(i).Name, 'pixelX')
            break;
        end
    end
    xpix = str2num(LSM(i).Value);
    ypix = str2num(LSM(i+1).Value);
    for(i = 1:size(LSM,2))
        if isequal(LSM(i).Name, 'fieldSize')
            break;
        end
    end
    fieldsize = LSM(i).Value;
    for(i = 1:size(header,2))
        if isequal(header(i).Name, 'Streaming')
               break;
         end
    end
    Streaming = header(i).Attributes; 
    for(i = 1:size(Streaming,2))
        if isequal(Streaming(i).Name, 'frames')
            break;
        end
    end
    framenum = str2num(Streaming(i).Value);
end

function UpdateImg()

hax = gcf;
handles = getappdata(hax, 'handles');
file = getappdata(hax, 'file');
set(handles.dfswitch, 'Value', 0); % update image will disable df/f view
current_frame = getappdata(hax, 'current_frame');
%stimp = getappdata(hax, 'stim_points_boundary');
rawimg = getappdata(hax, 'rawimg');
redrange = getappdata(hax, 'redrange');
greenrange = getappdata(hax, 'greenrange');
bluerange = getappdata(hax, 'bluerange');

%% optimize image display
img = rawimg.Data.img(:,:,:,current_frame);
img = double(img);
img = imfilter_gaussian(img,[1 1 0]);
% make an empty channel
img = cat(3,img, zeros(getappdata(hax, 'xpix'), getappdata(hax, 'ypix'))); % attach a zero layer for none
vers = version;
if strncmp(vers,'7.14.0',6)
    red = get(handles.redch,'Value');
    green = get(handles.greench,'Value');
    blue = get(handles.bluech,'Value');
else
    red = handles.redch.Value;
    green = handles.greench.Value;
    blue = handles.bluech.Value;
end
% manually scale the image

rgbimg = cat(3, (img(:,:,red)-redrange(1))/diff(redrange), (img(:,:,green)-greenrange(1))/diff(greenrange),...
    (img(:,:,blue)-bluerange(1))/diff(bluerange));

rgbimg(rgbimg > 1) = 1;
%% image layout

image(rgbimg,'Parent', handles.imgax);
%plot a  bar indicate the position of current frame in e-phys axes
PlotAx(hax);
%update info panel
UpdateInfo(hax);

end

function PlotAx(hax)
handles = getappdata(hax,'handles');
current_frame = getappdata(hax, 'current_frame');
current_sweep = getappdata(hax, 'current_sweep');
current_file = getappdata(hax, 'current_file');
file = getappdata(hax, 'file');
odor_list = file.odor_list;
inter = getappdata(hax, 'inter');
ptspersweep = file.ptspersweep;
framep = reshape(file.framep, 2,[size(file.framep,2)/2])';
xel = 0:ptspersweep-1;
xel = inter * xel;
frame_point = framep(current_frame, :);
barposition = file.timep(frame_point); 
barposition = barposition - inter*ptspersweep*(current_sweep-1);
odor_bar = file.timep(odor_list(current_sweep,2:3));
plot(xel, file.datapoints(:,1,current_sweep),'blue', 'Parent', handles.rec_ax);
ylimit = get(handles.rec_ax, 'YLim');
line([barposition(1) barposition(1)], ylimit, 'Parent', handles.rec_ax);
line([barposition(2) barposition(2)], ylimit, 'Parent', handles.rec_ax);
line([odor_bar(1), odor_bar(1)], ylimit, 'Parent', handles.rec_ax, 'Color', [0.7,0.7,0.7]);
line([odor_bar(2), odor_bar(2)], ylimit, 'Parent', handles.rec_ax, 'Color', [0.7,0.7,0.7]);
set(handles.rec_ax,'YLim', ylimit);
plot(xel, file.datapoints(:,2,current_sweep),'red', 'Parent', handles.stim_ax);
line([barposition(1) barposition(1)], get(handles.stim_ax, 'YLim'), 'Parent', handles.stim_ax);
line([barposition(2) barposition(2)], get(handles.stim_ax, 'YLim'), 'Parent', handles.stim_ax);
line([odor_bar(1), odor_bar(1)], ylimit, 'Parent', handles.stim_ax, 'Color', [0.7,0.7,0.7]);
line([odor_bar(2), odor_bar(2)], ylimit, 'Parent', handles.stim_ax, 'Color', [0.7,0.7,0.7]);
end

function UpdateInfo(hax)
current_frame = getappdata(hax, 'current_frame');
current_file = getappdata(hax, 'current_file');
current_sweep = getappdata(hax, 'current_sweep');
total_frame = getappdata(hax, 'maxframe');
framestr = [num2str(current_frame),'(',num2str(total_frame),')'];
file = getappdata(hax, 'file');
odor_list = file.odor_list;
infohandle = findobj(hax, 'Tag', 'Text');
str1 = {'Current File: ', num2str(current_file),'Current Frame: ', framestr, 'Total Frame:', num2str(getappdata(hax, 'maxframe')),...
    'Current Sweep: ', current_sweep, 'Valve#: ', odor_list(current_sweep,1), 'Field Size: ', getappdata(hax, 'fieldsize')};
str1 = strcat(str1);
set(infohandle, 'String', str1);
end

function AddBg(hObject, callbackdata)
hax = gcf;
handles = getappdata(hax, 'handles');
current_frame = getappdata(hax, 'current_frame');
current_file = getappdata(hax, 'current_file');
bglist = getappdata(hax, 'bglist');
bgimg = getappdata(hax, 'bgimg');
bgimg = [bgimg;current_frame, current_file]; %bgimg serves as the index of bg imgs
str = ['file', num2str(current_file), '; ', 'frame', num2str(current_frame)];
bglist = [bglist, str];
setappdata(hax, 'bgimg', bgimg);
setappdata(hax, 'newbg',true);
setappdata(hax, 'bglist', bglist);
set(handles.bglist, 'String', bglist, 'Value', size(bglist,2));
vers = version;
if strncmp(vers,'7.14.0',6)
    if get(handles.dfswitch,'Value') == 1
        dfUpdateImg();
    end
else
    if handles.dfswitch.Value == 1
        dfUpdateImg();
    end
end
end

function DelBg(hObject, callbackdata)

hax = gcf;
handles = getappdata(hax,'handles');
vers = version;
if strncmp(vers,'7.14.0',6)
    bgselected = get(handles.bglist,'Value');
else
    bgselected = handles.bglist.Value;
end
bglist = getappdata(hax, 'bglist');
bgimg = getappdata(hax, 'bgimg');
bglist(bgselected) = [];
bgimg(bgselected,:) = [];
setappdata(hax, 'bglist', bglist);
setappdata(hax, 'newbg', true);
setappdata(hax, 'bgimg', bgimg);
set(handles.bglist, 'String', bglist);
if strncmp(vers,'7.14.0',6)
    if get(handles.bglist,'Value') > size(bglist,2)
        set(handles.bglist, 'Value', size(bglist,2));
    end
    if get(handles.dfswitch,'Value') == 1
        dfUpdateImg();
    end
else
    if handles.bglist.Value > size(bglist,2)
        set(handles.bglist, 'Value', size(bglist,2));
    end
    if handles.dfswitch.Value == 1
        dfUpdateImg();
    end
end
end

function ClearBg(hObject, callbackdata)

hax = gcf;
handles = getappdata(hax,'handles');
setappdata(hax, 'bglist', {});
setappdata(hax, 'bgimg', []);
setappdata(hax, 'newbg', true);
set(handles.bglist, 'String', {}, 'Value', 0);
UpdateImg();

end

function Addbgbybox(hObject, callbackdata)
hax = gcf;
handles = getappdata(hax, 'handles');
current_file = getappdata(hax,'current_file');
bgstart = handles.bgstart;
bgend = handles.bgend;
start = get(bgstart,'String');
ending = get(bgend,'String');
if ~isempty(start)&~isempty(ending)
    bglist = getappdata(hax, 'bglist');
    bgimg = getappdata(hax, 'bgimg');
    tmpbg = str2num(start):str2num(ending);
    tmpbg = tmpbg';
    tmpbg = cat(2,tmpbg,repmat([current_file], size(tmpbg,1),1));
    bgimg = [bgimg;tmpbg];
    for i = 1:size(bgimg,1)
    str = ['file', num2str(current_file), '; ', 'frame', num2str(bgimg(i,1))];
    bglist = [bglist, str];
    end
    setappdata(hax, 'bgimg', bgimg);
    setappdata(hax, 'newbg',true);
    setappdata(hax, 'bglist', bglist);
    set(handles.bglist, 'String', bglist, 'Value', size(bglist,2));
end
end

function Offset(hObject, callbackdata)
hax = gcf;
vers = version;
if strncmp(vers,'7.14.0',6)
    setappdata(hax,'offset',str2num(get(hObject,'String')));
else
    setappdata(hax,'offset',str2num(hObject.String));
end
handles = getappdata(hax, 'handles');
if handles.dfswitch.Value == 1
    dfUpdateImg();
end
end

function dfUpdateImg()
hax = gcf;
bgimg = getappdata(hax, 'bgimg');
newbg = getappdata(hax, 'newbg');
handles = getappdata(hax, 'handles');
rawimg = getappdata(hax, 'rawimg');
current_frame = getappdata(hax, 'current_frame');
current_file = getappdata(hax, 'current_file');
%calculate background
dfch = getappdata(hax, 'dfch');
bg = zeros;
if isempty(newbg)
    newbg = true;
end
if newbg
    for i = 1:size(bgimg,1)
        %bg = bg + medfilt2(rawimg(:,:,dfch,i),[10,10]);
        bg = bg + rawimg.Data.img(:,:,dfch,bgimg(i,2));
    end
    setappdata(hax,'bg',bg);
    setappdata(hax,'newbg',false);
else
    bg = getappdata(hax,'bg');
end
bg = double(bg);
bg = bg/size(bgimg,1); 
%bg = medfilt2(bg, [3,3]);
bg = imfilter_gaussian(bg,[1 1]);
% calculate df/f of current_frame
%% exponential moving average filter (-3 frames)
% dfof=[];
% for i=2:-1:0
%     ref=medfilt2(squeeze(rawimg(:,:,dfch,current_frame-i)),[4,4]);
%     dfof=cat(3,dfof,(ref-bg)./bg);
% end
% total = exp(-2*inter/0.01)+exp(-inter/0.01)+1;
% dfof = exp(-2*inter/0.01)*dfof(:,:,1)+exp(-inter/0.01)*dfof(:,:,2)+dfof(:,:,3);
% dfof = dfof/total;
offset = getappdata(hax,'offset');
nframes = 5;  % THIS IS A TEMPORAL AVERAGE TERM!!!! (JPM)
%dfof = (medfilt2(rawimg(:,:,dfch,current_frame, current_file),[3,3]) - bg)./(bg + offset);
total_frame = getappdata(hax, 'maxframe');
if current_frame<=nframes
    fg = squeeze(rawimg.Data.img(:,:,dfch,1:(current_frame+nframes)));
elseif current_frame + nframes > total_frame
    fg = squeeze(rawimg.Data.img(:,:,dfch,(current_frame-nframes):total_frame));
else
    fg = squeeze(rawimg.Data.img(:,:,dfch,(current_frame-nframes):(current_frame+nframes)));
end
fg = double(fg);
fg = mean(fg,3);
fg = imfilter_gaussian(fg,[1,1]);
dfof = (fg - bg)./(bg + offset);
% dfof(find(dfof == Inf))=0; % set Inf to 0(zero points in background)
vers = version;
if strncmp(vers,'7.14.0',6)
    clim = [str2num(get(handles.climl,'String')), str2num(get(handles.climh,'String'))];    
else
    clim = [str2num(handles.climl.String), str2num(handles.climh.String)];
end
%dfof(find(dfof<0)) = dfof(find(dfof<0))*(1/abs(clim(1))); %XZ
%dfof(find(dfof>0)) = dfof(find(dfof>0))*(1/abs(clim(2))); %XZ
%imagesc(dfof, 'Parent', handles.imgax, [-1,1]);           %XZ
imagesc(dfof, 'Parent', handles.imgax, clim);            %JPM
%construct colormap
%m = getappdata(hax, 'colormap'); % XZ
colormap(colorize_asymmetric(clim));
%colormap(m); % XZ
% colorbar();
%update bar in stim/rec ax
PlotAx(hax);
%update info panel
UpdateInfo(hax);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%keep editing here%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end



function DfCh(hObject, callbackdata)
hax = gcf;
handles = getappdata(hax,'handles');
setappdata(hax,'dfch',hObject.Value);
if handles.dfswitch.Value == 1
    dfUpdateImg();
end
end

function ChanSelect(hObject, callbackdata)

UpdateImg();

end

function CLim(hObject, callbackdata)

hax = gcf;
handles = getappdata(hax,'handles');


dfhandle = handles.dfswitch;
vers = version;
if strncmp(vers,'7.14.0',6)
    if get(dfhandle,'Value') == 1
        dfUpdateImg();
    end
else
    if dfhandle.Value == 1
        dfUpdateImg();
    end
end
end

function Df(hObject, callbackdata)
vers = version;
if strncmp(vers,'7.14.0',6)
    if get(hObject,'Value') == 1
        dfUpdateImg();
    else
        UpdateImg();
    end
else
    if hObject.Value == 1
        dfUpdateImg();
    else
        UpdateImg();
    end
end
end

function FrameSlider(hObject, callbackdata)
hax = gcf;
file = getappdata(hax, 'file');
current_sweep = getappdata(hax,'current_sweep');
vers = version;
if strncmp(vers,'7.14.0',6)
    framenum = round(get(hObject,'Value'));
else
    framenum = round(hObject.Value);
end
% current_frame = mod(framenum, cur_swep_fram);
% if current_frame == 0
%     current_frame = cur_swep_frame;
% end
framesum = getappdata(hax, 'framesum');
frameprior = sum(file.sweepsum(1:current_sweep));
setappdata(hax, 'current_frame', framenum+frameprior);
dfhandle = findobj(hax, 'Tag', 'df');
if strncmp(vers,'7.14.0',6)
    if get(dfhandle,'Value') == 1
        dfUpdateImg();
    else
        UpdateImg();
    end
else
    if dfhandle.Value == 1
        dfUpdateImg();
    else
        UpdateImg();
    end
end
end

function SweepSlider(hObject, callbackdata)
hax = gcbf;
file = getappdata(hax, 'file');
current_sweep = round(hObject.Value);
current_file = getappdata(hax, 'current_file');
setappdata(hax, 'current_sweep', current_sweep);
frameslider = findobj(hax, 'Tag', 'FramSlide');
sweepsum = getappdata(hax, 'sweepsum');
maxframe = sweepsum(current_sweep+1);
if frameslider.Value > maxframe % check if the frame slider value exceeds the range
    set(frameslider, 'Value', maxframe);
end
if maxframe ~= frameslider.Max
    set(frameslider, 'Value', frameslider.Value-(frameslider.Max-maxframe));
    if frameslider.Value < 1
        set(frameslider, 'Value', 1);
    end
end
set(frameslider, 'Max', maxframe);
set(frameslider, 'SliderStep', [1/(maxframe-1), 4/(maxframe-1)]); %update frameslider settings
framenum = round(frameslider.Value);
framenum = framenum + sum(file.sweepsum(1:current_sweep));
total_frame = framenum;
setappdata(hax, 'total_frame', total_frame); % calculate total frame#(for denoise background setting)
setappdata(hax, 'current_frame', framenum);
setappdata(hax, 'current_file', current_file);
UpdateImg();
end

function DrawROI(hObject, callbackdata)
hax = gcf;
handles = getappdata(hax, 'handles');
roi = impoly(handles.imgax);
wait(roi);
roi_mask = createMask(roi);
PlotActive(roi_mask);
end

function PlotActive(roi_mask)
hax = gcf;
handles = getappdata(hax,'handles');
current_file = getappdata(hax, 'current_file');
framesum = getappdata(hax, 'framesum');
file = getappdata(hax, 'file');

%% locate stims by frame#
ptspersweep = file.ptspersweep;
odor_list = file.odor_list;
datap = file.datapoints;
framep = file.framep;
stim = false; 
meantime = file.meanframetime;
if round(max(datap(:,2)),0) ~= 0
    cutp = diff(datap(:,2));
    start = find(cutp > max(datap(:,2))-10)+1;
    ending = find(cutp < -1*max(datap(:,2))+10);
    stimframe = [];
    for i = 1:size(start,1)
        q = find(framep>=start(i)& framep<=ending(i));
        if isempty(q)
            m = find(framep<=start(i));
            n = find(framep>=ending(i));
            fp = floor((m(end)+1)/2):floor((n(1)+1)/2); 
        else
            fp = floor((q(1)+1)/2):floor((q(end)+1)/2);
        end
        stimframe = [stimframe, fp];         
    end
    stim = true;
end
%% find VNO stimulus window
odor_window = [];
for i = 1:size(odor_list, 1)
    start = odor_list(i,2)+(i-1)*ptspersweep;
    ending = odor_list(i,3)+(i-1)*ptspersweep;
    fstart = find(framep>start,1,'first');
    fend = find(framep<ending,1,'last');
    fstart = floor(fstart/2)+1;
    fend = floor(fend/2);
    odor_window = [odor_window;fstart,fend];
end
%% plot df/f
dfch = getappdata(hax, 'dfch');
bgimg = getappdata(hax, 'bgimg');
rawimg = getappdata(hax, 'rawimg');
total_frame = sum(framesum);
if ~isempty(bgimg)
    bg = zeros;
    for i = 1:size(bgimg,1)
        bg = bg + rawimg.Data.img(:,:,dfch,bgimg(i,1),bgimg(i,2));
    end
    bg = bg/size(bgimg,1);
    bg_roi = sum(bg(roi_mask))/sum(sum(roi_mask));
    mean_roi = [];
    for i = 1:size(file,2)
    for j = 1:framesum(i)
        image = rawimg.Data.img(:,:,dfch,j,i);
        mean_roi = [mean_roi, mean(image(roi_mask))];
    end
    end
    abval = mean_roi - bg_roi;
    relval = abval./bg_roi;
    relval = smooth(1:size(relval,2), relval, 8, 'sgolay');
    active = figure;
    subplot(3,1,1);
    plot(1:total_frame,mean_roi);
    ax=gca;
    ylim = ax.YLim;
    for i = 1:size(odor_window,1);
        if odor_list(i,1) ~= 1
        posx = [odor_window(i,:),odor_window(i,2),odor_window(i,1)];
        posy = [ylim(1),ylim(1),ylim(2),ylim(2)];
        rec = patch(posx,posy,[0.5,0.5,0.5]);
        set(rec,'EdgeColor','none');
        alpha(rec, 0.5);
        tex = num2str(odor_list(i,1));
        text(1/2*sum(odor_window(i,:)),0.1*diff(ylim)+ylim(1),tex);
        end
    end
    if stim
        hold on, plot(stimframe, mean_roi(stimframe)*1.05, 'r*');
        hold off;
    end
    title('absolute average value');
    xlabel('frame');
    subplot(3,1,2);
    plot(1:total_frame, abval);
    ax=gca;
    ylim = ax.YLim;
    for i = 1:size(odor_window,1);
        if odor_list(i,1) ~= 1
        posx = [odor_window(i,:),odor_window(i,2),odor_window(i,1)];
        posy = [ylim(1),ylim(1),ylim(2),ylim(2)];
        rec = patch(posx,posy,[0.5,0.5,0.5]);
        set(rec,'EdgeColor','none');
        alpha(rec, 0.5);
        tex = num2str(odor_list(i,1));
        text(1/2*sum(odor_window(i,:)),0.1*diff(ylim)+ylim(1),tex);
        end
    end
    if stim
        hold on, plot(stimframe, abval(stimframe)*1.05,'r*');
        hold off;
    end
    title('absolute average value - bg average');
    xlabel('frame');
    subplot(3,1,3);
    plot(1:total_frame,relval);
    ax=gca;
    ylim = ax.YLim;
    for i = 1:size(odor_window,1);
        if odor_list(i,1) ~= 1
        posx = [odor_window(i,:),odor_window(i,2),odor_window(i,1)];
        posy = [ylim(1),ylim(1),ylim(2),ylim(2)];
        rec = patch(posx,posy,[0.5,0.5,0.5]);
        set(rec,'EdgeColor','none');
        alpha(rec, 0.5);
        tex = num2str(odor_list(i,1));
        text(1/2*sum(odor_window(i,:)),0.1*diff(ylim)+ylim(1),tex);
        end
    end
    if stim
        hold on, plot(stimframe, relval(stimframe)*1.1, 'r*');
        hold off;
    end
    title('change relative to bg average');
    xlabel('frame');
%     ylim([-1,1]);
    sweepsum = getappdata(hax, 'sweepsum');
    filepath = getappdata(hax, 'filepath');
    odorstream = [];
    sweepindex = [];
    for i=1:size(sweepsum,2)-1
        odorstream = [odorstream;repmat(odor_list(i,1),sweepsum(i+1),1)];
        sweepindex = [sweepindex;repmat(i, sweepsum(i+1),1)];
    end
    csv = [odorstream, relval,meantime,sweepindex];
    csvwrite(strcat(filepath,'df.csv'),csv);
    csvwrite(strcat(filepath,'odorwindow.csv'),odor_window);
else
    mean_roi = [];
    frame_count=0;
    for i=1:size(files,2)
    for j=1:framesum(i)
        image = rawimg.Data.img(:,:,dfch,j,i);
        mean_roi = [mean_roi, mean(image(roi_mask))];
    end
    end
    mean_roi = smooth(1:size(mean_roi,2), mean_roi, 8, 'sgolay');
    active = figure;
    plot(1:total_frame,mean_roi);
    if stim
        hold on, plot(stimframe, mean_roi(stimframe)*1.05, 'r*');
        hold off;
    end
    title('absolute average pixel value');
    xlabel('frame');
end
end

function RangeGUI(hObject, callbackdata)
hax = gcf;
current_frame = getappdata(hax, 'current_frame');
rawimg = getappdata(hax, 'rawimg');
img = rawimg.Data.img(:,:,:,current_frame);
vers = version;
if strncmp(vers,'7.14.0',6)
    tag = get(hObject,'Tag');
else
    tag = hObject.Tag;
end
switch tag
    case 'red_range'
        redhandle = findobj(hax, 'Tag', 'RedCh');
        if strncmp(vers,'7.14.0',6)
            red = get(redhandle,'Value');
        else
            red = redhandle.Value;
        end
        [rgout, csout] = imrangegui(img(:,:,red), getappdata(hax, 'redrange'));
        if ~isempty(rgout)
            setappdata(hax,'redrange', rgout);
        end
    case 'green_range'
        greenhandle = findobj(hax, 'Tag', 'GreenCh');
        if strncmp(vers,'7.14.0',6)
            green = get(greenhandle,'Value');
        else
            green = greenhandle.Value;
        end
        [rgout, csout] = imrangegui(img(:,:,green), getappdata(hax, 'greenrange'));
        if ~isempty(rgout)
            setappdata(hax,'greenrange', rgout);
        end
    case 'blue_range'
        bluehandle = findobj(hax, 'Tag', 'BlueCh');
        if strncmp(vers,'7.14.0',6)
            blue = get(bluehandle,'Value');
        else
            blue = bluehandle.Value;
        end
        [rgout, csout] = imrangegui(img(:,:,blue), getappdata(hax, 'bluerange'));
        if ~isempty(rgout)
            setappdata(hax, 'greenrange', rgout);
        end
end
UpdateImg();

end

function Flow(hObject, callbackdata)
hax = gcf;
handles = getappdata(hax,'handles');
slider = handles.frame_slider;
% current_frame = getappdata(hax, 'current_frame');
set(slider, 'Value', get(slider,'Value')+1);
slider_callback = get(slider,'Callback');
slider_callback(slider, []);
end

function extractinfo = AbfExtract(data)
abf_fields = {'header', 'format', 'units', 'channames',...
    'rate', 's_interval', 'filter', 'moment', 'points',...
    'tag', 'notes', 'flag'};

   if ~isfield(data, abf_fields)
       error(message('MATLAB:guide:StateFieldNotFound', abf_fields, ''));
   end
%% extract frame %%
% preliminary explore
sample_times = (0:size(data.points,1)-1)*data.s_interval; % time for each sweep
desired_signal = 'Frame sig';  % 'IN2' is a copy of frame taking signal
sig = find(strcmpi(desired_signal,data.channames));
frame_data = squeeze(data.points(:,sig,:));
linearized_frame_data = cat(2,frame_data(:));
linearized_time = (0:size(linearized_frame_data,1)-1)*data.s_interval; % total time for each channel
frame_acq_time_points =	linearized_frame_data > 5; % some transition may take more than 1 time points
% sectioning
cut_points = diff([frame_acq_time_points ; 0]); % find section edges
cut_points = [0; cut_points]';
cut_points = find(cut_points);
cut_points_within_frame_stop = cut_points - repmat([0,1],1,size(cut_points,2)/2); % set the stop value the indice of the last data point within frames
cut_points(end) = cut_points(end) -1;
%% averaging on 2
% av_cutp = [];
% for i = 1:size(cut_points,2)/2
%     if i%2 == 1
%         av_cutp = [av_cutp, cut_points(2*i-1)];
%     else
%         av_cutp = [av_cutp, cut_points(2*i)];
%     end
% end
% cut_points = [av_cutp, cut_points(end)];
%%
frame_boarder_time = linearized_time(cut_points); %translate data points into time
% frame_boarder_time = linearized_time(av_cutp); %average on 2

%% extract stimulus train %%
desired_signal = 'Command';
sig = find(strcmpi(desired_signal,data.channames));
stim_train = squeeze(data.points(:, sig, :));
linear_stim_train = cat(2, stim_train(:));
stim_points = linear_stim_train > -60; % extract command signal>-60
stim_points_boundary = diff([stim_points; 0]);
stim_points_boundary = [0; stim_points_boundary]';
stim_points_boundary = find(stim_points_boundary);

%% extract recording %%
desired_signal = 'Record';
sig = find(strcmpi(desired_signal,data.channames));
record_train = squeeze(data.points(:, sig, :));
linear_rec_train = cat(2, record_train(:));
%% extract vno stimulus %%
desired_signal1 = 'automate1';
desired_signal2 = 'automate2';
sig1 = find(strcmpi(desired_signal1, data.channames));
sig2 = find(strcmpi(desired_signal2, data.channames));
auto1 = squeeze(data.points(:,sig1,:));
auto2 = squeeze(data.points(:,sig2,:));
baseline = 2.503; % baseline voltage
stim_list = [];
for i = 1:size(auto1,2)
    dfauto1 = diff(auto1(:,i));
    dfauto2 = diff(auto2(:,i));
    if round(max(dfauto1),2) >= round(max(dfauto2),2)
        current_stim = dfauto1;
        valve_offset = 0;
    else
        current_stim = dfauto2;
        valve_offset = 8;
    end
    if round(max(current_stim),1)> 0 % not a control stim
        stim_start = find(current_stim == max(current_stim))+1;
        stim_end = find(dfauto1>0.1, 1, 'last')+1;
        stim = round(max(current_stim)/0.31,0); % decode automate analog signal
    else
        stim_start = 1;
        stim_end = size(current_stim,1);
        stim = 1; % flush
    end
    stim_list = [stim_list;stim+valve_offset,stim_start,stim_end];
end

%% save extracted info %%
extractinfo = struct('timep', linearized_time, 'framep', cut_points,...
    'stimp', stim_points_boundary, 'ptspersweep',...
    size(data.points,1), 'numsweep', size(data.points,3),'odor_list',stim_list);
end

function InitFig(hs)
ax_stim = axes('Parent', hs, 'Units','Normalized','Tag', 'StimAx','Position',...
    [0.0450 0.0300 0.6200 0.1000], 'NextPlot', 'replacechildren', 'YLimMode', 'auto');

ax_record =  axes('Parent', hs, 'Units','Normalized','Tag','RecAx','XTick',[],...
    'Position', [0.0450 0.1470 0.6200 0.1000], 'NextPlot', 'replacechildren', 'YLimMode', 'auto');

info_panel = uipanel(hs, 'Title', 'Frame Info', 'Tag', 'Info','Position', [0.7000 0.6628 0.2380 0.3351]);


frame_slider = uicontrol(hs, 'Style', 'slider', 'Min', 1, 'Max', getappdata(hs,'maxframe'), 'Value', 1, 'SliderStep',...
    [1/(getappdata(hs,'maxframe')-1),4/(getappdata(hs,'maxframe')-1)],... 
    'Units', 'Normalized', 'Position',[0.093 0.264 0.492 0.02],'Tag', 'FramSlide','CallBack', @FrameSlider);
sweep_slider = uicontrol(hs, 'Style', 'slider', 'Min', 1, 'Max', getappdata(hs, 'numsweep'), 'Value', 1, 'SliderStep',...
    [1/(getappdata(hs, 'numsweep')-1),4/(getappdata(hs, 'numsweep')-1)],...
    'Units', 'Normalized', 'Position', [0.627 0.361 0.015 0.58], 'Tag', 'SweepSlide', 'CallBack', @SweepSlider);
img_ax = axes('Parent', hs, 'Units', 'Normalized', 'Tag', 'Img', 'Position', [0.102,0.325,0.495,0.66], 'NextPlot', 'replacechildren',...
    'XLim', [0 getappdata(hs,'xpix')], 'YLim', [0 getappdata(hs, 'ypix')]);

info_text = uicontrol('Parent', info_panel, 'Style', 'text', 'String', getappdata(hs, 'dispinfo'), 'Units', 'Normalized',...
    'Position', [0.2 0.073 0.522 0.853], 'Tag', 'Text', 'FontSize', 10 );

button_grp = uibuttongroup('Parent', hs, 'Title', 'Control Panel', ...
    'Position', [0.7000 0.0300 0.2380 0.6354], 'Tag', 'control_panel');
red = uicontrol('Parent', button_grp, 'Style', 'listbox', 'String', getappdata(hs, 'chlist'), ...
    'Units', 'Normalized', 'Position', [0.0906  0.209    0.2100    0.144],...
    'Tag', 'RedCh', 'Value', 2, 'TooltipString', 'Select red channel', 'CallBack', @ChanSelect);
green = uicontrol('Parent', button_grp, 'Style', 'listbox', 'String', getappdata(hs, 'chlist'),...
    'Units', 'Normalized','Position', [0.4036    0.209    0.2100    0.144],...
    'Tag', 'GreenCh', 'Value', 1, 'TooltipString', 'Select green channel', 'CallBack', @ChanSelect);
blue = uicontrol('Parent', button_grp, 'Style', 'listbox', 'String', getappdata(hs, 'chlist'),...
    'Units', 'Normalized','Position', [0.7165    0.209    0.2100    0.144],...
    'Tag', 'BlueCh', 'Value', 3, 'TooltipString', 'Select blue channel','CallBack', @ChanSelect);

red_range = uicontrol('Parent', button_grp, 'Style', 'pushbutton', 'String', 'Red'...
, 'Units', 'Normalized','Position', [0.071    0.377    0.2500    0.0500], 'Tag', 'red_range', 'CallBack', @RangeGUI);
green_range = uicontrol('Parent', button_grp, 'Style', 'pushbutton', 'String', 'Green'...
, 'Units', 'Normalized','Position', [0.379     0.377    0.2500    0.0500], 'Tag', 'green_range', 'CallBack', @RangeGUI);
blue_range = uicontrol('Parent', button_grp, 'Style', 'pushbutton', 'String', 'Blue'...
, 'Units', 'Normalized','Position', [0.696    0.377    0.2500    0.0500], 'Tag', 'blue_range', 'CallBack', @RangeGUI);


dfswitch = uicontrol('Parent', button_grp, 'Style', 'checkbox', 'String', 'df/f', 'Units',...
    'Normalized', 'Position', [0.0872    0.135    0.2500    0.0500], 'Value', 0, 'CallBack', @Df,...
    'Tag', 'df');
chlist = getappdata(hs, 'chlist');
dfchselect = uicontrol('Parent', button_grp, 'Style', 'popupmenu', 'String', chlist(1:end-1),...
    'Value', 1, 'Units', 'Normalized', 'Position', [0.2968    0.103    0.2500    0.0800], 'Tag','dfchselect','CallBack',@DfCh);
climhigh = uicontrol('Parent', button_grp, 'Style', 'edit', 'String', '1', ...
    'Tag', 'climhigh', 'Units', 'Normalized', 'Position', [0.6915    0.105    0.2000    0.0700], 'TooltipString','set clim upper bound','CallBack',@CLim);
climlow = uicontrol('Parent', button_grp, 'Style', 'edit', 'String', '-1', ...
    'Tag', 'climlow', 'Units', 'Normalized', 'Position', [0.6915    0.017    0.2000    0.0700], 'TooltipString','set clim lower bound','CallBack',@CLim);
filelist = uicontrol('Parent', button_grp, 'Style', 'listbox', 'String', getappdata(hs, 'filelist'),...
    'Units', 'Normalized', 'Position', [0.0906 0.7472 0.6032 0.1721], 'Tag', 'filelist');
addfile = uicontrol('Parent', button_grp, 'Style', 'pushbutton', 'String', '+', ...
    'Units', 'Normalized', 'Position', [0.7362 0.8329 0.1194 0.0700], 'Tag', 'addfile', 'CallBack', @AddFile);
delfile = uicontrol('Parent', button_grp, 'Style', 'pushbutton', 'String', '-', ...
    'Units', 'Normalized', 'Position', [0.7362 0.7505 0.1194 0.0700], 'Tag', 'delfile', 'CallBack', @DelFile);

bglist = uicontrol('Parent', button_grp, 'Style', 'listbox', 'String', getappdata(hs, 'filelist'),...
    'Units', 'Normalized', 'Position', [0.0906 0.5482 0.6032 0.1685], 'Tag', 'bglist');
addbg = uicontrol('Parent', button_grp, 'Style', 'pushbutton', 'String', '+', ...
    'Units', 'Normalized', 'Position', [0.7362 0.6418 0.1194 0.0700], 'Tag', 'addbg', 'CallBack', @AddBg);
delbg = uicontrol('Parent', button_grp, 'Style', 'pushbutton', 'String', '-', ...
    'Units', 'Normalized', 'Position', [0.7362 0.5594 0.1194 0.0700], 'Tag', 'delbg', 'CallBack', @DelBg);
clearbg = uicontrol('Parent', button_grp, 'Style', 'pushbutton', 'String', 'clear', ...
    'Units', 'Normalized', 'Position', [0.86 0.601 0.1194 0.0700], 'Tag', 'clearbg', 'CallBack', @ClearBg);
bgstart = uicontrol('Parent', button_grp, 'Style', 'edit', 'String', '', ...
    'Tag', 'bgstart', 'Units', 'Normalized', 'Position', [0.0917 0.4639 0.2500 0.07007], 'TooltipString','set background start frame','CallBack',@Addbgbybox);
bgend = uicontrol('Parent', button_grp, 'Style', 'edit', 'String', '', ...
    'Tag', 'bgend', 'Units', 'Normalized', 'Position', [0.3997 0.4639 0.2500 0.0700], 'TooltipString','set background end frame','CallBack',@Addbgbybox);
offset = uicontrol('Parent', button_grp, 'Style', 'edit', 'String', '0', ...
    'Tag', 'offset', 'Units', 'Normalized', 'Position', [0.3632 0.0170 0.2000 0.0700], 'CallBack',@Offset, 'TooltipString','offset');

roi = uicontrol('Parent', button_grp, 'Style', 'pushbutton', 'String', 'ROI',...
    'Units', 'Normalized', 'Position', [0.0706,0.022,0.163,0.07], 'CallBack', @DrawROI, 'TooltipString', 'Draw ROI');
flow = uicontrol('Parent', button_grp, 'Style', 'pushbutton', 'String', 'flow',...
    'Visible','Off', 'CallBack', @Flow, 'Tag', 'ImFlow');
handles = struct('stim_ax', ax_stim, 'rec_ax', ax_record, 'imgax', img_ax, 'info_panel',...
    info_panel, 'frame_slider', frame_slider, 'sweep_slider', sweep_slider,...
    'button_grp', button_grp,'redch', red, 'greench', green, 'bluech', blue,...
    'redra_btn', red_range, 'greenra_btn', green_range, 'bluera_btn', blue_range,...
    'dfswitch', dfswitch, 'chlist', chlist, 'dfch',...
    dfchselect, 'climh', climhigh, 'climl', climlow,'filelist',filelist,...
    'addfile_btn', addfile, 'delfile_btn', delfile, 'bglist', bglist,...
    'addbg_btn', addbg, 'delbg_btn', delbg, 'offset', offset, 'roi', roi, 'bgstart',bgstart, 'bgend',bgend,...
    'info_text',info_text);
setappdata(hs, 'handles', handles);
end

