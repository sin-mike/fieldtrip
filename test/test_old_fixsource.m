function test_old_fixsource

% MEM 1gb
% WALLTIME 00:10:00

% TEST test_old_fixsource

%this script tests the fixsource function which is part of checkdata

%-------------------------------------
%generate data
rand('twister',20090408);
data = [];
data.fsample = 1000;
data.cfg     = [];

nsmp  = 1000;
nchan = 80;
for k = 1:10
  data.trial{k} = randn(nchan,nsmp);
  data.time{k}  = ([1:nsmp]-1)./data.fsample;
end

%create grad-structure and add to data
addpath /home/common/matlab/fieldtrip_private
[pnt,tri] = icosahedron162;
nrm       = normals(pnt, tri, 'vertex');
pnt       = pnt.*12;
[srt,ind] = sort(pnt(:,3),'descend');
grad      = [];
grad.pnt  = pnt(ind(1:nchan),:);
grad.ori  = nrm(ind(1:nchan),:);
grad.tra  = eye(nchan);
for k = 1:nchan
  grad.label{k} = ['chan',num2str(k,'%03d')];
end
data.grad  = grad;
data.label = grad.label;

%create vol
vol   = [];
vol.o = [0 0 2];
vol.r = 8;

%prepare leadfields and grid
cfg                 = [];
cfg.grid.resolution = 1.5;
cfg.vol             = vol;
cfg.grad            = grad;
grid                = ft_prepare_leadfield(cfg);

%do spectral analysis
cfg        = [];
cfg.method = 'mtmfft';
cfg.output = 'fourier';
cfg.foilim = [2 100];
cfg.pad    = 1;
cfg.tapsmofrq = 3;
freq       = ft_freqanalysis(cfg, data);

%do timelocked analysis
cfg            = [];
cfg.covariance = 'yes';
cfg.covariancewindow = [0 0.999];
cfg.keeptrials = 'yes';
tlck           = ft_timelockanalysis(cfg, data);

%-----------------------------------------------

%-----------------------------------------------
%source reconstruction part

%without fixedori
cfgs           = [];
cfgs.grid      = grid;
cfgs.frequency = 20;
cfgs.method    = 'dics';
cfgs.lambda    = '10%';
cfgs.keepfilter = 'yes';
cfgs.feedback  = 'textbar';
cfgs.vol       = vol;
cfgs.fixedori  = 'no';
cfgs.keepcsd   = 'yes';
cfgs.realfilter = 'yes';
cfgs.keepleadfield = 'yes';
source         = sourceanalysis(cfgs,freq);
sdics          = checkdata(source, 'sourcerepresentation', 'new');

cfgs.grid.filter = sdics.filter;
cfgs.method      = 'pcc';
cfgs.keepmom     = 'yes';
source           = ft_sourceanalysis(cfgs, freq);
spcc1            = checkdata(source, 'sourcerepresentation', 'new', 'haspow', 'yes');
%this gives a warning

cfgsd            = [];
cfgsd.projectmom = 'yes';
sd               = ft_sourcedescriptives(cfgsd, source);
spcc2            = checkdata(sd, 'sourcerepresentation', 'new', 'haspow', 'yes');

%with fixedori
cfgs.grid     = grid;
cfgs.method   = 'dics';
cfgs.keepmom  = 'no';
cfgs.fixedori = 'yes';
source        = sourceanalysis(cfgs, freq);
sdics2        = checkdata(source, 'sourcerepresentation', 'new');

cfgs.grid.filter = sdics2.filter;
cfgs.method      = 'pcc';
cfgs.keepmom     = 'yes';

%there are two ways for not crashing the second round of sourceanalysis
%with fixori = 'yes';
for k = 1:numel(source.inside)
  kk = source.inside(k);
  cfgs.grid.leadfield{kk} = sdics2.leadfield{kk}*sdics2.ori{kk};
end
source = ft_sourceanalysis(cfgs, freq);
spcc1f = checkdata(source, 'sourcerepresentation', 'new', 'haspow', 'yes');
%FIXME known problem: ori-field is missing here

% alternative
% append a mom to the grid as (3xN) matrix
cfgs.grid.mom = zeros(size(grid.pos))';
for k = 1:numel(source.inside)
  kk = source.inside(k);
  cfgs.grid.mom(:,kk) = sdics2.ori{kk};
end
%FIXME there's an issue here with mom being expected to be Nx3 and 3xN in beamformer_pcc
source = ft_sourceanalysis(cfgs, freq);
try,
  spcc2f = checkdata(source, 'sourcerepresentation', 'new', 'haspow', 'yes');
catch
  error('this does not work');
end

%call sourcedescriptives to get a .trial field
cfgsd            = [];
cfgsd.keeptrials = 'yes';
sd               = ft_sourcedescriptives(cfgsd, source);
spcc3f           = checkdata(sd, 'sourcerepresentation', 'new');

%lcmv
cfgs           = [];
cfgs.grid      = grid;
cfgs.frequency = 20;
cfgs.method    = 'lcmv';
cfgs.lambda    = '10%';
cfgs.keepfilter = 'yes';
cfgs.feedback  = 'textbar';
cfgs.vol       = vol;
cfgs.fixedori  = 'no';
cfgs.keepcov   = 'yes';
cfgs.keepleadfield = 'yes';
source         = sourceanalysis(cfgs,tlck);
slcmv          = checkdata(source, 'sourcerepresentation', 'new');

cfgs.grid.filter = slcmv.filter;
cfgs.rawtrial    = 'yes';
source           = sourceanalysis(cfgs, tlck);
slcmv2           = checkdata(source, 'sourcerepresentation', 'new');