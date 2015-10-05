pro match, a, b, suba, subb, COUNT = count, SORT = sort, $
           COMPLEMENTA = complementa, COMPLEMENTB = complementb 
; 
; downloaded by Lizzie Good on 05/06/08 from: 
; http://astro.uni-tuebingen.de/software/idl/astrolib/misc/match.pro
;+
; NAME:
;       MATCH
; PURPOSE:
;       Routine to match values in two vectors.
;
; CALLING SEQUENCE:
;       match, a, b, suba, subb, [ COUNT =, /SORT ]
;
; INPUTS:
;       a,b - two vectors to match elements, numeric or string data types
;
; OUTPUTS:
;       suba - subscripts of elements in vector a with a match
;               in vector b
;       subb - subscripts of the positions of the elements in
;               vector b with matchs in vector a.
;
;       suba and subb are ordered such that a[suba] equals b[subb]
;
; OPTIONAL INPUT KEYWORD:
;       /SORT - By default, MATCH uses two different algorithm: (1) the 
;               /REVERSE_INDICES keyword to HISTOGRAM is used for integer data,
;               while a sorting algorithm is used for non-integer data.   The
;               histogram algorithm is usually faster, except when the input
;               vectors are sparse and contain very large numbers, possibly
;               causing memory problems.   Use the /SORT keyword to always use
;               the sort algorithm.
;               
; OPTIONAL KEYWORD OUTPUT:
;       COUNT - set to the number of matches, integer scalar
;       COMPLEMENTA - set to the complement of a where there are no matches
;       COMPLEMENTB - set to the complement of b where there are no matches
;
; SIDE EFFECTS:
;       The obsolete system variable !ERR is set to the number of matches;
;       however, the use !ERR is deprecated in favor of the COUNT keyword 
;
; RESTRICTIONS:
;       The vectors a and b should not have duplicate values within them.
;       You can use rem_dup function to remove duplicate values
;       in a vector
;
; EXAMPLE:
;       If a = [3,5,7,9,11]   & b = [5,6,7,8,9,10]
;       then 
;               IDL> match, a, b, suba, subb, COUNT = count
;
;       will give suba = [1,2,3], subb = [0,2,4],  COUNT = 3
;       and       suba[a] = subb[b] = [5,7,9]
;
; 
; METHOD:
;       For non-integer data types, the two input vectors are combined and
;       sorted and the consecutive equal elements are identified.   For integer
;       data types, the /REVERSE_INDICES keyword to HISTOGRAM of each array
;       is used to identify where the two arrays have elements in common.   
; HISTORY:
;       D. Lindler  Mar. 1986.
;       Fixed "indgen" call for very large arrays   W. Landsman  Sep 1991
;       Added COUNT keyword    W. Landsman   Sep. 1992
;       Fixed case where single element array supplied   W. Landsman Aug 95
;       Converted to IDL V5.0   W. Landsman   September 1997
;       Use a HISTOGRAM algorithm for integer vector inputs for improved 
;             performance                W. Landsman         March 2000
;       Work again for strings           W. Landsman         April 2000
;       Use size(/type)                  W. Landsman         December 2002
;       Work for scalar integer input    W. Landsman         June 2003
;       Added COMPLEMENTA and COMPLEMENTB keywords - Elizabeth Good, Jun 2008
;-
;-------------------------------------------------------------------------
 On_error,2

 if N_params() LT 3 then begin
     print,'Syntax - match, a, b, suba, subb, [ COUNT = ]'
     print,'    a,b -- input vectors for which to match elements'
     print,'    suba,subb -- output subscript vectors of matched elements'
     return
 endif

 da = size(a,/type) & db =size(b,/type)
 if keyword_set(sort) then hist = 0b else $
 hist = (( da LE 3 ) or (da GE 12)) and  ((db LE 3) or (db GE 12 )) 

 na = N_elements(a)              ;number of elements in a
 nb = N_elements(b)             ;number of elements in b

 if not hist then begin           ;Non-integer calculation
 

; Check for a single element array

 if (na EQ 1) or (nb EQ 1) then begin
        if (nb GT 1) then begin
                subb = where(b EQ a[0], nw, COMPLEMENT=complementb)
                if (nw GT 0) then BEGIN
		   suba = replicate(0,nw)
		   complementa= REPLICATE(1,nw)
		ENDIF else BEGIN
		   suba = [-1]
		   complementa = [0]
		ENDELSE
        endif else begin
                suba = where(a EQ b[0], nw, COMPLEMENT=complementa)
                if (nw GT 0) then BEGIN
		   subb = replicate(0,nw) 
		   complementb = REPLICATE(1, nw)
		ENDIF else BEGIN
		   subb = [-1]
		   complementb = [0]
		ENDELSE
        endelse
        count = nw
        return
 endif
        
 c = [ a, b ]                   ;combined list of a and b
 ind = [ lindgen(na), lindgen(nb) ]       ;combined list of indices
 vec = [ bytarr(na), replicate(1b,nb) ]  ;flag of which vector in  combined 
                                         ;list   0 - a   1 - b

; sort combined list

 sub = sort(c)
 c = c[sub]
 ind = ind[sub]
 vec = vec[sub]

; find duplicates in sorted combined list

 n = na + nb                            ;total elements in c
 firstdup = where( (c EQ shift(c,-1)) and (vec NE shift(vec,-1)), Count)

 if Count EQ 0 then begin               ;any found?
        suba = lonarr(1)-1
        subb = lonarr(1)-1
	complementa = LINDGEN(na)
	complementb = LINDGEN(nb)
        return
 end
 
 dup = lonarr( Count*2 )                     ;both duplicate values
 even = lindgen( N_elements(firstdup))*2     ;Changed to LINDGEN 6-Sep-1991
 dup[even] = firstdup
 dup[even+1] = firstdup+1
 ind = ind[dup]                         ;indices of duplicates
 vec = vec[dup]                         ;vector id of duplicates
 suba = ind[ where( vec EQ 0)  ]       ;a subscripts
 subb = ind[ where( vec) ]             ;b subscripts

 endif else begin             ;Integer calculation using histogram.

 minab = min(a, MAX=maxa) > min(b, MAX=maxb) ;Only need intersection of ranges
 maxab = maxa < maxb

;If either set is empty, or their ranges don't intersect: 
;  result = NULL (which is denoted by integer = -1)
  !ERR = -1
  suba = -1
  subb = -1
  COUNT = 0L
  complementa = LINDGEN(na)
  complementb = LINDGEN(nb)
 if (maxab lt minab) or (maxab lt 0) then return
 
 ha = histogram([a], MIN=minab, MAX=maxab, reverse_indices=reva)
 hb = histogram([b], MIN=minab, MAX=maxab, reverse_indices=revb)
 
 r = where((ha ne 0) and (hb ne 0), count)
 if count gt 0 then begin
  suba = reva[reva[r]]
  subb = revb[revb[r]]
 endif 
 endelse 
 
 ; Establish complementary arrays of indices for a and b - i.e. where the 
 ; arrays do not match.
 arra=LINDGEN(na)
 IF suba[0] NE -1 THEN arra[suba]=-1
 complementa=WHERE(arra NE -1)
 arrb=LINDGEN(nb)
 IF subb[0] NE -1 THEN arrb[subb]=-1
 complementb=WHERE(arrb NE -1)
 
 return
 
 end