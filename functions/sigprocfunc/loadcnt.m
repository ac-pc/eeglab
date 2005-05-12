% loadcnt() - Load a Neuroscan continuous signal file.
%
% Usage:
%   >> cnt = loadcnt(file, varargin) 
%
% Inputs:
%   filename - name of the file with extension
%
% Optional inputs:
%  't1'         - start at time t1, default 0
%  'sample1'    - start at sample1, default 0, overrides t1
%  'lddur'      - duration of segment to load, default = whole file
%  'ldnsamples' - number of samples to load, default = whole file, 
%                 overrides lddur
%  'scale'      - ['on'|'off'] scale data to microvolt (default:'on')
%  'dataformat' - ['int16'|'int32'] default is 'int16' for 16-bit data.
%                 Use 'int32' for 32-bit data.
%  'blockread'  - [integer] by default it is automatically determined 
%                 from the file header, though sometimes it finds an 
%                 incorect value, so you may want to enter a value manually 
%                 here (1 is the most standard value).
%
% Outputs:
%  cnt          - structure with the continuous data and other informations
%               cnt.header
%               cnt.electloc
%               cnt.data
%               cnt.tag
%
% Authors:   Sean Fitzgibbon, Arnaud Delorme, 2000-
%
% Note: function original name was load_scan41.m
%
% Known limitations: 
%  For more see http://www.cnl.salk.edu/~arno/cntload/index.html    

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2000 Sean Fitzgibbon, <psspf@id.psy.flinders.edu.au>
% Copyright (C) 2003 Arnaud Delorme, Salk Institute, arno@salk.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% $Log: not supported by cvs2svn $
% Revision 1.19  2004/11/23 17:08:57  hilit
% fixed a typo
%
% Revision 1.18  2004/09/14 23:31:57  arno
% dataformat
%
% Revision 1.17  2004/09/14 23:27:44  arno
% opening file as little endian
%
% Revision 1.16  2004/03/19 18:52:42  arno
% blockread msg
%
% Revision 1.15  2004/03/19 18:51:26  arno
% allowing blockread option
%
% Revision 1.14  2003/11/05 16:38:08  arno
% reading events for 32-bit data
%
% Revision 1.13  2003/10/30 19:41:01  arno
% updating error message
%
% Revision 1.12  2003/10/30 19:23:54  arno
% adding revision line
%

function [f,lab,ev2p] = loadcnt(filename,varargin)

if ~isempty(varargin)
	 r=struct(varargin{:});
else r = []; 
end;

try, r.t1;         catch, r.t1=0; end
try, r.sample1;    catch, r.sample1=[]; end
try, r.lddur;      catch, r.lddur=[]; end
try, r.ldnsamples; catch, r.ldnsamples=[]; end
try, r.scale;      catch, r.scale='on'; end
try, r.blockread;  catch, r.blockread = []; end
try, r.dataformat; catch, r.dataformat = 'int16'; end


sizeEvent1 = 8  ; %%% 8  bytes for Event1  
sizeEvent2 = 19 ; %%% 19 bytes for Event2 

type='cnt';
if nargin ==1 
    scan=0;
end     

fid = fopen(filename,'r', 'l');
disp(['Loading file ' filename ' ...'])

