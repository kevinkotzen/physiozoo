function varargout = Configure_Dialog(varargin)
% CONFIGURE_DIALOG MATLAB code for Configure_Dialog.fig
%      CONFIGURE_DIALOG, by itself, creates a new CONFIGURE_DIALOG or raises the existing
%      singleton*.
%
%      H = CONFIGURE_DIALOG returns the handle to a new CONFIGURE_DIALOG or the handle to
%      the existing singleton*.
%
%      CONFIGURE_DIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONFIGURE_DIALOG.M with the given input arguments.
%
%      CONFIGURE_DIALOG('Property','Value',...) creates a new CONFIGURE_DIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Configure_Dialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Configure_Dialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Configure_Dialog

% Last Modified by GUIDE v2.5 16-Jul-2018 20:17:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Configure_Dialog_OpeningFcn, ...
    'gui_OutputFcn',  @Configure_Dialog_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Configure_Dialog is made visible.
function Configure_Dialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Configure_Dialog (see VARARGIN)

% Choose default command line output for Configure_Dialog
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
cmd = FGV_CMD;
UniqueMap = FGV_DATA(cmd.GET);
ENABLE = [{'on'};{'off'}];
FIRST_ITEM = [{'Select'};{'Auto'}];
Config = ReadYaml('Loader Config.yml');
Names = fieldnames(Config);

for i = 1 : length(Names)-1
    localName = cell2mat(Names(i));
    if i > 1
        strItems = Config.(localName)';
    else
        strItems =  fieldnames(Config.(localName));
    end
    set(handles.(['pm_',localName]),'string',strItems,'value',1)
end

hCh = findobj(handles.figure1,'style','popupmenu');
set(hCh,'backgroundcolor',[ 1.0000    0.8667    0.8667],'value',1,'enable','on')

    %% ------------------- Set Params Control ---------------------------------
    hFileParams =  findobj(handles.uipGeneral,'style','popupmenu');

    for iParameter = 1 : length(hFileParams)
        hObj = hFileParams((iParameter));
        pName = get(hObj,'tag');
        try
            strParamValue = replace(strtrim(lower(UniqueMap(pName(4:end)))),' ','_');
        catch
            continue
        end
        Set_Popupmenu(hObj, strParamValue, 'off')
        Channels.General.(pName(4:end)) = strParamValue;
    end
    
%     Item = Get_Popupmenu_Item_Text(handles.pm_file_type)
%     set(handles.pm_data_type,'string',['select';strItems],'value',1)


%% -------------- Init Fs control ---------------------------------------
try
    eboxColor = 'w';
    eboxString = UniqueMap('fs');
    enable = 'off';
catch
    eboxColor = [ 1.0000    0.8667    0.8667];
    eboxString = NaN;
    enable = 'on';
end
set(handles.ebFs,'backgroundcolor',eboxColor,'string',eboxString,'enable',enable)
%% ----------- Init All popupmenu controls----------------


%% --------------Get data -------------------------------------
try
    data = UniqueMap('rawData');
    Data_Size = size(data,2);
    set(handles.figure1,'userdata',data)
catch
     btnOK_Callback(hObject, eventdata, handles)
    return
end

%% --------------Get Channels  -------------------------------------
if isKey(UniqueMap,'channels')
    rawChannels = UniqueMap('channels');
else
    rawChannels = zeros(1,Data_Size);
end
if length(rawChannels) ~= Data_Size
     UniqueMap('MSG') = 'Channel Info problem';
    FGV_DATA(cmd.SET,UniqueMap);
     btnOK_Callback(hObject, eventdata, handles)
%     figure1_CloseRequestFcn(hObject, eventdata, handles)
    return
end

