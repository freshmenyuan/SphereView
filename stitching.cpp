
 // stitching.cpp
 //
 //  Created by peidong yuan on 01/09/2016.
 //  Copyright © 2016 peidong yuan. All rights reserved.
 //


#include "stitching.h"

bool try_use_gpu = true;
vector<Mat> imgs;
string result_name = "result.jpg";

vector<string> img_names;
bool preview = false;
bool try_gpu = false;
double work_megapix = 0.6;
double seam_megapix = 0.1;
double compose_megapix = -1;
float conf_thresh = 1.f;
string features_type = "surf";
string ba_cost_func = "ray";
string ba_refine_mask = "xxxxx";
bool do_wave_correct = true;
WaveCorrectKind wave_correct = detail::WAVE_CORRECT_HORIZ;
bool save_graph = false;
std::string save_graph_to;
string warp_type = "spherical";
int expos_comp_type = ExposureCompensator::GAIN_BLOCKS;
float match_conf = 0.3f;
string seam_find_type = "gc_color";
int blend_type = Blender::MULTI_BAND;
float blend_strength = 5;
Mat ZERO = Mat::zeros(3,3, CV_8UC1);

Mat stitch (vector<Mat>& images)
{
    imgs = images;
    Mat pano;
    Stitcher stitcher = Stitcher::createDefault(try_use_gpu);
    OrbFeaturesFinder *OrbFinder = new OrbFeaturesFinder();
    stitcher.setFeaturesFinder(OrbFinder);
//    stitcher.setFeaturesFinder(new SurfFeaturesFinder());
    Stitcher::Status status = stitcher.stitch(imgs, pano);
    
    if (status != Stitcher::OK)
        {
        cout << "Can't stitch images, error code = " << int(status) << endl;
            //return 0;
        }
    return pano;
}

