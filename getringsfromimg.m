function [rings_locs,rings_wdith,rings_num]=getringsfromimg(I)
% ���㻷Ƭ��Ŀ������
% I - ��Ƭդ��ͼ��
%
% OUTPUT��
% rings_locs - ����λ�ö�Ӧ���غ�����
% rings_wdith - �������У���һ��Ϊ��Ƭ���ؿ�ȣ��ڶ���Ϊ�������0��ʾ������1��
%               ʾ��Ӧ���츽�������д�����©��
% rings_num - �����Ļ������

I = im2double(I);
[H1,H2] = gradienthist(I);
data=H2;%ʹ��H2���Ч���Ϻ�

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ���������
Fs =1; %����Ƶ��
MinPeakProminence = max(data)/1; %����Сͻ���������
threshold = 0; %��ֵ�����ڽ���Ƚ�����
MinPeakHeight = max(data)/5; %��С��߶�����
MinPeakDistance = 40/Fs; %��С�������ޣ����ֵ
nPeaks = 90000; %�����nPeaks����
sortstr = 'none'; %�������
Annotate = 'extents'; 
%���ȼ����׼,halfprom:��ͻ����ȿ� halfheight:��߿�
WidthReference = 'halfprom';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ȷ��MinPeakDistance
[pks,locs,w,p] = ...
    findpeaks(data,Fs,'MinPeakProminence',MinPeakProminence, ...
'threshold',threshold,'MinPeakHeight',MinPeakHeight, ...
'MinPeakDistance',MinPeakDistance,'npeaks',nPeaks, ...
'sortstr',sortstr, ...
'Annotate',Annotate,'WidthReference',WidthReference);
dd=[(locs(2:end)-locs(1:end-1))';190;199;100];
pren = size(dd,1);
nextn=0;
while(pren~=nextn)
    md = mean(dd);
    derta = sqrt(sum((dd-md).^2)/size(dd,1));
    dd = dd(abs(dd-md)<2*derta); 
    pren = nextn;
    nextn = size(dd,1);
end
MinPeakDistance = mean(dd)*0.75;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%�ӷ�λ��ʶ��
[pks1,locs1,w1,p1] = ...
    findpeaks(data,Fs,'MinPeakProminence',MinPeakProminence, ...
'threshold',threshold,'MinPeakHeight',MinPeakHeight, ...
'MinPeakDistance',MinPeakDistance,'npeaks',nPeaks, ...
'sortstr',sortstr, ...
'Annotate',Annotate,'WidthReference',WidthReference);

 [pks2,locs2,w2,p2] =...
     findpeaks(-data,Fs,'MinPeakProminence',MinPeakProminence, ...
'threshold',threshold,'MinPeakHeight',MinPeakHeight, ...
'MinPeakDistance',MinPeakDistance,'npeaks',nPeaks, ...
'sortstr',sortstr, ...
'Annotate',Annotate,'WidthReference',WidthReference);

locs1 =locs1';
locs2 = locs2';
for(i=1:size(locs1,1))
    dist = abs(locs2-locs1(i,1));
    [A,idx] = sortrows(dist);
    if(A(1,1)<MinPeakDistance*0.1)
        locs_result(i,1) = ceil((locs1(i,1)+locs2(idx(1),1))/2);
    else
        locs_result(i,1) = locs1(i,1);
    end
end

rings_num = size(locs_result,1);%��Ƭ��Ŀ
rings_locs = locs_result;%��Ƭλ��
ring_wdith = [rings_locs] - [0;rings_locs(1:end-1)];
tmp = ring_wdith;
pren = size(tmp,1);
nextn=0;
while(pren~=nextn)
    md = mean(tmp);
    derta_tmp = sqrt(sum((tmp-md).^2)/size(tmp,1));
    tmp = tmp(abs(tmp-md)<2*derta_tmp); 
    pren = nextn;
    nextn = size(tmp,1);
end
m_wdith = ceil(mean(tmp));
rings_wdith = [ring_wdith,zeros(size(ring_wdith,1),1)];
rings_wdith(abs(ring_wdith(2:end-1,1)-m_wdith)>10*derta_tmp,2) = 1;%��ǿ��ܵ�©�졢����쳣ֵ

%����λ��д��ͼ��
position = [];
value = [];
for i= 1:size(ring_wdith,1)
    I(:,abs(ceil(rings_locs(i)))) = 1;
    position =  [position;ceil(rings_locs(i))+5 5];
    value = [value,i];
    if(rings_wdith(i,2)==0)
        box_color(i) = {'green'};
    elseif(rings_wdith(i,2)==1)
        box_color(i) = {'red'};
    end
end
RGB = insertText(I,position,value,'FontSize',30,'BoxColor',box_color);
imwrite(RGB,'result_rings.png');%ͼ������
end


function [H,H2] = gradienthist(I)
%
%�����غ���������ݶ�ֱ��ͼ
[FX,FY] = gradient(I);
[row col] = size(FX); 
H = zeros(1,col);%�ݶ���ֵͳ��
H2 = zeros(1,col);%�ݶȷ���ͳ��
for iCol = 1:col,
    h = 0;
    h2 = 0;
    for iRow = 1:row,
        h = h+FX(iRow,iCol); 
        if FX(iRow,iCol)>0;
            h2=h2+1;
        elseif FX(iRow,iCol)<-0;
            h2=h2-1;
        end
    end
    H(iCol) = h;
    H2(iCol) = h2;
end
% A2=fspecial('gaussian',2,5);     
% H2 = filter2(A2,H);
% for i = 1:iCol,
%     if abs(H(i))<1,
%         H(i)=0;
%     end
% end
% plot(1:col,H,'r-');hold on
% plot(1:col,H2,'b-');


% Igrad = sqrt(FY.^2+FX.^2);
% [Igrad,T] = histeq(Igrad);
% imwrite(Igrad,'myGradxy.png');%ͼ������
% imshow(Igrad);
end


