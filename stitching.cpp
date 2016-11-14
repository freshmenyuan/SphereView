/////////////////////////
/*
 
 // stitching.cpp
 // adapted from stitching.cpp sample distributed with openCV source.
 // adapted by Foundry for iOS
 
 */



/*M///////////////////////////////////////////////////////////////////////////////////////
//
//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//
//
//                          License Agreement
//                For Open Source Computer Vision Library
//
// Copyright (C) 2000-2008, Intel Corporation, all rights reserved.
// Copyright (C) 2009, Willow Garage Inc., all rights reserved.
// Third party copyrights are property of their respective owners.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//   * The name of the copyright holders may not be used to endorse or promote products
//     derived from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors "as is" and
// any express or implied warranties, including, but not limited to, the implied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage.
//
//

 M*/

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

