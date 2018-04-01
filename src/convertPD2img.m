function [imageData,gridArray] = convertPD2img(pointData,pxielSize,radius,isRotate)
% convert pointcloud data into raster intensity image��a substitutor of convertpointcloud2img
% [imageData,gridArray] = convertPD2img(pointData,pxielSize,radius,isRotate)
%
% arguments: (input)
% radius - ���ز�ֵ�뾶����������Ӽ���������Сͼ�������ڶ����ص㣬һ������
%          Ϊ��ļ����С
% isRotate - ��OPTIONAL��- �Ƿ���תͼ��ͨ����ת����ʹ��·ͼ���ӹ켣ˮƽ���ã�
%           ����ͼ����ͼ���нϴ�н�
%
% arguments: (output)
% radius - ���ز�ֵ�뾶����������Ӽ���������Сͼ�������ڶ����ص㣬һ������
%          Ϊ��ļ����С
%           DEFAULT: 'radius'    (pxielSize*3)
%                    'isRotate'  (true)
%
% isRotate - ��OPTIONAL��- �Ƿ���תͼ��ͨ����ת����ʹ��·ͼ���ӹ켣ˮƽ���ã�
%           ����ͼ����ͼ���нϴ�н�
% 
% arguments: (output)
% imageData - ת����ĻҶ�ͼ��
% gridArray - �Ҷ�ͼ��ÿ�����ض�Ӧ�ĵ���
% 

% The program is written by Chen Qichao in his period of studying in master
% degree at Tongji University. You can redistribute or modify the program
% for non-commercial use. Any commercial use of this program is forbidden
% except being authorized.
%
% mail : mailboxchen@foxmail.com
% Copyright (C) 2015 - 2018  Tongji University

% datetime('now','TimeZone','local','Format','HH:mm:ss Z')
isRotate=false;
if ~exist('radius','var')||isempty(radius),radius = pxielSize*2;end
if ~exist('isRotate','var')||(isRotate==true)
    x = pointData(:,1);
    y = pointData(:,2);
    [rectx,recty,~,~] = minboundrect(x,y);
    d = sqrt((rectx(1:2) - rectx(2:3)).^2+(recty(1:2) - recty(2:3)).^2);%��Ӿ��α߳�
    [a,idx_a] = max(d);%�ϳ��ı�
    b = min(d);
    rotateA = atand((recty(idx_a)-recty(idx_a+1))/(rectx(idx_a)-rectx(idx_a+1)));%��Ӿ��νϳ��ı���x��н�
    if rotateA>=0
        [minY,idx_minY] = min(recty);
        origin  = [rectx(idx_minY) minY];%ͼ��ԭ���Ӧ����
    else
        [minX,idx_minX] = min(rectx);
        origin  = [minX recty(idx_minX)];%ͼ��ԭ���Ӧ����
    end
else
    [width,height,minX,minY,maxX,maxY] = calculatesize(pointData,pxielSize);
    a = maxX - minX;
    b = maxY - minY;
    origin = [minX,minY];
    rotateA = 0;
end
%     gridArray = gridpoint(pointData,pxielSize,origin,rotateA);%������
    greyImage = idwpartition(pointData,origin,a,b,rotateA,pxielSize,radius);%��ֵ���ȽϺ�ʱ 
    imageData = greyImage;
end

