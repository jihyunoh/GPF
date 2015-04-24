#! /bin/csh

#foreach year (2012)
#foreach mon (03)
#foreach day (01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31)

foreach year (2011)
foreach mon (10)
foreach day (01)

cd /data2/dynamo/$year$mon$day
foreach hr (00 06 12 18)
set fn1 = "00"
set fn2 = "001"
ncl_convert2nc D1D$mon$day$hr$fn1$mon$day$hr$fn2.grb1 
mv D1D$mon$day$hr$fn1$mon$day$hr$fn2.nc $year$mon$day$hr.nc
#rm D1D$mon$day$hr$fn1$mon$day$hr$fn2.grb1

end

end
end
end
