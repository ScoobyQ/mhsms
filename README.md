# mhsms
NHS Digital MHSMS datasets

https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-services-monthly-statistics

Scripts currently filter on 2019/20 files and additionally filter out any files that are not an exact headers match for Aug 2020 csv. 
Whilst some earlier periods could pivot_longer various columns, as well as subset, to give the same headers, I believe there has been 
a change in indicator methodologies such that like for like comparisons are not possible.