h.rev               = fread(fid,12,'char');
h.nextfile          = fread(fid,1,'long');
h.prevfile          = fread(fid,1,'long');
h.type              = fread(fid,1,'char');
h.id                = fread(fid,20,'char');
h.oper              = fread(fid,20,'char');
h.doctor            = fread(fid,20,'char');
h.referral          = fread(fid,20,'char');
h.hospital          = fread(fid,20,'char');
h.patient           = fread(fid,20,'char');
h.age               = fread(fid,1,'short');
h.sex               = fread(fid,1,'char');
h.hand              = fread(fid,1,'char');
h.med               = fread(fid,20, 'char');
h.category          = fread(fid,20, 'char');
h.state             = fread(fid,20, 'char');
h.label             = fread(fid,20, 'char');
h.date              = fread(fid,10, 'char');
h.time              = fread(fid,12, 'char');
h.mean_age          = fread(fid,1,'float');
h.stdev             = fread(fid,1,'float');
h.n                 = fread(fid,1,'short');
h.compfile          = fread(fid,38,'char');
h.spectwincomp      = fread(fid,1,'float');
h.meanaccuracy      = fread(fid,1,'float');
h.meanlatency       = fread(fid,1,'float');
h.sortfile          = fread(fid,46,'char');
h.numevents         = fread(fid,1,'int');
h.compoper          = fread(fid,1,'char');
h.avgmode           = fread(fid,1,'char');
h.review            = fread(fid,1,'char');
h.nsweeps           = fread(fid,1,'ushort');
h.compsweeps        = fread(fid,1,'ushort');
h.acceptcnt         = fread(fid,1,'ushort');
h.rejectcnt         = fread(fid,1,'ushort');
h.pnts              = fread(fid,1,'ushort');
h.nchannels         = fread(fid,1,'ushort');
h.avgupdate         = fread(fid,1,'ushort');
h.domain            = fread(fid,1,'char');
h.variance          = fread(fid,1,'char');
h.rate              = fread(fid,1,'ushort');
h.scale             = fread(fid,1,'double');
h.veogcorrect       = fread(fid,1,'char');
h.heogcorrect       = fread(fid,1,'char');
h.aux1correct       = fread(fid,1,'char');
h.aux2correct       = fread(fid,1,'char');
h.veogtrig          = fread(fid,1,'float');
h.heogtrig          = fread(fid,1,'float');
h.aux1trig          = fread(fid,1,'float');
h.aux2trig          = fread(fid,1,'float');
h.heogchnl          = fread(fid,1,'short');
h.veogchnl          = fread(fid,1,'short');
h.aux1chnl          = fread(fid,1,'short');
h.aux2chnl          = fread(fid,1,'short');
h.veogdir           = fread(fid,1,'char');
h.heogdir           = fread(fid,1,'char');
h.aux1dir           = fread(fid,1,'char');
h.aux2dir           = fread(fid,1,'char');
h.veog_n            = fread(fid,1,'short');
h.heog_n            = fread(fid,1,'short');
h.aux1_n            = fread(fid,1,'short');
h.aux2_n            = fread(fid,1,'short');
h.veogmaxcnt        = fread(fid,1,'short');
h.heogmaxcnt        = fread(fid,1,'short');
h.aux1maxcnt        = fread(fid,1,'short');
h.aux2maxcnt        = fread(fid,1,'short');
h.veogmethod        = fread(fid,1,'char');
h.heogmethod        = fread(fid,1,'char');
h.aux1method        = fread(fid,1,'char');
h.aux2method        = fread(fid,1,'char');
h.ampsensitivity    = fread(fid,1,'float');
h.lowpass           = fread(fid,1,'char');
h.highpass          = fread(fid,1,'char');
h.notch             = fread(fid,1,'char');
h.autoclipadd       = fread(fid,1,'char');
h.baseline          = fread(fid,1,'char');
h.offstart          = fread(fid,1,'float');
h.offstop           = fread(fid,1,'float');
h.reject            = fread(fid,1,'char');
h.rejstart          = fread(fid,1,'float');
h.rejstop           = fread(fid,1,'float');
h.rejmin            = fread(fid,1,'float');
h.rejmax            = fread(fid,1,'float');
h.trigtype          = fread(fid,1,'char');
h.trigval           = fread(fid,1,'float');
h.trigchnl          = fread(fid,1,'char');
h.trigmask          = fread(fid,1,'short');
h.trigisi           = fread(fid,1,'float');
h.trigmin           = fread(fid,1,'float');
h.trigmax           = fread(fid,1,'float');
h.trigdir           = fread(fid,1,'char');
h.autoscale         = fread(fid,1,'char');
h.n2                = fread(fid,1,'short');
h.dir               = fread(fid,1,'char');
h.dispmin           = fread(fid,1,'float');
h.dispmax           = fread(fid,1,'float');
h.xmin              = fread(fid,1,'float');
h.xmax              = fread(fid,1,'float');
h.automin           = fread(fid,1,'float');
h.automax           = fread(fid,1,'float');
h.zmin              = fread(fid,1,'float');
h.zmax              = fread(fid,1,'float');
h.lowcut            = fread(fid,1,'float');
h.highcut           = fread(fid,1,'float');
h.common            = fread(fid,1,'char');
h.savemode          = fread(fid,1,'char');
h.manmode           = fread(fid,1,'char');
h.ref               = fread(fid,10,'char');
h.rectify           = fread(fid,1,'char');
h.displayxmin       = fread(fid,1,'float');
h.displayxmax       = fread(fid,1,'float');
h.phase             = fread(fid,1,'char');
h.screen            = fread(fid,16,'char');
h.calmode           = fread(fid,1,'short');
h.calmethod         = fread(fid,1,'short');
h.calupdate         = fread(fid,1,'short');
h.calbaseline       = fread(fid,1,'short');
h.calsweeps         = fread(fid,1,'short');
h.calattenuator     = fread(fid,1,'float');
h.calpulsevolt      = fread(fid,1,'float');
h.calpulsestart     = fread(fid,1,'float');
h.calpulsestop      = fread(fid,1,'float');
h.calfreq           = fread(fid,1,'float');
h.taskfile          = fread(fid,34,'char');
h.seqfile           = fread(fid,34,'char');
h.spectmethod       = fread(fid,1,'char');
h.spectscaling      = fread(fid,1,'char');
h.spectwindow       = fread(fid,1,'char');
h.spectwinlength    = fread(fid,1,'float');
h.spectorder        = fread(fid,1,'char');
h.notchfilter       = fread(fid,1,'char');
h.headgain          = fread(fid,1,'short');
h.additionalfiles   = fread(fid,1,'int');
h.unused            = fread(fid,5,'char');
h.fspstopmethod     = fread(fid,1,'short');
h.fspstopmode       = fread(fid,1,'short');
h.fspfvalue         = fread(fid,1,'float');
h.fsppoint          = fread(fid,1,'short');
h.fspblocksize      = fread(fid,1,'short');
h.fspp1             = fread(fid,1,'ushort');
h.fspp2             = fread(fid,1,'ushort');
h.fspalpha          = fread(fid,1,'float');
h.fspnoise          = fread(fid,1,'float');
h.fspv1             = fread(fid,1,'short');
h.montage           = fread(fid,40,'char');
h.eventfile         = fread(fid,40,'char');
h.fratio            = fread(fid,1,'float');
h.minor_rev         = fread(fid,1,'char');
h.eegupdate         = fread(fid,1,'short');
h.compressed        = fread(fid,1,'char');
h.xscale            = fread(fid,1,'float');
h.yscale            = fread(fid,1,'float');
h.xsize             = fread(fid,1,'float');
h.ysize             = fread(fid,1,'float');
h.acmode            = fread(fid,1,'char');
h.commonchnl        = fread(fid,1,'uchar');
h.xtics             = fread(fid,1,'char');
h.xrange            = fread(fid,1,'char');
h.ytics             = fread(fid,1,'char');
h.yrange            = fread(fid,1,'char');
h.xscalevalue       = fread(fid,1,'float');
h.xscaleinterval    = fread(fid,1,'float');
h.yscalevalue       = fread(fid,1,'float');
h.yscaleinterval    = fread(fid,1,'float');
h.scaletoolx1       = fread(fid,1,'float');
h.scaletooly1       = fread(fid,1,'float');
h.scaletoolx2       = fread(fid,1,'float');
h.scaletooly2       = fread(fid,1,'float');
h.port              = fread(fid,1,'short');
h.numsamples        = fread(fid,1,'ulong');
h.filterflag        = fread(fid,1,'char');
h.lowcutoff         = fread(fid,1,'float');
h.lowpoles          = fread(fid,1,'short');
h.highcutoff        = fread(fid,1,'float');
h.highpoles         = fread(fid,1,'short');
h.filtertype        = fread(fid,1,'char');
h.filterdomain      = fread(fid,1,'char');
h.snrflag           = fread(fid,1,'char');
h.coherenceflag     = fread(fid,1,'char');
h.continuoustype    = fread(fid,1,'char');
h.eventtablepos     = fread(fid,1,'long');
h.continuousseconds = fread(fid,1,'float');
h.channeloffset     = fread(fid,1,'long');
h.autocorrectflag   = fread(fid,1,'char');
h.dcthreshold       = fread(fid,1,'uchar');

