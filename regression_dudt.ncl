; Specify the location of your NCL as $NCARG_ROOT in your .cshrc for csh users
; Ex) setenv NCARG_ROOT /usr/local/ncarg

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

 begin

; Specify domain where predictor (e.g., TRMM) is averaged.

 latN=5.0
 latS=0.0
 lonL=360+73.
 lonR=360+80.

; Number of vertical level
nlev=25
; Explicit vertical level
lev = (/150,200,250,300,400,500,600,700,800,850,900,925,950,1000/)

; Create time and vertical level arrays from inFile
; inFile has 4-dimensional (x,y,z,t) data structure spanning from Oct-01-2011 to Mar-31-2012

 inFile = addfile("../momentum/U.nc","r")
 timeUnits = inFile->time@units
 startDynamo = ut_inv_calendar( 2011, 10, 01, 00, 0, 0, timeUnits, 0 )
 endDynamo   = ut_inv_calendar( 2012, 03, 31, 18, 0, 0, timeUnits, 0 )
 time = inFile->time
 level=inFile->level
 delete(inFile)

; Read predictor: every 6-hour (00, 06, 12, 18 UTC) TRMM data are located in 'trmm' directory 
 
  files = systemfunc ("ls ../trmm/3B42*.7.nc")
  f = addfiles (files, "r")
  ListSetType (f, "Join")
  pcp = f[:]->pcp(:,0,{latS:latN},{lonL-360:lonR-360})

;Array average
  ulon = dim_avg_n_Wrap(pcp,2)
  delete(pcp)
  uTS = dim_avg_n_Wrap(ulon,1)

;5-day running mean: 4 times per day x 5-day = 20
  TS = runave_n (uTS, 20, 1, 0)

  TS!0="time"
  TS&time=time
  TS&time = ut_convert( TS&time, timeUnits )
  TSdynamo=TS({startDynamo:endDynamo})
  ntt=dimsizes(TS)

  trmmMean = avg(TS)
  trmmStd = stddev(TS)

  trmmxtrmm = TS*TS
  b2 = dim_sum_n( trmmxtrmm, 0 )

; Read predictand: dudt =============================

  inFile = addfile("../momentum/dudt.nc","r")

; Convert unit from m/sec/sec to m/sec/day by multyplying 86400
  u = inFile->U_ten(:,:,{latS:latN},{lonL:lonR})*86400
  runU = runave_n(u,20,1,0)
  delete(u)
  delete(inFile)
  runUStd = dim_stddev_n( runU, 0 ) 

  runUrunU=runU

  do it=0,ntt-1
  runU(it,:,:,:) = TS(it)*runU(it,:,:,:)
  runUrunU(it,:,:,:) = runU(it,:,:,:)*runU(it,:,:,:)

  end do

  b1 = dim_sum_n( runU, 0 )
  b3 = dim_sum_n( runUrunU, 0 )

  b=b1/sqrt(b2*b3)*(runUStd/trmmStd)

  reg=b*trmmStd
  reglon=dim_avg_n_Wrap(reg,2)
  regdudt=dim_avg_n_Wrap(reglon,1)
  regdudt!0="level"
  regdudt&level=level

 data      = new((/1,dimsizes(lev)/),float)
 data!1="level"
 data&level=lev

 data(0,:) = regdudt({1000:150})

;************************************************
; create plot
;************************************************
 wks   = gsn_open_wks ("pdf","regression_dudt_NA")     ; open pdf file

 res                   = True                       ; plot mods desired
 res@trYReverse        = True                       ; reverse Y-axis
 res@gsnFrame          = False                      ; don't advance frame yet

  res@vpHeightF 	 = 0.7               ; change aspect ratio of plot
  res@vpWidthF 	         = 0.4

 res@xyLineColors = (/"Red"/)
 res@xyLineThicknesses	 = (/3./)      ; line thicknesses
  res@xyDashPatterns	 = (/0./)      ; make all lines solid

; add a legend
 res@pmLegendDisplayMode    = "Always"              ; turn on legend
 
 res@pmLegendSide           = "Top"                 ; Change location of 
 res@pmLegendParallelPosF   = .30                   ; move units right
 res@pmLegendOrthogonalPosF = -0.8                  ; more neg = down
  
 res@pmLegendWidthF         = 0.12                  ; Change width and
 res@pmLegendHeightF        = 0.25                  ; height of legend.
 res@lgLabelFontHeightF     = .02                   ; change font height
 res@lgPerimOn              = False                 ; no box around
; labels for the legend
 res@xyExplicitLegendLabels = (/"dudt"/)
 res@tmYLMode          = "Explicit"                ; explicit labels
 res@tiYAxisString       = "Pressure (hPa)"
 res@tmYLValues        = (/1000,950,925,900,850,800,700,600,500,400,300,250,200,150/)
 res@tmYLLabels        = ""+res@tmYLValues         ; make strings

 plot  = gsn_csm_xy (wks,data,data&level,res)            ; create plot
;************************************************
; add polyline
;************************************************
 
 gsn_polyline(wks,plot,(/0,0/),(/0,1000/),False)
 frame(wks)


end








