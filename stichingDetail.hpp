//
//  stitch_detail.hpp
//  SwiftStitch
//
//  Created by peidong yuan on 18/09/2016.
//  Copyright © 2016 ellipsis.com. All rights reserved.
//

#ifndef stichingDetail_h
#define stichingDetail_h

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>
#include "opencv2/opencv_modules.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/stitching/detail/autocalib.hpp"
#include "opencv2/stitching/detail/blenders.hpp"
#include "opencv2/stitching/detail/camera.hpp"
#include "opencv2/stitching/detail/exposure_compensate.hpp"
#include "opencv2/stitching/detail/matchers.hpp"
#include "opencv2/stitching/detail/motion_estimators.hpp"
#include "opencv2/stitching/detail/seam_finders.hpp"
#include "opencv2/stitching/detail/util.hpp"
#include "opencv2/stitching/detail/warpers.hpp"
#include "opencv2/stitching/warpers.hpp"
#include "opencv2/core/core.hpp"
#include "opencv2/features2d/features2d.hpp"
#include "opencv2/calib3d/calib3d.hpp"
#include "opencv2/imgproc/imgproc.hpp"

using namespace std;
using namespace cv;
using namespace cv::detail;

class stichingDetail{
private:
    
public:
    stichingDetail();
    ~stichingDetail();
    Mat stiching(vector<string>& images);
    
    vector<string> img_names;
    bool preview = false;
    bool try_gpu = false;
    double work_megapix = 0.6;
    double seam_megapix = 0.1;
    double compose_megapix = -1;
    float conf_thresh = 1.f;
    string features_type = "orb";
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
    string result_name = "result.jpg";
    Mat ZERO = Mat::zeros(3,3, CV_8UC1);
};


#endif /* stichingDetail_h */