for n = 1:h.nchannels
    e(n).lab            = deblank(char(fread(fid,10,'char')'));
    e(n).reference      = fread(fid,1,'char');
    e(n).skip           = fread(fid,1,'char');
    e(n).reject         = fread(fid,1,'char');
    e(n).display        = fread(fid,1,'char');
    e(n).bad            = fread(fid,1,'char');
    e(n).n              = fread(fid,1,'ushort');
    e(n).avg_reference  = fread(fid,1,'char');
    e(n).clipadd        = fread(fid,1,'char');
    e(n).x_coord        = fread(fid,1,'float');
    e(n).y_coord        = fread(fid,1,'float');
    e(n).veog_wt        = fread(fid,1,'float');
    e(n).veog_std       = fread(fid,1,'float');
    e(n).snr            = fread(fid,1,'float');
    e(n).heog_wt        = fread(fid,1,'float');
    e(n).heog_std       = fread(fid,1,'float');
    e(n).baseline       = fread(fid,1,'short');
    e(n).filtered       = fread(fid,1,'char');
    e(n).fsp            = fread(fid,1,'char');
    e(n).aux1_wt        = fread(fid,1,'float');
    e(n).aux1_std       = fread(fid,1,'float');
    e(n).senstivity     = fread(fid,1,'float');
    e(n).gain           = fread(fid,1,'char');
    e(n).hipass         = fread(fid,1,'char');
    e(n).lopass         = fread(fid,1,'char');
    e(n).page           = fread(fid,1,'uchar');
    e(n).size           = fread(fid,1,'uchar');
    e(n).impedance      = fread(fid,1,'uchar');
    e(n).physicalchnl   = fread(fid,1,'uchar');
    e(n).rectify        = fread(fid,1,'char');
    e(n).calib          = fread(fid,1,'float');
end

% finding if 32-bits of 16-bits file
% ----------------------------------
begdata = ftell(fid);
enddata = h.eventtablepos;   % after data
if strcmpi(r.dataformat, 'int16')
     nums    = (enddata-begdata)/h.nchannels/2;
else nums    = (enddata-begdata)/h.nchannels/4;
end;

% number of sample to read
% ------------------------
if ~isempty(r.sample1)
   r.t1      = r.sample1/h.rate;
else 
   r.sample1 = r.t1*h.rate;
end;
if strcmpi(r.dataformat, 'int16')
     startpos = r.t1*h.rate*2*h.nchannels;
else startpos = r.t1*h.rate*4*h.nchannels;
end;
if isempty(r.ldnsamples)
     if ~isempty(r.lddur)
          r.ldnsamples = round(r.lddur*h.rate); 
     else r.ldnsamples = nums; 
     end;
end;

% channel offset
% --------------
if ~isempty(r.blockread)
    h.channeloffset = r.blockread;
end;
if h.channeloffset > 1
    fprintf('WARNING: reading data in blocks of %d, if this fails, try using option "''blockread'', 1"\n', ...
            h.channeloffset);
end;

disp('Reading data .....')
if type == 'cnt' 
  
      % while (ftell(fid) +1 < h.eventtablepos)
      %d(:,i)=fread(fid,h.nchannels,'int16');
      %end
      fseek(fid, startpos, 0);
	  if h.channeloffset <= 1
      	  dat=fread(fid, [h.nchannels r.ldnsamples], r.dataformat);
 	  else
          h.channeloffset = h.channeloffset/2;
          % reading data in blocks
     	  dat = zeros( h.nchannels, r.ldnsamples);
      	  dat(:, 1:h.channeloffset) = fread(fid, [h.channeloffset h.nchannels], r.dataformat)';

		  counter = 1;	
 		  while counter*h.channeloffset < r.ldnsamples
              dat(:, counter*h.channeloffset+1:counter*h.channeloffset+h.channeloffset) = ...
                  fread(fid, [h.channeloffset h.nchannels], r.dataformat)';
              counter = counter + 1;
		  end;
	  end;	
      
      %ftell(fid)
      if strcmpi(r.scale, 'on')
          disp('Scaling data .....')
          %%% scaling to microvolts
          for i=1:h.nchannels
              bas=e(i).baseline;sen=e(i).senstivity;cal=e(i).calib;
              mf=sen*(cal/204.8);
              dat(i,:)=(dat(i,:)-bas).*mf;
          end
      end     
      
      fseek(fid, h.eventtablepos, 'bof');      
      disp('Reading Event Table...')
      eT.teeg   = fread(fid,1,'uchar');
      eT.size   = fread(fid,1,'ulong');
      eT.offset = fread(fid,1,'ulong');
      
      if eT.teeg==2
          nevents=eT.size/sizeEvent2;
          if nevents > 0
              ev2(nevents).stimtype  = [];
              for i=1:nevents
                  ev2(i).stimtype      = fread(fid,1,'ushort');
                  ev2(i).keyboard      = fread(fid,1,'char');

% modified by Andreas Widmann  2005/05/12  14:15:00
                  %ev2(i).keypad_accept = fread(fid,1,'char');
                  temp                 = fread(fid,1,'uint8');
                  ev2(i).keypad_accept = bitand(15,temp);
                  ev2(i).accept_ev1    = bitshift(temp,-4);
% end modification

                  ev2(i).offset        = fread(fid,1,'long');
                  ev2(i).type          = fread(fid,1,'short'); 
                  ev2(i).code          = fread(fid,1,'short');
                  ev2(i).latency       = fread(fid,1,'float');
                  ev2(i).epochevent    = fread(fid,1,'char');
                  ev2(i).accept        = fread(fid,1,'char');
                  ev2(i).accuracy      = fread(fid,1,'char');
              end     
          else
              ev2 = [];
          end;
      elseif eT.teeg==1
          nevents=eT.size/sizeEvent1;
          if nevents > 0
              ev2(nevents).stimtype  = [];
              for i=1:nevents
                  ev2(i).stimtype      = fread(fid,1,'ushort');
                  ev2(i).keyboard      = fread(fid,1,'char');

% modified by Andreas Widmann  2005/05/12  14:15:00
                  %ev2(i).keypad_accept = fread(fid,1,'char');
                  temp                 = fread(fid,1,'uint8');
                  ev2(i).keypad_accept = bitand(15,temp);
                  ev2(i).accept_ev1    = bitshift(temp,-4);
% end modification

                  ev2(i).offset        = fread(fid,1,'long');
              end;
          else
              ev2 = [];
          end;
     else
          disp('Skipping event table (tag != 1,2 ; theoritically impossible)');
          ev2 = [];
      end     
end 

fseek(fid, -1, 'eof');
t = fread(fid,'char');

f.header   = h;
f.electloc = e;
f.data     = dat;
f.Teeg     = eT;
f.event    = ev2;
f.tag=t;

%%%% channels labels
for i=1:h.nchannels
  plab=sprintf('%c',f.electloc(i).lab);
  if i>1 
   lab=str2mat(lab,plab);
  else 
   lab=plab;  
  end  
end  

%%%% to change offest in bytes to points 
if ~isempty(ev2)
    ev2p=ev2; 
    ioff=900+(h.nchannels*75); %% initial offset : header + electordes desc 
    if strcmpi(r.dataformat, 'int16')
        for i=1:nevents 
            ev2p(i).offset=(ev2p(i).offset-ioff)/(2*h.nchannels) - r.sample1; %% 2 short int end 
        end     
    else % 32 bits
        for i=1:nevents 
            ev2p(i).offset=(ev2p(i).offset-ioff)/(4*h.nchannels) - r.sample1; %% 4 short int end 
        end     
    end;        
    f.event = ev2p;
end;

frewind(fid);
fclose(fid);


