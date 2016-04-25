function show_neg_clusters( clusters, patches )

% threshold clusters to > 1
old_clusters = clusters;
clusters = {};
c = 1;
for i=1:size(old_clusters,2)
  cluster = old_clusters{i};
  if size(cluster,2) >= 1
    clusters{c} = cluster;
    c = c + 1;
  end
end

num_clusters = size(clusters,2)
scrsz = get(0,'ScreenSize');
clusters_at_once = 5;
samples_per_cluster = 10;
save clusters.mat;
load clusters.mat;

for i=0:clusters_at_once:num_clusters
  %figure('Position', [1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2]);
  figure('Position', [1 scrsz(4)/2 scrsz(3) scrsz(4)/2]);
  for j=1:clusters_at_once
    if i+j <= num_clusters
      cluster = clusters{i+j};
      K = min(samples_per_cluster,size(cluster,2));
      % center patch:
      %center = cluster_center( cluster, patches );
%       center = cluster_center_frechet( cluster, patches );
%       subplot(clusters_at_once, samples_per_cluster+1, (j-1)*(samples_per_cluster+1)+1)
%       imshow( uint8(reshape(center,37,37)) )
      % first K patches:
      for k=1:K
        subplot(clusters_at_once, samples_per_cluster+1, (j-1)*(samples_per_cluster+1)+1+k)
        imshow( uint8(reshape(patches(cluster{k},:),37,37)) )
      end
    end
    end
  end