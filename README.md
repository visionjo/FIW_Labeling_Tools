Program:    Face Clustering Toolbox
Author:     Joseph P. Robinson
Email:      robinson.jo@husky.neu.edu
Created:    12/01/2016

TO DO: 
    - 

OVERVIEW: 
    MATLAB tools designed to label FIW dataset in a semi-automated fashion.
         
 MOTIVATION:
    Several families are incomplete (in terms of data, whether members and or samples per member). Having collected several additional photos for each family, and having existing family labels exist as prior knowledge, the goal of this project is to label new photos by leveraging prior knowledge to generate labels in a automated fashion (i.e., minimize manual labor needed to label).
       
CONTENTS: 

    setup.m
        Configures workspace for MATLAB tools.

Important directories:
 


REVISION HISTORY:

    11/29/2016:  Started Project
    12/01/2016:  Added utils to handle and organize existing FIW data (i.e., labeled data)                         
                            - Parse FID info into table format                (FIW.prepare_fid_table())

  
3rd Party Dependencies
In order to compile this software the following libraries are needed:
* VL_FEAT library (https://github.com/vlfeat/vlfeat, tested with v9.20)
    - USAGE: vl_svm
