function varargout = doERPanalysis(varargin)
% DOERPANALYSIS MATLAB code for doERPanalysis.fig
%      DOERPANALYSIS, by itself, creates a new DOERPANALYSIS or raises the existing
%      singleton*.
%
%      H = DOERPANALYSIS returns the handle to a new DOERPANALYSIS or the handle to
%      the existing singleton*.
%
%      DOERPANALYSIS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DOERPANALYSIS.M with the given input arguments.
%
%      DOERPANALYSIS('Property','Value',...) creates a new DOERPANALYSIS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before doERPanalysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to doERPanalysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help doERPanalysis

% Last Modified by GUIDE v2.5 04-Jul-2018 15:31:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @doERPanalysis_OpeningFcn, ...
                   'gui_OutputFcn',  @doERPanalysis_OutputFcn, ...
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


% --- Executes just before doERPanalysis is made visible.
function doERPanalysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to doERPanalysis (see VARARGIN)

% Choose default command line output for doERPanalysis
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes doERPanalysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = doERPanalysis_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in button1.
function button1_Callback(hObject, eventdata, handles)
% hObject    handle to button1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of button1
set(handles.button1,'value',1);
set(handles.button2,'value',0)
doERPanalysis_new

% --- Executes on button press in button2.
function button2_Callback(hObject, eventdata, handles)
% hObject    handle to button2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of button2
set(handles.button1,'value',0);
set(handles.button2,'value',1)
doERPanalysis_redo


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection=questdlg(['¹Ø±Õ ' get(handles.figure1,'Name') '?'],...
    ['Close ' get(handles.figure1,'Name') '...'],...
    'ÊÇ','·ñ','ÊÇ');
if strcmp(selection,'·ñ')
    return;
end
% Hint: delete(hObject) closes the figure
delete(hObject);
