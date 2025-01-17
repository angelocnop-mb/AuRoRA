function [lines,th] = plotLinesOnVid(img1)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
%%
% img1 = imread('C:\Users\alexa\Dropbox\AuRoRA 2018\Vision\Screenshot_2.png');
t = tic;
med = uint8(mean(img1,3));
img = img1-med;

I = impyramid(img, 'reduce');
I = impyramid(I, 'reduce');
I = impyramid(I, 'reduce');

img = impyramid(img, 'reduce');
img = impyramid(img, 'reduce');
img = impyramid(img, 'reduce');

BW1 = imbinarize(img1,'global');
BW1 = impyramid(BW1, 'reduce');
BW1 = impyramid(BW1, 'reduce');
BW1 = impyramid(BW1, 'reduce');
% for ii = 1:3
BW = edge(BW1(:,:,2),'canny');
% BW = edge(BW1(:,:,ii),'canny');

[H,T,R] = hough(BW);
P  = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
x = T(P(:,2)); y = R(P(:,1));


lines = houghlines(BW,T,R,P,'FillGap',5,'MinLength',7);


img1 = impyramid(img1, 'reduce');
img1 = impyramid(img1, 'reduce');
img1 = impyramid(img1, 'reduce');

figure(1)
imshow(img1)
hold on
max_len = 0;
for k = 1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   
   plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');

   % Plot beginnings and ends of lines
   plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
   plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');

   % Determine the endpoints of the longest line segment
   len = norm(lines(k).point1 - lines(k).point2);
   if ( len > max_len)
      max_len = len;
      xy_long = xy;
      th = T(k);
   end
end
plot(xy_long(:,1),xy_long(:,2),'LineWidth',2,'Color','cyan')
disp(toc(t))
% figure
% subplot(311)
% imshow(BW1(:,:,1))
% subplot(312)
% imshow(BW1(:,:,2))
% subplot(313)
% imshow(BW1(:,:,3))
% figure
% imshow(BW)
% end
%%
end

