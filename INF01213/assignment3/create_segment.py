import numpy as np
import cv2 as cv

iter = 5

img = cv.imread('./res/Luan.jpg')
mask = np.zeros(img.shape[:2],np.uint8)
bgdModel = np.zeros((1,65),np.float64)
fgdModel = np.zeros((1,65),np.float64)
rect = (50,50,900,500)
cv.grabCut(img,mask,rect,bgdModel,fgdModel,iter,cv.GC_INIT_WITH_RECT)
mask2 = np.where((mask==2)|(mask==0),0,1).astype('uint8')
img2 = img*mask2[:,:,np.newaxis]

cv.imwrite("./res/out-luan-rect" + str(iter) + ".jpg", img2)

newmask = cv.imread('./res/newluanmask.jpeg',0)
print(newmask)
mask[newmask == 0] = 0
mask[newmask == 255] = 1
mask, bgdModel, fgdModel = cv.grabCut(img,mask,None,bgdModel,fgdModel,iter,cv.GC_INIT_WITH_MASK)
mask = np.where((mask==2)|(mask==0),0,1).astype('uint8')
img3 = img*mask[:,:,np.newaxis]

cv.imwrite("./reyout.s/out-luan" + str(iter) + ".jpg", img3)
