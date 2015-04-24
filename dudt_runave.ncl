
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/kf_filter.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

 begin

       latN=0.0
       latS=-7.0
       lonL=360+73.
       lonR=360+80.
       nlev=25

  lon=fspan(180,539.75,1440)
;;total period of MJO2

  inFile = addfile("../momentum/dudt.nc","r")
  timeUnits = inFile->time@units
  startDynamo = ut_inv_calendar( 2011, 10, 01, 00, 0, 0, timeUnits, 0 )
  endDynamo   = ut_inv_calendar( 2011, 12, 31, 18, 0, 0, timeUnits, 0 )
  u = inFile->U_ten(:,:,{latS:latN},{lonL:lonR})*86400

  printVarSummary(u)
  time = inFile->time
  level = inFile->level
  u@_FillValue = 1e20
  ulon = dim_avg_n_Wrap(u,2)
  uTS = dim_avg_n_Wrap(ulon,2)
  TS = runave_n (uTS, 20, 1, 0)
  print(num(ismissing(TS)))
  TS!0="time"
  TS!1="level"
  printVarSummary(TS)
  nlev=dimsizes(level)
  ntt=dimsizes(time)
  TSplot=new((/nlev,ntt/),"float",1e20)
  TSplot=TS(level|:,time|:)
  TSplot!0="level"
  TSplot!1="time"
  TSplot&time=time
  TSplot&level=level
  printVarSummary(TSplot)
  TSplot&time = ut_convert( TSplot&time, timeUnits )
;================================================
 wks                 = gsn_open_wks ("ps", "dudt_SA_5dayrave_2011" )     ; open workstation
 gsn_define_colormap(wks,"BLWhRe")
 res                 = True                               ; plot mods desired
 res@cnFillOn = True
 res@cnLinesOn = True
 res@cnLevelSelectionMode = "ManualLevels"
 res@cnMinLevelValF = -10.0
 res@cnMaxLevelValF = 10.0
 res@cnLevelSpacingF = 1

 res@tiMainString    = "zonal wind tendency (5-day moving)"               ; title
 res@vpWidthF = 0.7
 res@vpHeightF = 0.4
 res@tmXTon = False
; note this data is already on pressure levels. If this were model
; data, it would be necessary to convert from hybrid to pressure levels
; before plotting.
 restick = True
;restick@ttmFormat = "%D %C %H"
 restick@ttmFormat      = "%N%D"
;restick@ttmFormat = "%D %C"

restick@ttmMajorStride = 60
;restick@ttmNumTicks = 4
restick@ttmAxis = "XB"
time_axis_labels(TSplot&time,res,restick)
 res@tiYAxisString = "Pressure (hPa)"
 res@tiXAxisString = "Time"

;  res@tmYLTickSpacingF     = 100             ;
 plot = gsn_csm_pres_hgt (wks,TSplot({1000:150},{startDynamo:endDynamo}),res)

end








