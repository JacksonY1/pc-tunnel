tunnelData = readpointcloudfile2('../../LAS2.xyz');%��ȡ�����������
[imageData,pointCloudData_ortho] = getorthoimage(tunnelData);%��������Ӱ��
imshow(imageData);
[rings_locs,rings_num,rings_wdith] = getrings(tunnelData);%�ݽӷ�ʶ��
imshow(imread('result_rings.png'));