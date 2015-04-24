   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
    begin
       in = addfile("../momentum/wdudp.nc","r") 
       msl  = in->wdudp
;      lat = in->lat
;      lon = in->lon
;      lev = in->level
;      time = in->time
       print("finish reading")

;---Open workstation and change color map
      wks = gsn_open_wks("x11","ce")   
  gsn_define_colormap(wks,"BlAqGrYeOrRe")        ; choose colormap

  res                       = True     ; plot mods desired
  res@cnFillOn              = True     ; turn on color fill
  res@cnLinesOn             = False    ; turn of contour lines
  res@lbLabelStride         = 4

  res@pmTickMarkDisplayMode = "Always"; use NCL default lat/lon labels

  res@gsnAddCyclic          = False    ; data already has cyclic point
				       ; this must also be set for any zoom

; note that the gsn_csm_*map_ce templates automatically set 
; res@mpLimitMode="LatLon" for you. If you are plotting a different projection,
; you may have to set this resource.

  res@mpMinLatF            = -15      ; range to zoom in on
  res@mpMaxLatF            =  15.
  res@mpMinLonF            =  80.
  res@mpMaxLonF            = 100.
print("here")
  plot = gsn_csm_contour_map_ce(wks,msl(0,1,:,:), res)







    end
