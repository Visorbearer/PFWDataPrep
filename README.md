# PFW Data Preparation for Occupancy Modeling

## Overview
This code details how to prepare raw data from **Project FeederWatch** (PFW), a citizen science project run by the Cornell Lab of Ornithology and Birds Canada, for use in R. The code template established is derived from *Greig et al. (2017)* and *Maron et al. (In Review)*. The provided script specifically walks through the steps needed to clean, filter, and zero-fill PFW data prior to modeling. Referring to the [Project FeederWatch Data Dictionary](https://clo-pfw-prod.s3.us-west-2.amazonaws.com/data/202306/FeederWatch_Data_Dictionary.xlsx) prior to using this code will help significantly in understanding each step and its results. 

## Data Sourcing
Data for use in this code can be downloaded directly from the [Project FeederWatch data request page](https://feederwatch.org/explore/raw-dataset-requests/). More information about the dataset is available from this publication:
> **Bonter, D. N., & Greig, E. I. (2021). *Over 30 years of standardized bird counts at supplementary feeding stations in North America: A citizen science data report for Project FeederWatch.* Frontiers in Ecology and Evolution. [https://doi.org/10.3389/fevo.2021.619682](https://doi.org/10.3389/fevo.2021.619682)**

## Zero-Filling
In this code, a specific method of zero-filling is provided. If preferred, an alternative method is available at this repository: https://github.com/engagement-center/Project-FeederWatch-Zerofilling-Taxonomic-Rollup-Public. It can be seamlessly integrated into the work flow here in place of the existing zero-filling code. If you choose to use this alternative, please give the appropriate credits and follow appropriate protocols as detailed within its `README` file. 

## Acknowledgements
As always, please credit Birds Canada and the Cornell Lab of Ornithology for establishing and managing Project FeederWatch, as well as the numerous contributors who have provided observations necessary to form its dataset. If this code is used in a publication, please cite *Maron et al. (In Review)* as its source.
