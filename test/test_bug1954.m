function test_bug1954

load /home/common/matlab/fieldtrip/template/headmodel/standard_mri.mat


cfg           = [];
cfg.output    = {'brain','skull','scalp'};
segmentedmri  = ft_volumesegment(cfg, mri);
% I said 'n' when asked 
% Do you want to change the anatomical labels for the axes [Y, n]? 
% Saying 'Y' and giving 'rasn' gives same answer.

% I get warning:
% Warning: could not open /tmp/tpe20fae07_8585_42ab_a6e4_0e4c656f97b3.img 

figure;imagesc(squeeze(segmentedmri.scalp(:,110,:)))
% voxels on top of head included in scalp

cfg = [];
cfg.method = 'bemcp';
vol1 = ft_prepare_headmodel(cfg, segmentedmri);
% vol1.mat are all NaN

cfg = [];
cfg.method = 'dipoli';
vol2 = ft_prepare_headmodel(cfg, segmentedmri);
% looks ok, but no .mat to assess

cfg=[];
cfg.numvertices=3000;
bnd=ft_prepare_mesh(cfg,segmentedmri);
% ft_plot_mesh(bnd(1)) shows that the segmentation did not go well.

segmentedmri.bnd=bnd;
cfg=[];
cfg.method='bemcp';
vol1o=ft_prepare_bemmodel(cfg,segmentedmri);
% vol1o.mat also all NaN

