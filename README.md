
INSTALLATION GUIDE
=============

### Dependencies

1. Download libsvm from [LINK](https://www.csie.ntu.edu.tw/~cjlin/libsvm/#download). 
   Move it to the root folder of the project and rename it libsvm.
   To compile it, go in Matlab to libsvm/matlab and run the function make.m.

2. Download matconvnet from [LINK](http://www.vlfeat.org/matconvnet/).
   Move it to the root folder of the project and rename it matconvnet.
   To compile it, go in Matlab to matconvnet/matlab and run vl_compilenn.
   
3. Download VGG Face Matconvnet from [LINK](http://www.robots.ox.ac.uk/~vgg/software/vgg_face/).
   Move it to the root folder of the project and rename it vgg_face_matconvnet.
   If the mex-file for your system are not present, copy the mex file for vl_nnconv and vl_nnpool from matconvnet/matlab/simplenn to vgg_face_matconvnet/+lib/+face_feats/@convNet/ .
   
4. Download DLib from [LINK](http://dlib.net/).
   Move it to the root folder of the project and rename it dlib.
   To compile it, first copy face_detector/face_detector.cpp to dlib/examples. Then go to dlib/examples/ with a terminal and run:
   ```
    mkdir build
    cd build
    cmake ..
    cmake --build .
    ```
    
5. Download the JDBC driver from [LINK](http://dev.mysql.com/downloads/connector/j/) to be able to use Mysql with Matlab.
   To install it, follow the instruction at [LINK](http://it.mathworks.com/products/database/driver-installation.html).
   
6. Other dependencies:
   - Stack LAMP.
   - MySQLdb and bs4 (BeautifulSoup) library for python.
   
   
#### Setup

1. Go to root_of_project/ImagesCollector/conf/, make a copy of proto.conf and call it config.conf.
Then fill the parameters inside the configuration file.

2. Insert a list of identities (identities.mat or identities.txt) in DATA_PATH/data/.


#### Web App

1. Copy the application to /var/www/.
2. Configure database.php with the database called DATABASE_DATASET in config.conf.
3. Make a symbolic link to the folder where the cropped images are, the same path used for DATA_PATH in config.conf:
    ```
    ln DATA_PATH/img_crop/ /var/media/name_of_the_web_app/media
    ```
