function [sts, infos] = pspm_hb2hp(fn, sr, chan, options)
% pspm_hb2hp transforms heart beat data into an interpolated heart rate
% signal and adds this as an additional channel to the data file
% 
% sts = pspm_hb2hp(fn, sr, chan, options)
%       fn: data file name
%       sr: new sample rate for heart period channel
%       chan: number of heart beat channel (optional, default: first heart
%             beat channel); if empty (= 0 / []) will be set to default
%             value
%       options: optional arguments [struct]
%           .replace        if specified and 1 when existing data should be
%                           overwritten
%           .limit          [struct] Specifies upper and lower limit for heart
%                           periods. If the limit is exceeded, the values will
%                           be ignored/removed and interpolated.
%
%               .upper      [numeric] Specifies the upper limit of the
%                           heart periods in seconds. Default is 2.
%               .lower      [numeric] Specifies the lower limit of the
%                           heart periods in seconds. Default is 0.2.
%__________________________________________________________________________
% PsPM 3.0
% (C) 2008-2015 Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

% $Id: pspm_hb2hp.m 450 2017-07-03 15:17:02Z tmoser $
% $Rev: 450 $


% initialise & user output
% -------------------------------------------------------------------------
sts = -1;
global settings;
if isempty(settings), pspm_init; end;

try options.replace; catch options.replace = 0; end;
try options.limit; catch options.limit = struct(); end;
try options.limit.upper; catch options.limit.upper = 2; end;
try options.limit.lower; catch options.limit.lower = 0.2; end;

% check input
% -------------------------------------------------------------------------
if nargin < 1
    warning('No input. Don''t know what to do.'); return;
elseif ~ischar(fn)
    warning('Need file name string as first input.'); return;
elseif nargin < 2
    warning('No sample rate given.'); return; 
elseif ~isnumeric(sr)
    warning('Sample rate needs to be numeric.'); return;
elseif nargin < 3 || isempty(chan) || (isnumeric(chan) && (chan == 0))
    chan = 'hb';
elseif ~isnumeric(chan) && ~strcmpi(chan, 'hb')
    warning('Channel number must be numeric'); return;
end;

% get data
% -------------------------------------------------------------------------
[nsts, dinfos, data] = pspm_load_data(fn, chan);
if nsts == -1, return; end;
if numel(data) > 1
    fprintf('There is more than one heart beat channel in the data file. Only the first of these will be analysed.');
    data = data(1);
end;

% interpolate
% -------------------------------------------------------------------------
hb  = data{1}.data;
ibi = diff(hb);
idx = find(ibi > options.limit.lower & ibi < options.limit.upper);
hp = 1000 * ibi; % in ms
newt = (1/sr):(1/sr):dinfos.duration;
newhp = interp1(hb(idx+1), hp(idx), newt, 'linear' ,'extrap'); % assign hr to following heart beat 


% save data
% -------------------------------------------------------------------------
newdata.data = newhp(:);
newdata.header.sr = sr;
newdata.header.units = 'ms';
newdata.header.chantype = 'hp';

if options.replace
    action = 'replace';
else
    action = 'add';
end;
o.msg.prefix = 'Heart beat converted to heart period and';
[sts, winfos] = pspm_write_channel(fn, newdata, action, o);
if nsts == -1, return; end;
infos.channel = winfos.channel;

sts = 1;
