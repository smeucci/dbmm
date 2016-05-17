/* 
    Created on: Feb 8, 2016
        Author: saverio
       
    Detects the faces in an image and print the box coordinates.
    
    Extension of the dlib face detector. Compile with cmake inside example folder.
    
*/


#include <dlib/image_processing/frontal_face_detector.h>
#include <dlib/gui_widgets.h>
#include <dlib/image_io.h>
#include <iostream>

using namespace dlib;
using namespace std;

// ----------------------------------------------------------------------------------------

int main(int argc, char** argv) {
    
    if (argc == 1) {
        cout << "Give some image files as arguments to this program." << endl;
        return 0;
    }
    
    //load the face detector
    frontal_face_detector detector = get_frontal_face_detector();
    
    bool scaled;
    for (int i = 1; i < argc; i++) {
    
        try {
            //load the image
            array2d<unsigned char> img;
            load_image(img, argv[i]);
            
            //scale up the image by a factor of two if too small
            scaled = false;
            if (img.nr() < 1000 && img.nc() < 1000) {
            
                pyramid_up(img);
                scaled = true;
                
            }
            
            //detect the faces in the image
            std::vector<rectangle> dets = detector(img);
            //cout << "Number of faces detected: " << dets.size() << endl;
            
            //for every face, print the box coordinates
            rectangle box;
            for (int j = 0; j < dets.size(); j++) {
            
                box = dets.at(j);
                int left, top, right, bottom;
                if (scaled == false) {
                
                    left = box.left();
                    top = box.top();
                    right = box.right();
                    bottom = box.bottom();
                    
                } else if (scaled == true) {
                
                    left = box.left() / 2;
                    top = box.top() / 2;
                    right = box.right() / 2;
                    bottom = box.bottom() / 2;
                    
                }
                
                cout << argv[i] << "+" << left << "+" << top << "+" << right << "+" << bottom  << ";" << endl;
                
            }
                
        }
        
        catch (exception& e) {
        
            //cout << "Error: " << e.what() << endl;
            
        }
      
    }

}

// ----------------------------------------------------------------------------------------
