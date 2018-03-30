function [rings_locs,rings_num,rings_wdith] = getrings(pointCloudFilePath)
% ����ʶ��
% [rings_locs,rings_num,rings_wdith] = getrings(pointCloudFilePath)
% pointCloudFilePath - ��������ļ�·��
% rings_locs - �������λ��
% rings_num - ��Ƭ��Ŀ
% rings_wdith - ��Ƭ��ȣ���ά����������һ��Ϊ��Ƭ��ȣ��ڶ���Ϊ�������0��ʾ������1��ʾ�����Ŀ�ȴ����쳣
pxielSize = 0.01;
    [imageData,PCD] = getorthoimage(pointCloudFilePath,pxielSize,5,120,150);
    initialX = PCD(1,1);
    [rings_locs,rings_wdith,rings_num]=getringsfromimg(imageData);
    rings_locs = rings_locs*pxielSize+initialX;
    rings_wdith(:,2) = rings_wdith(:,2).*pxielSize;
    result = [rings_num;rings_locs];
    fid1=fopen('getrings_result.txt','wt');
    fprintf(fid1,'%.2f\n',result');
    fclose(fid1);
end