% function gridArray = gridpoint(pointData,gridSize,origin,rotateA)
% % generate grid of points, not recommended
%    % [width,height,minX,minY,maxX,maxY] = calculatesize(pointData,gridSize);
%     
%     x0 = pointData(:,1);
%     y0 = pointData(:,2);
%     if abs(tand(rotateA))~=inf
%         k = tand(rotateA);
%         A = k;
%         B = -1;
%         C = origin(2)-k*origin(1);
%         d1 = abs(A.*x0+B.*y0+C)./sqrt(A*A+B*B);%�㵽���ߵľ���,��Ӧ����Y
%         %�㵽�̱ߵľ��룬��Ӧ��ת���x����
%         k = tand(rotateA+90);
%         A = k;
%         B = -1;
%         C = origin(2)-k*origin(1);
%         d2 = abs(A.*x0+B.*y0+C)./sqrt(A*A+B*B);
%     else
%         d1 = y0-origin(2);
%         d2 = x0 - origin(1);
%     end
%     minX = min(d2);%d1.d2������x��y
%     minY = min(d1);
%     maxX = max(d2);
%     maxY = max(d1);
%     width = ceil((maxX-minX)/gridSize);
%     height = ceil((maxY-minY)/gridSize);
%     pointData(:,5) = d2;%���и���������5,6λ�����5,6λ�洢���������ݣ�����͵��޸ĵ�����λ
%     pointData(:,6) = d1;
%     widthStripsArray = cut2strips(pointData,width,minX,maxX,gridSize,5);
%     gridArray = cell(height,width);
%     for i = 1:width
%         widthStrip = widthStripsArray{i};
%         heightStripsArray = cut2strips(widthStrip,height,minY,maxY,gridSize,6);
%         gridArray(:,i) = heightStripsArray';
%     end
% end
% 
% function stripsArray = cut2strips(pointData,nStrips,startValue,endValue,pxielSize,type)
% %cut point into strips
% %type==1, cut by x coordinate;
% %type==2, cut by y coordinate;
% %typeҲ����������ָ����;
%     stripsArray(1:nStrips) = {[]};
%     if isempty(pointData)
%         return;
%     end
%     pointData = sortrows(pointData,type);%��x��������
%     nPoint = size(pointData,1);
%     valueArray = pointData(:,type);%�ָ�����ݣ��簴x����y����
%     cutStart = startValue;
%     cutEnd = startValue + pxielSize;
%     iPoint=1;
%     value = valueArray(1);
%     isEndPoint = false;%�Ƿ���������һ����
%     for i = 1:nStrips,%�ֳ�nStrips��
%         strip = [];
%         iStripPoint = 0;
%         while value<cutEnd,
%             iStripPoint = iStripPoint+1;
%             strip(iStripPoint,:) = pointData(iPoint,:);
%             if iPoint<nPoint,
%                 iPoint = iPoint+1;   
%                 value = valueArray(iPoint);
%             else
%                 isEndPoint = true;
%                 break;
%             end
%         end  
%         stripsArray(i) = {strip};
%         cutStart = cutEnd;
%         cutEnd = cutEnd + pxielSize;
%         if isEndPoint,
%             break;
%         end
%     end
% end


function [width,height,minX,minY,maxX,maxY] = calculatesize(pointCloudData,pxielSize)
%calcullate width and height of image
xAraay = pointCloudData(:,1);
yArray = pointCloudData(:,2);
minX = min(xAraay);
maxX = max(xAraay);
minY = min(yArray);
maxY = max(yArray);
width =  ceil((maxX - minX)/pxielSize);
height = ceil((maxY - minY)/pxielSize);
end

function [imageOut,gridArray]= idwpartition(pointData,origin,a,b,rotateCloudA,pxielSize,radius)
%  partition processing for pointcloud by inverse distance weighted interpolation 
%
% arguments(input):
% pointData - ��������xyzi
% origin - ��ֵ����ԭ�㣨���½ǣ�
% a - ��ֵ���ο�
% b - ��ֵ���θ�
% rotateCloudA - ԭ����ϵ����ֵ��������ϵ��ת�ǣ�˳ʱ��Ϊ����
% radius - 0.10;��ֵ�뾶��������ն����ص�
%
% ��ֵ����ָ�Ե��ƵĲ�ֵ��Χ��һ�������֣�һ�������������ϵxy��ƽ�е���Ӿ��Σ�
% ��һ������С��Ӿ��Ρ��������С��Ӿ��Σ���a��Ӧ���ߣ�b��Ӧ�̱ߣ���Ϊ��·��
% ��״�ģ�ϣ����ֵ���ͼ�����������򣬶�����������
%
% arguments(output):
% imageOut - ��ֵ��ͼ��
% gridArray - ��ֵͼ��ÿ�����ض�Ӧ�ĵ��ƣ���ȱ
%
imageOut = [];
np = size(pointData,1);
if np<1000000&&np>0
    partN = 1;
elseif np<=10000000
    partN = ceil(np/1000000);
elseif np>10000000
    partN = 10;
else
    return;
end
    
maxI = max(pointData(:,4));
minI = min(pointData(:,4));
minX = origin(1);
minY = origin(2);
height = ceil(b/pxielSize);
width = ceil(a/pxielSize);
% imageOut2 = zeros(height,width);
% normPara = normalizegray(imageArray);%��һ������ϵ��

