; Specify the location of your NCL as $NCARG_ROOT in your .cshrc for csh users
; Ex) setenv NCARG_ROOT /usr/local/ncarg

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

 begin

  ; Select domain for spatial average
  ; Ex)73E-80E, wlat = 360+40 (western longitudinal boundary), elon = 360+160 (eastern longitudinal boundary)
  ; Equator-5N, slat = 0 (southern latitudinal boundary) nlat = 5 (northern latitudinal boundary)

       latN=5.0
       latS=0.0
       lonL=360+73.
       lonR=360+80.
       nlev=25

  inFile = addfile("../momentum/vdudy.nc","r")
  in = addfile("../momentum/dudt.nc","r")
  timeUnits = inFile->time@units
  startDynamo = ut_inv_calendar( 2011, 10, 01, 00, 0, 0, timeUnits, 0 )
  endDynamo   = ut_inv_calendar( 2011, 12, 31, 18, 0, 0, timeUnits, 0 )
  vdudy = inFile->vdudy(:,:,{latS:latN},{lonL:lonR})*-86400
  dudt = in->U_ten(:,:,{latS:latN},{lonL:lonR})*86400
  time = inFile->time
  level = inFile->level

  vdudy@_FillValue = 1e20
  dudt@_FillValue = 1e20

  vdudylon = dim_avg_n_Wrap(vdudy,2)
  dudtlon = dim_avg_n_Wrap(dudt,2)
  delete(vdudy)
  delete(dudt)

  vdudyTS = dim_avg_n_Wrap(vdudylon,2)
  dudtTS = dim_avg_n_Wrap(dudtlon,2)

  vdudyTS = runave_n (vdudyTS, 20, 1, 0)
  dudtTS = runave_n (dudtTS, 20, 1, 0)
;  dudtTS = runave_n (dudtTS, 3, 1, 1)

  vdudyTS!0="time"
  dudtTS!0="time"
  vdudyTS!1="level"
  dudtTS!1="level"
  nlev=dimsizes(level)
  ntt=dimsizes(time)

  vdudyTSplot=new((/nlev,ntt/),"float",1e20)
  dudtTSplot=new((/nlev,ntt/),"float",1e20)

  vdudyTSplot=vdudyTS(level|:,time|:)
  dudtTSplot=dudtTS(level|:,time|:)

  vdudyTSplot!0="level"
  dudtTSplot!0="level"
  vdudyTSplot!1="time"
  dudtTSplot!1="time"
  vdudyTSplot&time=time
  dudtTSplot&time=time
  vdudyTSplot&level=level
  dudtTSplot&level=level
  vdudyTSplot&time = ut_convert( vdudyTSplot&time, timeUnits )
  dudtTSplot&time = ut_convert( dudtTSplot&time, timeUnits )

;================================================
;first plot (-vdu/dy in shading)
;================================================
 wks                 = gsn_open_wks ("ps", "vdudy_NA_5dayrave_2011" )     ; open workstation
 gsn_define_colormap(wks,"BlGrYeRe")

 res                 = True                               ; plot mods desired
  res@gsnDraw      = False                        ; don't draw yet
  res@gsnFrame     = False                        ; don't advance frame yet

 res@cnFillOn = True
 res@cnLinesOn            = False
 res@cnLevelSelectionMode = "ManualLevels"
 res@cnMinLevelValF = -10.0
 res@cnMaxLevelValF = 10.0
 res@cnLevelSpacingF = 1

res@tmYLMode               = "Manual"
res@tmYLTickStartF         = 1000.0
res@tmYLTickSpacingF       = 100.0
res@tmYLTickEndF           = 100.0
res@tmYLMinorPerMajor      = 0
res@tmXBLabelFontHeightF = 0.03
res@tmYLLabelFontHeightF = 0.03

 res@tiMainString    = "Meridional advection"               ; title
 res@vpWidthF = 0.7
 res@vpHeightF = 0.4
 res@tmXTon = False
; note this data is already on pressure levels. If this were model
; data, it would be necessary to convert from hybrid to pressure levels
; before plotting.
 restick = True
;restick@ttmFormat = "%D %C %H"
 restick@ttmFormat      = "%c%D"
;restick@ttmFormat = "%D %C"

restick@ttmMajorStride = 60
;restick@ttmNumTicks = 4
restick@ttmAxis = "XB"
time_axis_labels(vdudyTSplot&time,res,restick)
 res@tiYAxisString = "Pressure (hPa)"
 res@tiXAxisString = "Time"

;  res@tmYLTickSpacingF     = 100             ;
res@trYLog = False
 vdudyplot = gsn_csm_pres_hgt (wks,vdudyTSplot({1000:100},{startDynamo:endDynamo}),res)

;================================================
;second plot (dudt in contour)
;================================================

 res@cnFillOn = False
 res@cnLinesOn            = True
 res@cnLineColor = "Black"
; res@cnLevelSelectionMode = "ManualLevels"
;  res@cnMinLevelValF       = -10.                ; set min contour level
;  res@cnMaxLevelValF       =  10.                ; set max contour level
;  res@cnLevelSpacingF      =   1.                ; set contour spacing
   res@gsnContourNegLineDashPattern = 1       ; sets negative contours to dash pattern 1
res@gsnContourZeroLineThicknessF = 2 	    ; eliminates zero contour
res@cnInfoLabelOn = False
res@cnLineLabelsOn       = False
  res@gsnRightString   = ""    
  res@gsnLeftString    = ""
  res@gsnCenterString  = ""
 dudtplot = gsn_csm_pres_hgt (wks,dudtTSplot({1000:100},{startDynamo:endDynamo}),res)

 overlay(vdudyplot,dudtplot)
 draw(vdudyplot)
frame(wks)




end








