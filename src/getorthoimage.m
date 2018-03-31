function [imageData,pointCloudData] = getorthoimage(pcdFilePathOrData,pxielSize,space,startA,endA,startL,endL,axis_x,brightness)
%generate ortho image with tunnel pointcloud data
%
%[imageData,samplePointArray] = getorthoimage(pcdFilePathOrData,pxielSize,space,startA,endA,startL,endL,axis_x,brightness)
%
% INPUT:
% pcdFilePathOrData - ����������ݻ����ļ�·��,Ϊlas��ʽ����xyz�ı���ʽ������ȱʡ
% pxielSize         - ���ش�С��Ĭ��0.01m
% space             - �������ݳ�ϡ�������ÿ��space����ȡһ�����ݣ�Ĭ��Ϊ5
% startA��endA      - ����ͼ��ĽǶȷ�Χ��Ĭ��30,60
% startL��endL      - ����ͼ�����̷�Χ��Ĭ��0,10000
% axis_x            - ������Ƶ�ǰ������1��ʾx���ߵ�һ��Ϊǰ������2��ʾy���ߵڶ���Ϊǰ������Ĭ��2
% brightness        - ����ϵ����ֵԽ��ͼ��Խ������Ĭ��1.3
%
% OUTPUT:
% pointCloudData - ortho point cloud data
% imageData      - ortho image data
%
% This program is for processing odered tunnel point cloud data which is 
% collected through single line profile scanning.Example for faro scanner.
% 
%
% The program is written by Chen Qichao in his period of studying in master
% degree at Tongji University. You can redistribute or modify the program
% for non-commercial use. Any commercial use of this program is forbidden
% except being authorized.
%
% mail : mailboxchen@foxmail.com
% Copyright (C) 2015 - 2018  Tongji University

if ~exist('pxielSize','var')||isempty(pxielSize),pxielSize = 0.01;end
if ~exist('space','var')||isempty(space),space = 5;end
if ~exist('startA','var')||isempty(startA),startA = 0;end
if ~exist('endA','var')||isempty(endA),endA = 360;end
if ~exist('startL','var')||isempty(startL),startL = 0;end
if ~exist('endL','var')||isempty(endL),endL = 10000;end
if ~exist('axis_x','var')||isempty(axis_x),axis_x = 2;end
if ~exist('brightness','var')||isempty(brightness),brightness = 1.3;end

%�ж���������ļ�·�����ǵ��ƾ���
[row,col] = size(pcdFilePathOrData);
if row>1&&col>=4
    pointCloudData = pcdFilePathOrData;
elseif row==1
    [path,filename,filetype]=fileparts(pcdFilePathOrData);
    if(filetype=='.las')
        A = LASreadAll(pcdFilePathOrData);
        pointCloudData=[A.x,A.y,A.z,A.intensity];
        savepointcloud2file(pointCloudData,filename,false);
    elseif(filetype=='.xyz')|(filetype=='.txt')
        fid=fopen(pcdFilePathOrData,'r');
        pointCloudData = readpointcloudfile2(pcdFilePathOrData);%��ȡȫ����
    %     pointCloudData =  readpointcloudfile(fid,100000);%��ȡָ��������
    else
        error('pcdFilePathOrData is not a correct path!');
        return;
    end
else 
    return;
end

   ScanLineArray = getscanline_faro(pointCloudData(1:space:end,:),axis_x);%����䶯��ȡɨ����,faro

  % ScanLineArray = slice2scanlines(pointCloudData(1:space:end,:),1);%�������ڵ�����ȡɨ����,sick

    samplePointArray = getsamplepoint(ScanLineArray,startA,endA,startL,endL);%��������
    pointCloudData = pointArray2Point(samplePointArray);
%     savepointcloud2file(pointCloudData,filename,false);%�洢չ���ĵ���
%     imageData = convertpointcloud2img(pointCloudData,pxielSize);%��������ͼ��
    imageData = convertPD2img(pointCloudData,pxielSize);%�뾶����������ͼ��
    imageData = imageData*brightness;
    imwrite(imageData,strcat('orthoimage','.png'));%ͼ������
end

function  samplepoint = pointArray2Point(samplePointArray)
%
%������չ����ƽ��
      nSample = size(samplePointArray,2);
      nPoint = 0;
      for iSample = 1:nSample,
          %��������,���ڳ�ʼ��
        n = size(samplePointArray(iSample).x,1);
        nPoint =nPoint+n;
      end
      x = zeros(nPoint,1);
      y = zeros(nPoint,1);
      ins = zeros(nPoint,1);
      iPoint = 0;
      for iSample = 1:nSample,
          n = size(samplePointArray(iSample).x,1);
          x(iPoint+1:iPoint+n,1) = samplePointArray(iSample).x;
          l(iPoint+1:iPoint+n,1) = samplePointArray(iSample).l;
          ins(iPoint+1:iPoint+n,1) = samplePointArray(iSample).ins;
          iPoint = iPoint+n;
      end
      samplepoint = [x l zeros(nPoint,1) ins];
%       savepointcloud2file(samplepoint,savefilename,false);
end

function samplePointArray = getsamplepoint(ScanLineArray,startA,endA,startL,endL)
%
%������xΪ���ǰ������yohΪɨ���߶���
%��Բ�Ĵ�ֱ����Ϊ��ʼ����˳ʱ��Ϊ��
%startA��endAΪ��ȡ��ĽǶȷ�Χ��lenghtΪ��ȡ����̳���
%ÿ1000��ɨ���߽���һ��Բ��������
    lenght = 0;
    nScanline = size(ScanLineArray,2);
    %xΪ�������ǰ�����꣬yΪ�����꣬hΪ�����꣬AΪ��Բ�Ĵ�ֱ����˳ʱ������ļнǣ�rΪ����Բ�뾶��lΪ����ĸ��չ���ĺ�ĳ���
    PointSet= struct('x',0,'y',0,'h',0,'ins',0,'A',0,'r',0,'l',0);
    samplePointArray=repmat(PointSet,[1 nScanline]);  
    for iScanline = 1:nScanline
        x = ScanLineArray(iScanline).x;
        y = ScanLineArray(iScanline).y;
        h = ScanLineArray(iScanline).h;
        ins = ScanLineArray(iScanline).ins;
        
%         nPoint = size(x,1);      
%         plot3(x,y,h,'r.');axis equal;hold on;
%         continue;

        if mod(iScanline,1000)||iScanline==1
            para = ransac([y h],'circle',0.02);
            if(isempty(para))
                continue;
            end
            x0 = para(1,1);%����Բ�����꣬��Ӧ������y��h
            y0 = para(2,1);
            r = para(3,1);
            if iScanline~=1
                lenght0 = norm([x0Pre-x0 y0Pre-y0]);
                lenght = lenght+lenght0;
            end
            x0Pre = x0;
            y0Pre = y0;
        end
        if lenght>=startL&&lenght<=endL
            ;
        else
            continue;
        end 
            px = x;
            py = y;
            ph = h;
            pins = ins;
            A = atan2d(ph-y0,py-x0);%ע����atan2d(Y,X)
            A(A>=-90)=(A(A>=-90)+90);
            A(A<-90&A>=-180)=(A(A<-90&A>=-180)+450);   
            [row,~]=find(A>=startA&A<=endA);
            samplePointArray(iScanline).x = px(row);
            samplePointArray(iScanline).y = py(row);
            samplePointArray(iScanline).h = ph(row);
            samplePointArray(iScanline).ins = pins(row);
            samplePointArray(iScanline).A = A(row);
            samplePointArray(iScanline).r = r;
            samplePointArray(iScanline).l = (A(row)./180).*pi*r;   
%             plot3(px(row),py(row),ph(row),'go');axis equal;hold on;
    end   
end