interX = (0.5*pxielSize:pxielSize:width*pxielSize);%��ֵ����������������
interY = (0.5*pxielSize:pxielSize:height*pxielSize)';

dx = (max(interX) - min(interX))/partN;% �ָ���
dy = (max(interY) - min(interY))/partN;% �ָ���

if height>width
    d = dy;
    index = 2;
     minO = minY;
     partNa = 1;
    partNb = partN;
else
    d = dx;
    index = 1;
    minO = minX;
    partNa = partN
    partNb = 1;
end

for i =1:partN
%     datetime
    seg1 = minO +(i-1)*d-radius;
    seg2 = minO +i*d+radius;
    segPoint = pointData((pointData(:,index)>seg1)&(pointData(:,index)<seg2),:);
    imagetmp= idw(segPoint,origin,a/partNa,b/partNb,rotateCloudA,pxielSize,radius,maxI,minI);
    origin(index) = origin(index)+d;
    if  height<width
        imageOut = [imageOut imagetmp];
    else
        imageOut = [imageOut;imagetmp];
    end  
end

end

function [imageOut,gridArray]= idw(pointData,origin,a,b,rotateCloudA,pxielSize,radius,maxI,minI)
%inverse distance weighted interpolation for pointcloud
%
% arguments(input):
% pointData - ��������xyzi
% origin - ��ֵ����ԭ�㣨���½ǣ�
% a - ��ֵ���ο�
% b - ��ֵ���θ�
% rotateCloudA - ԭ����ϵ����ֵ��������ϵ��ת�ǣ�˳ʱ��Ϊ����
% radius - 0.10;��ֵ�뾶��������ն����ص�
%
% ��ֵ����ָ�Ե��ƵĲ�ֵ��Χ��һ�������֣�һ�������������ϵxy��ƽ�е���Ӿ��Σ�
% ��һ������С��Ӿ��Ρ��������С��Ӿ��Σ���a��Ӧ���ߣ�b��Ӧ�̱ߣ���Ϊ��·��
% ��״�ģ�ϣ����ֵ���ͼ�����������򣬶�����������
%
% arguments(output):
% imageOut - ��ֵ��ͼ��
% gridArray - ��ֵͼ��ÿ�����ض�Ӧ�ĵ��ƣ���ȱ
%

Mdl = KDTreeSearcher(pointData(:,1:2));%����kd������
% maxI = max(pointData(:,4));
% minI = min(pointData(:,4));
minX = origin(1);
minY = origin(2);
height = ceil(b/pxielSize);
width = ceil(a/pxielSize);
imageOut = zeros(height,width);
% normPara = normalizegray(imageArray);%��һ������ϵ��
if maxI~=minI
    normPara = 1/abs(1*maxI-minI);%����0.8maxI�����ص��
else
    normPara = 1;
end
interX = (0.5*pxielSize:pxielSize:width*pxielSize);%��ֵ����������������
interY = (0.5*pxielSize:pxielSize:height*pxielSize)';
interX = repmat(interX,height,1);
interY = repmat(interY,1,width);
rotateImageA = atand(interY./interX);%��ֵ����������������ϵ��x��н�
rotateA = rotateCloudA + rotateImageA;
distO = sqrt(interX.^2+interY.^2);%��ֵ���������������ϵԭ�����
dx = distO.*cosd(rotateA);
dy = distO.*sind(rotateA);
interX = minX + dx;
interY = minY + dy;

ix = reshape(interX',[1 width*height])';
iy = reshape(interY',[1 width*height])';
Idx = rangesearch(Mdl,[ix iy],radius);
for iHeight=1:height
    for iWidth=1:width
        idx_pixel = (iHeight-1)*width+iWidth;%���ص����������е�˳���
        points = pointData(Idx{idx_pixel},:);%��ֵ�뾶�ڵĵ�
        nPoints = size(points,1);
        distC = sqrt((points(:,1)-ix(idx_pixel)).^2 + (points(:,2)-iy(idx_pixel)).^2);
        weight = zeros(nPoints,1);
        weight(distC(:,1)~=0,1) = (pxielSize./distC).^3;
        weight(distC(:,1)==0,1) = 1;
        ins = points(:,4);
        insOutTotal = sum(weight.*(ins-minI));
        weightTotal = sum(weight);
        insOut = ((insOutTotal)/weightTotal)*normPara;
        imageOut(iHeight,iWidth) = insOut;
    end
end
end

