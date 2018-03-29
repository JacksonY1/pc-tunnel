function getinnerrings(pcdFilePathOrData)
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% �ж���������ļ�·�����ǵ��ƾ���
[row,col] = size(pcdFilePathOrData);
if row>1&&col>=4
    pointCloudData = pcdFilePathOrData;
elseif row==1
    [path,filename,filetype]=fileparts(pcdFilePathOrData);
    if(filetype=='.las')
        A = LASreadAll(pcdFilePathOrData);
        pointCloudData=[A.x,A.y,A.z,A.intensity];
        savepointcloud2file(pointCloudData,filename,false);
    elseif(filetype=='.xyz')
        fid=fopen(pcdFilePathOrData,'r');
%         pointCloudData = readpointcloudfile2(pcdFilePathOrData);%��ȡȫ����
        pointCloudData =  readpointcloudfile(fid,10000000);%��ȡָ��������
    else
        return;
    end
else 
    return;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% �������Ƭ�ӷ�
[imageData,PCD] = getorthoimage(pointCloudData,0.01,5,80,110);
initialX = PCD(1,1);%���Ͻǵ�һ�����ص���ʼ���
[rings_locs,rings_wdith,rings_num]=getringsfromimg(imageData);
rings_locs = rings_locs*0.01+initialX;
ScanLineArray = getscanline_faro(pointCloudData,2);%����䶯��ȡɨ����,faro

%����Ƭ����д�뵽�ļ�
% ringspointArray = cell();%���ڴ洢��Ƭ��������
ringscanlineiIdx = [];%
nScanLine = size(ScanLineArray,2);
iScanLine = 1;
mkdir('rings');
for iloc=1:size(rings_locs,1)
    loc = rings_locs(iloc,1);
    ringdata = [];
    while(iScanLine<=nScanLine)
        x = ScanLineArray(iScanLine).x;%ע��ÿ��ɨ����x������һ����,�����������ӵ�
        X = x(1,1);
        if(loc>=X)
            y = ScanLineArray(iScanLine).y;
            h = ScanLineArray(iScanLine).h;
            ins = ScanLineArray(iScanLine).ins;
            ringdata = [ringdata;x,y,h,ins];
            iScanLine = iScanLine+1;
        else
            if ~isempty(ringdata)
                ringscanlineiIdx(iloc) = iScanLine-1;
                ringspointArray(iloc) = {ringdata};