%% ---------------Get Channels Information -------------
Channels.Time.Enable = 0;
Channels.Time.No = 0;
Channels.Time.Scale_factor= 1;
Channels.Time.Fs = eboxString;
Channels.Time.Unit = 'second';
Channels.Time.Type = 'time';
Channels.Data.Enable = 0;
Channels.Data.No =  Data_Size;
Channels.Data.Scale_factor = 1;
Channels.Data.Data = data(:,Channels.Data.No);
Channels.Data.Unit = 'select';
Channels.Data.Type = 'select';
for i = 1 : Data_Size
    Channels.Data.Names{i} = sprintf('Ch%02d',i);
end
Channels.Data.Names = Channels.Data.Names';
status_enable =2;
if UniqueMap('IsHeader')
    for iCh = 1 : length(rawChannels)
        try
            localChannel = cell2mat(rawChannels(iCh));
            type = lower(localChannel.type);
            Channels.Data.Names{iCh} =localChannel.name;
            switch type
                case 'time'
                    type = 'Time';
                otherwise
                    type = 'Data';
            end
            if localChannel.enable
                Channels = Update_Channel_Info(Channels,iCh,localChannel,data,type,Config);
            end
        catch
        end
    end
    status_enable = 1;
end
if ~Channels.Time.No
    if sum((diff(data(:,1)))>0) < (length(data)-1)
        Channels.Time.Data = ((1:length(data))*(1/Channels.Time.Fs))';
     else
        status_enable = 1;
        Channels.Time.Data = data(:,1);
        Channels = Update_Fs(Channels,handles,enable);
    end
    if size(data,2) <= 1
        status_enable = 2;
    end
else
    status_enable = 2;
    Channels = Update_Fs(Channels,handles,enable);
