function mytest(ScanLineArray)
% ScanLineArray = getscanline_faro(pointCloudData,2);%����䶯��ȡɨ����,faro
nScanLine = size(ScanLineArray,2);
tmp = [];
Aseam = [];
outdata=  [];
for iScanLine = 1:nScanLine
    x = ScanLineArray(iScanLine).x;
    y = ScanLineArray(iScanLine).y;
    h = ScanLineArray(iScanLine).h;
    ins = ScanLineArray(iScanLine).ins;
    originalData = [x y h ins];
    
    %�����˳�
    [x0,y0,r] = getcirclepara(ScanLineArray(iScanLine));%������Χ��-0.02~0.02��
    d = sqrt((y-x0).^2+(h-y0).^2)-r;
    data =  originalData(abs(d)<0.03,:);
   
   %���ư��Ƕ�������
   px = data(:,1);
   py = data(:,2);
   ph = data(:,3);
   pins = data(:,4);
   A = atan2d(ph-y0,py-x0);%ע����atan2d(Y,X)
   A(A>=-90)=(A(A>=-90)+90);
   A(A<-90&A>=-180)=(A(A<-90&A>=-180)+450);
   [A_sorted, idx] = sortrows(A);
   data_sorted = data(idx,:);
   
   outdata = [outdata;data_sorted(A_sorted>97&A_sorted<253,:)];
   %�������
   x2 = data_sorted(:,1);
   y2 = data_sorted(:,2);
   h2 = data_sorted(:,3);
   
   d2 = sqrt((y2-x0).^2+(h2-y0).^2)-r;
    figure(1);plot(A_sorted,d2,'r-');
    dd = smooth(d2,300);
    figure(2);hold on;plot(A_sorted,dd,'r-');
    curvedata = dd;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ���������/peak detect parameters
    Fs = 1; %����Ƶ��
    MinPeakProminence = max(curvedata)/1; %����Сͻ���������
    threshold = 0; %��ֵ�����ڽ���Ƚ�����
    MinPeakHeight = max(curvedata)/5; %��С��߶�����
    MinPeakDistance = 50/Fs; %��С�������ޣ����ֵ
    nPeaks = 90; %�����nPeaks����
    sortstr = 'none'; %�������
    Annotate = 'extents';
    %���ȼ����׼,halfprom:��ͻ����ȿ� halfheight:��߿�
    WidthReference = 'halfprom';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % get MinPeakDistance
    [pks,locs,w,p] = ...
        findpeaks(curvedata,Fs,'MinPeakProminence',MinPeakProminence, ...
        'threshold',threshold,'MinPeakHeight',MinPeakHeight, ...
        'MinPeakDistance',MinPeakDistance,'npeaks',nPeaks, ...
        'sortstr',sortstr, ...
        'Annotate',Annotate,'WidthReference',WidthReference);
     figure(2);hold on;plot(A_sorted(locs),pks,'go');
       figure(3); plot3(x2,y2,h2,'g.');hold on;
       tmp = [tmp;x2(locs),y2(locs),h2(locs)];
Aseam = [Aseam;[A_sorted(locs) pks]];
end
% savepointcloud2file([outdata(:,2) outdata(:,1) outdata(:,3) outdata(:,4)],'22',0);
Aseam1 = Aseam(Aseam(:,1)<=180,:);
Aseam2 = Aseam(Aseam(:,1)>180,:);
[para ,percent]= ransac(Aseam1,0,2);
[para2 ,percent2]= ransac(Aseam2,0,2);
plot(Aseam1(:,1),Aseam1(:,2),'r.');
figure(2);plot(Aseam2(:,1),Aseam2(:,2),'r.');
figure(4);plot3(tmp(:,1),tmp(:,2),tmp(:,3),'r.','MarkerSize',5)
end





function [x0,y0,r] = getcirclepara(pointArray)
%
midIdx = ceil(size(pointArray,2)/2);
y = pointArray(midIdx).y;
h = pointArray(midIdx).h;
para = ransac([y h],'circle',0.02);
if(~isempty(para))
    x0 = para(1,1);%����Բ�����꣬��Ӧ������y��h
    y0 = para(2,1);
    r = para(3,1);
else
    x0 = 0;
    y0 = 0;
    r=0;
end
end