%                 savepointcloud2file(ringdata,strcat('rings\',num2str(iloc)),false);
            end
            break;
        end
    end
end
ringscanlineiIdx = [0,ringscanlineiIdx];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%����ÿһ����������
%����ͨ��ʶ��ⶥ����ж�λ
for i=1:size(ringspointArray,2)
    % �ⶥ������λ��Ӱ��
    [imageData,PCD] = getorthoimage(ringspointArray{i},0.01,5,135,245,[],[],1);
    
    % ʶ��ⶥ��
    [lines1,lines2,flag] = gettopring(imageData);
    midA = 135+(245-135)/size(imageData,1)*(lines1.point1(2)+lines2.point1(2))/2;%�ⶥ���м�λ�ýǶ�
    
    %��ȡ���ڻ�Ƭ����
    topPointArray = getsamplepoint(ScanLineArray(ringscanlineiIdx(i)+1:ringscanlineiIdx(i+1)),midA-17.5,midA+17.5);
    right1Array = getsamplepoint(ScanLineArray(ringscanlineiIdx(i)+1:ringscanlineiIdx(i+1)),midA-82.5,midA-17.5);
    right2Array = getsamplepoint(ScanLineArray(ringscanlineiIdx(i)+1:ringscanlineiIdx(i+1)),midA-147.5,midA-82.5);
    left1Array = getsamplepoint(ScanLineArray(ringscanlineiIdx(i)+1:ringscanlineiIdx(i+1)),midA+17.5,midA+82.5);
    [left2Array,x0,y0,r] = getsamplepoint(ScanLineArray(ringscanlineiIdx(i)+1:ringscanlineiIdx(i+1)),midA+82.5,midA+147.5);
%     bottomArray = getsamplepoint(ScanLineArray(ringscanlineiIdx(i)+1:ringscanlineiIdx(i+1)),midA-82.5,midA-17.5);

    %����ڻ�����Ƶ�Բ����
    [topx0,topy0,topr] = getcirclepara(topPointArray);
    [right1x0,right1y0,right1r] = getcirclepara(right1Array);
    [right2x0,right2y0,right2r] = getcirclepara(right2Array);
    [left1x0,left1y0,left1r] = getcirclepara(left1Array);
    [left2x0,left2y0,left2r] = getcirclepara(left2Array);
%     [x0,y0,r] = getcirclepara(topPointArray);

    % ���ڻ�����ϲ����洢���ļ�
    path = strcat('rings\',num2str(i));
    mkdir(path);
    x0 = [x0 topx0 right1x0 right2x0 left1x0 left2x0]';
    y0 = [y0 topy0 right1y0 right2y0 left1y0 left2y0]';
    r = [r topr right1r right2r left1r left2r]';
    result = [x0 y0 r];
    fid1=fopen(strcat(path,'\',num2str(i),'.txt'),'wt');
    fprintf(fid1,'%.4f %.4f %.4f\n',result');
    fclose(fid1);

    %�������ڻ�Ƭ�洢���ļ���
    topPoint = pointArray2Point(topPointArray,2);
    right1Point = pointArray2Point(right1Array,2);
    right2Point = pointArray2Point(right2Array,2);
    left1Point = pointArray2Point(left1Array,2);
    left2Point = pointArray2Point(left2Array,2);
    savepointcloud2file(topPoint,strcat(path,'\','topPoint'),false);
    savepointcloud2file(right1Point,strcat(path,'\','right1Point'),false);
    savepointcloud2file(right2Point,strcat(path,'\','right2Point'),false);
    savepointcloud2file(left1Point,strcat(path,'\','left1Point'),false);
    savepointcloud2file(left2Point,strcat(path,'\','left2Point'),false);
end

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
function  samplepoint = pointArray2Point(samplePointArray,type)
%
%���ṹ��ת���ɵ��ƾ���,type=1��ʾչ����ƽ�棬type=2��ʾԭʼ����ת��
      nSample = size(samplePointArray,2);
      nPoint = 0;
      for iSample = 1:nSample,
          %��������,���ڳ�ʼ��
        n = size(samplePointArray(iSample).x,1);
        nPoint =nPoint+n;
      end
      x = zeros(nPoint,1);
      y = zeros(nPoint,1);
      h = zeros(nPoint,1);
      ins = zeros(nPoint,1);
      iPoint = 0;
      for iSample = 1:nSample,
          n = size(samplePointArray(iSample).x,1);
          x(iPoint+1:iPoint+n,1) = samplePointArray(iSample).x;
          y(iPoint+1:iPoint+n,1) = samplePointArray(iSample).y;
          h(iPoint+1:iPoint+n,1) = samplePointArray(iSample).h;
          l(iPoint+1:iPoint+n,1) = samplePointArray(iSample).l;
          ins(iPoint+1:iPoint+n,1) = samplePointArray(iSample).ins;
          iPoint = iPoint+n;
      end
      if(type==1)
        samplepoint = [x l zeros(nPoint,1) ins];
      elseif(type==2)
        samplepoint = [x y h ins];
      end
%       savepointcloud2file(samplepoint,savefilename,false);
end

function [samplePointArray,x0,y0,r]= getsamplepoint(ScanLineArray,startA,endA,startL,endL)
%
%������xΪ���ǰ������yohΪɨ���߶���
%��Բ�Ĵ�ֱ����Ϊ��ʼ����˳ʱ��Ϊ��
%startA��endAΪ��ȡ��ĽǶȷ�Χ��lenghtΪ��ȡ����̳���
%ÿ1000��ɨ���߽���һ��Բ��������

if ~exist('startL','var')||isempty(startL),startL = 0;end
if ~exist('endL','var')||isempty(endL),endL = 99999;end

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