end
set(handles.pm_time_channel,'string',[FIRST_ITEM(status_enable);Channels.Data.Names])
set(handles.pm_time_channel,'value',Channels.Time.No+1,'backgroundcolor','w','enable',cell2mat(ENABLE(status_enable)))


    %% Set pm
    set(handles.pm_data_unit,'string',['select';Config.data_type.(Channels.Data.Type)'])
%     set(handles.pm_data_unit,'string',['select';Config.file_type.(Channels.General.file_type).unit'])
    %     DataChannel_ChangeString(handles.pm_data_unit,Channels.General.File_Type)
    Set_Popupmenu(handles.pm_time_unit, Channels.Time.Unit, cell2mat(ENABLE(status_enable)))
    Set_Popupmenu(handles.pm_data_unit, Channels.Data.Unit, cell2mat(ENABLE(Channels.Data.Enable+1)))
    Set_Popupmenu(handles.pm_data_type, Channels.Data.Type, cell2mat(ENABLE(Channels.Data.Enable+1)))
    Channels = UpdateDataChannel(Channels,handles);
    Channels = UpdateTimeChannel(Channels,handles);
    PlotData(Channels,handles.axData)
   

set(handles.pm_channels_name,'string',Channels.Data.Names','value',Channels.Data.No,'backgroundcolor','w','enable','on')



% UIWAIT makes Configure_Dialog wait for user response (see UIRESUME)
% uiwait(handles.figure1);

setappdata(handles.figure1,'Channels',Channels)
setappdata(handles.figure1,'Config',Config)
switch CheckStatus(handles.ebFs, eventdata, handles);
    case 'onn'
            btnOK_Callback(handles.btnOK, 0, handles);
            return
    otherwise
end
% --- Outputs from this function are returned to the command line.
function varargout = Configure_Dialog_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
try
varargout{1} = handles.output;
catch
    varargout{1} = [];
end

% --- Executes on selection change in pm_integration_level.
function pm_integration_level_Callback(hObject, eventdata, handles)
% hObject    handle to pm_integration_level (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_integration_level contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_integration_level
Channels = getappdata(handles.figure1,'Channels');
Channels.General.integration_level = Get_Popupmenu_Item_Text(hObject);
CheckStatus(hObject, eventdata, handles);
setappdata(handles.figure1,'Channels',Channels)

% --- Executes during object creation, after setting all properties.
function pm_integration_level_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_integration_level (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in pm_data_unit.
function pm_data_unit_Callback(hObject, eventdata, handles)
% hObject    handle to pm_data_unit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_data_unit contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_data_unit

Channels = getappdata(handles.figure1,'Channels');
Channels.Data.Unit = Get_Popupmenu_Item_Text(hObject);
Channels.Data.Scale_factor =  ScaleFactor('data',Channels.Data.Unit);
Channels = UpdateDataChannel(Channels,handles);
Channels = UpdateTimeChannel(Channels,handles);
PlotData(Channels,handles.axData)
CheckStatus(hObject, eventdata, handles);
setappdata(handles.figure1,'Channels',Channels)



% --- Executes during object creation, after setting all properties.
function pm_data_unit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_data_unit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pm_mammal.
function pm_mammal_Callback(hObject, eventdata, handles)
% hObject    handle to pm_mammal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_mammal contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_mammal
Channels = getappdata(handles.figure1,'Channels');
Channels.General.mammal = Get_Popupmenu_Item_Text(hObject);
CheckStatus(hObject, eventdata, handles);
setappdata(handles.figure1,'Channels',Channels)

% --- Executes during object creation, after setting all properties.
function pm_mammal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_mammal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ebFs_Callback(hObject, eventdata, handles)
% hObject    handle to ebFs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ebFs as text
%        str2double(get(hObject,'String')) returns contents of ebFs as a double
data = get(handles.figure1,'userdata');
Fs = str2double(get(hObject,'string'));
if isnan(Fs) || Fs > 10000
    Fs = NaN;
    set(hObject,'string',Fs)
end
Channels = getappdata(handles.figure1,'Channels');
Channels.Time.Fs = Fs;
Channels = SetTimeChannel(handles.pm_time_channel,Channels,data);
Channels = UpdateDataChannel(Channels,handles);
Channels = UpdateTimeChannel(Channels,handles);
PlotData(Channels,handles.axData)
CheckStatus(hObject, eventdata, handles);
setappdata(handles.figure1,'Channels',Channels)





% --- Executes during object creation, after setting all properties.
function ebFs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ebFs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pm_file_type.
function pm_file_type_Callback(hObject, eventdata, handles)
% hObject    handle to pm_file_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_file_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_file_type
ENABLE = [{'on'};{'off'}];
Channels = getappdata(handles.figure1,'Channels');
Config = getappdata(handles.figure1,'Config');
Channels.General.file_type = Get_Popupmenu_Item_Text(hObject);
set(handles.pm_data_unit,'string',Config.file_type.(Channels.General.file_type).unit')
set(handles.pm_data_type,'string',['select';Config.file_type.(Channels.General.file_type).type'],'value',1)
Set_Popupmenu(handles.pm_data_unit, Channels.Data.Unit, cell2mat(ENABLE(Channels.Data.Enable+1)))
Set_Popupmenu(handles.pm_data_type, Channels.Data.Type, cell2mat(ENABLE(Channels.Data.Enable+1)))

CheckStatus(hObject, eventdata, handles);
setappdata(handles.figure1,'Channels',Channels)


% --- Executes during object creation, after setting all properties.
function pm_file_type_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_file_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in btnOK.
function btnOK_Callback(hObject, eventdata, handles)
% hObject    handle to btnOK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Channels = getappdata(handles.figure1,'Channels');
assignin('base','Channels',Channels)
cmd = FGV_CMD;
UniqueMap = FGV_DATA(cmd.GET);
UniqueMap('DATA') = Channels;
FGV_DATA(cmd.SET,UniqueMap);
try 
%     eventdata.Source
my_closereq(handles.figure1)
%     closereq
catch
  
end

% --- Executes on button press in btnCancel.
function btnCancel_Callback(hObject, eventdata, handles)
% hObject    handle to btnCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cmd = FGV_CMD;
UniqueMap = FGV_DATA(cmd.GET);
UniqueMap('MSG') = 'Canceled';
FGV_DATA(cmd.SET,UniqueMap);

my_closereq(handles.figure1)


% Check if disable
function Status = CheckStatus(hObject, eventdata, handles)
% hObject    handle to btnCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hCh = [findobj(handles.uipGeneral,'style','popupmenu');handles.pm_data_unit;handles.pm_time_unit];
Status = 'off';
if prod([cell2mat(get(hCh,'value'))-1;~isnan(str2double(get(handles.ebFs,'str')))])
    Status = 'on';
end
set(handles.btnOK,'enable',Status)
switch hObject
    case handles.ebFs
        status = isnan(str2double(get(handles.ebFs,'str')));
     case {handles.pm_time_channel,handles.pm_channels_name}
         status = 0;
    otherwise
        status = ~(get(hObject,'value')-1);
end

if status
    set(hObject,'backgroundcolor',[ 1.0000    0.8667    0.8667])
else
    set(hObject,'backgroundcolor','white')
end


% --- Executes on selection change in pm_channels_name.
function pm_channels_name_Callback(hObject, eventdata, handles)
% hObject    handle to pm_channels_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_channels_name contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_channels_name
Channels = getappdata(handles.figure1,'Channels');
Channels.Data.No = get(hObject,'value');
Channels = UpdateDataChannel(Channels,handles);
Channels = UpdateTimeChannel(Channels,handles);
PlotData(Channels,handles.axData)

CheckStatus(hObject, eventdata, handles);
setappdata(handles.figure1,'Channels',Channels)


% --- Executes during object creation, after setting all properties.
function pm_channels_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_channels_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnSaveAs.
function btnSaveAs_Callback(hObject, eventdata, handles)
% hObject    handle to btnSaveAs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)





% --- Executes on selection change in pm_time_channel.
function pm_time_channel_Callback(hObject, eventdata, handles)
% hObject    handle to pm_time_channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_time_channel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_time_channel
Channels = getappdata(handles.figure1,'Channels');
data = get(handles.figure1,'userdata');
Channels.Time.No = Get_Popupmenu_Item_Text(hObject);
Channels = SetTimeChannel(handles.pm_time_channel,Channels,data);
PlotData(Channels,handles.axData)
CheckStatus(hObject, eventdata, handles);
setappdata(handles.figure1,'Channels',Channels)


% --- Executes during object creation, after setting all properties.
function pm_time_channel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_time_channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Get Scale Factor 
function scale_factor = ScaleFactor(type,unit)
switch type
    case 'time'
        switch lower(unit)
            case 'millisecond'
                scale_factor = 0.001;
            case 'second'
                scale_factor = 1;
            case 'index'
                scale_factor = 1;
            otherwise
                scale_factor = 1;
        end
    case {'data','peak','interval'}
        switch lower(unit)
            case 'millivolt'
                scale_factor = 1;
            case 'volt'
                scale_factor = 1000;
            case 'microvolt'
                scale_factor = 0.001;
            case 'millisecond'
                scale_factor = 0.001;
            case 'second'
                scale_factor = 1;
            case 'index'
                scale_factor = 0;
            case 'bpm'
                scale_factor = 1;
            otherwise
                scale_factor = 1;
        end
    otherwise
        scale_factor = 1;
end



function pm_time_unit_Callback(hObject, eventdata, handles)
% hObject    handle to pm_file_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_file_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_file_type
Channels = getappdata(handles.figure1,'Channels');
Channels.Time.Unit = Get_Popupmenu_Item_Text(hObject);
Channels.Time.Scale_factor =  ScaleFactor('time',Channels.Time.Unit);
Channels = UpdateDataChannel(Channels,handles);
Channels = UpdateTimeChannel(Channels,handles);
Channels = Update_Fs(Channels,handles,get(handles.ebFs,'enable'));
PlotData(Channels,handles.axData)
CheckStatus(hObject, eventdata, handles);
setappdata(handles.figure1,'Channels',Channels)

% --- Executes during object creation, after setting all properties.
function pm_time_unit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_file_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- 
function Set_Popupmenu(hObject, pName, status)
strNames = lower(get(hObject,'string'));  
[Lia,LocB] = ismember(pName,strNames);
    if Lia
        set(hObject,'value',LocB,'backgroundcolor','w','enable',status)
    else
        set(hObject,'value',1)
    end

    
    
     
    % --- 
function Item = Get_Popupmenu_Item_Text(hObject)

val = get(hObject,'value');
str = get(hObject,'string');
if iscell(str)
    Item = cell2mat(str(val));
else
    Item = str(val);
end




%% ------------------
function DataChannel_ChangeString(hObject,File_Type)
    set(hObject,'string',header.file_type.(Channels.General.file_type).unit')
    if 0
        timeUnits = [{'Select Units'};{'milisecond'};{'second'};{'minute'};{'datapoint'}];
        signalUnits = [{'Select Units'};{'microvolt'};{'millivolt'};{'volt'};{'datapoint'}];
        switch lower(File_Type)
            case 'beating_rate'
                str = timeUnits;
            case 'electrography'
                str = signalUnits;
            otherwise
                str = timeUnits;
        end
        set(hObject,'string',str)
    end

%% ------------------
function Channels = Update_Channel_Info(Channels,iCh,localChannel,data,type,Config)
Channels.(type).No = iCh;
Channels.(type).Unit = Update_Unit(Config,lower(localChannel.unit));
Channels.(type).Scale_factor =  ScaleFactor(lower(type),Channels.(type).Unit);
Channels.(type).Data = data(:,iCh);
Channels.(type).Enable = 1;
Channels.(type).Type = replace(strtrim(lower(localChannel.type)),' ','_');

 

%% ------------------
function strUnit = Update_Unit(Config,unit)
AllUnits = fieldnames(Config.units);
strUnit = '';
for i = 1 : length(AllUnits)
    unitName = cell2mat(AllUnits(i));
    if sum(strcmp(Config.units.(unitName),unit))
         strUnit = unitName;
         break
    end
end


%% ------------------------- Set Time Channel
function Channels = SetTimeChannel(hObject,Channels,data)
TimeChannel = int32(str2double(Get_Popupmenu_Item_Text(hObject)));
%     TimeChannel = get(hObject,'value');
if TimeChannel
    Channels.Time.Data = data(:,TimeChannel*Channels.Time.Scale_factor);
else
    Channels.Time.Data = (((1:length(data))*(1/(Channels.Time.Fs)))'*Channels.Time.Scale_factor)';
end






  %% -----------------  Plot Data ------------------
    function PlotData(Channels,hAx)
        try
            iWc = int32(length(Channels.Data.Data)/2);
            switch Channels.Data.Type
                case 'electrography'
                    title = 'Amplitude [volt]';
                    Span = GetSpan(Channels);
                otherwise
                    title = 'Amplitude [sec]';
                    Span =int32(length(Channels.Data.Data)/1000);
                    if ~Span || Span < 10
                        Span = iWc;
                    end
                    
            end
            dataWindow = iWc-Span+1:iWc+Span-1;
            plot(hAx,Channels.Time.Data(dataWindow),Channels.Data.Data(dataWindow))
            ylabel(hAx,title)
        catch
        end
       
        
%% ---------- Get Span Function ------------------
        function Span = GetSpan(Channels)
            Y = fft(Channels.Data.Data-mean(Channels.Data.Data));
            Fs = Channels.Time.Fs;
            L = length(Channels.Data.Data);
            P2 = abs(Y/L);
            P1 = P2(1:L/2+1);
            P1(2:end-1) = 2*P1(2:end-1);
            f = Fs*(0:(L/2))/L;
            [~,k] = max(P1);
            Span = 1/f(k)*10*Fs;
            
    %% ------------------ Update Data Channels Function --------------
        function Channels = UpdateDataChannel(Channels,handles)
            data = get(handles.figure1,'userdata');
            switch lower(Channels.Data.Type)
                case 'electrography'
                      if Channels.Data.Scale_factor
                        Fs = 1;
                        Scale_factor = Channels.Data.Scale_factor;
                    else
                        Fs = Channels.Time.Fs;
                        Scale_factor = 1;
                    end
                    Channels.Data.Data = (data(:,Channels.Data.No)/Fs)*Scale_factor;
                case {'data','interval'}
                    if Channels.Data.Scale_factor
                        Fs = 1;
                        Scale_factor = Channels.Data.Scale_factor;
                    else
                        Fs = Channels.Time.Fs;
                        Scale_factor = 1;
                    end
                    Channels.Data.Data = (data(:,Channels.Data.No)/Fs)*Scale_factor;
                case 'peak'
                    if Channels.Data.Scale_factor
                        Fs = 1;
                        Scale_factor = Channels.Data.Scale_factor;
                    else
                        Fs = Channels.Time.Fs;
                       Scale_factor = 1;
                    end
                    dData = diff((data(:,Channels.Data.No)));
%                     dData(end+1) = dData(end);
                    Channels.Data.Data = (dData/Fs)*Scale_factor;
                case 'beating_rate'
                    Channels.Data.Data =60./data(:,Channels.Data.No)*Channels.Data.Scale_factor;
                otherwise
            end
                 
    %% ------------------ Update Time Channel Function --------------
        function Channels = UpdateTimeChannel(Channels,handles)
            data = get(handles.figure1,'userdata');
                    
            switch lower(Channels.Data.Type)
                case 'electrography'
                    if sum((diff(data(:,1)))>0) < (length(data)-1)
                        Channels.Time.Data = ((1:length(data))*(1/Channels.Time.Fs))';
                    else
                        Channels.Time.Data = data(:,1)*Channels.Time.Scale_factor;
                    end
                case 'peak'
                    if Channels.Data.Scale_factor
                        Fs = 1;
                        %                         Scale_factor = Channels.Data.Scale_factor;
                        Scale_factor = Channels.Data.Scale_factor;
                    else
                        Fs = Channels.Time.Fs;
                        Scale_factor = 1;
                    end
                    Channels.Time.Data = (data(:,Channels.Data.No)/Fs)*Scale_factor';
                case 'interval'
                     if Channels.Data.Scale_factor
                        Fs = 1;
                        %                         Scale_factor = Channels.Data.Scale_factor;
                        Scale_factor = 1;
                    else
                        Fs = 1;
                        Scale_factor = 1;
                    end
                    Channels.Time.Data = ((cumsum(Channels.Data.Data)/Fs)*Scale_factor)';
                case 'beating_rate'
                    Fs = 1;
                    Scale_factor = 1;
                    Channels.Time.Data = ((cumsum(Channels.Data.Data)/Fs)*Scale_factor)';
                otherwise
            end
                 

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(hObject)



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject)


% --- Executes on selection change in pm_data_type.
function pm_data_type_Callback(hObject, eventdata, handles)
% hObject    handle to pm_data_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns pm_data_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pm_data_type

ENABLE = [{'on'};{'off'}];
Channels = getappdata(handles.figure1,'Channels');
Config = getappdata(handles.figure1,'Config');
Channels.Data.Type = Get_Popupmenu_Item_Text(hObject);
set(handles.pm_data_unit,'string',['select';Config.data_type.(Channels.Data.Type)'])
Set_Popupmenu(handles.pm_data_unit, Channels.Data.Unit, cell2mat(ENABLE(Channels.Data.Enable+1)))

CheckStatus(hObject, eventdata, handles);
setappdata(handles.figure1,'Channels',Channels)





% --- Executes during object creation, after setting all properties.
function pm_data_type_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pm_data_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% ------ Check and Update Fs function --------------
    function Channels = Update_Fs(Channels,handles,enable)
        switch Channels.Data.Type
            case 'electrography'
                if str2double(get(handles.ebFs,'string')) ~= 1/(mean(diff(Channels.Time.Data))*Channels.Time.Scale_factor)
                    Channels.Time.Fs = 1/(mean(diff(Channels.Time.Data))*Channels.Time.Scale_factor);
                    set(handles.ebFs,'string', num2str(Channels.Time.Fs),'enable',enable)
                end
            otherwise
        end