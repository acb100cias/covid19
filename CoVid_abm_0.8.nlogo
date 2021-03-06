extensions[shell py csv nw array]

globals[
  dd ;mean desease duration
  trigger-pop; threshold of population for starting qurantine
  sr?; initialize social restriction
  max-Bed; maximum hosp capacity
  T
  D
  PT
]

turtles-own[
  age
  is-healthy?
  is-sick?
  ti ; time since exposure to sars-cov2
  tc
  ts ; time since symptoms show
  OB ;obese
  DB ;diabetic
  hypt ;hypertense
  is_symptomatic?
  symptoms-type; 0-> mild , 1-> moderate, 2-> severe,3->critical
  hosp? ;hospitalized
  responsivity ;how much the individual is responsive to security measures
]

breed[personas persona ]

;;;;;;SETUP;;;;;;;;;

to setup
  clear-all
  setup-globals
  setup-personas
  setup-patches
  reset-ticks
end

to setup-globals
  set dd 14
  set trigger-pop qt
  set sr? false
  set max-Bed mb
  set T 0
  set D 0
  set PT M * N
end

to setup-patches
   ask patches [let k count personas-here set pcolor cyan + 0.1 * k]
end

to setup-personas
  foreach range M
  [create-personas N [set xcor ((random M - (M - 1)) * 40 ) - random-poisson  random 20 set ycor ((random M - (M - 1)) * 40 ) - random-poisson  random 20]]
  ask personas[
    set shape "person"
    set color green
    set age random 100
    set tc precision (36 + random-float 3) 2
    set is-sick? false
    set is-healthy? true
    set is_symptomatic? false
    set ti 0
    set ts 0
    set hypt random 2
    set OB random 2
    set DB random 2
    set hosp? false
    set responsivity random-float 1
    ;create-links-with personas-on neighbors
    ;nw:set-context personas links
  ]
  ask up-to-n-of (0.1 * N) personas
  [
    set is-sick? true
    set is-healthy? false
    set ti ti + 1
    ifelse random 100 <= 8 [
    set is_symptomatic? true
    set color red
    set symptoms-type 0
    set ts ts + 1
  ]
    [
      set is_symptomatic? false
      set color pink
  ]
  ]
end

;;;;;;;;;;;;GO;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  ;if T > 365 [ask personas[set age age + 1] ask n-of (0.18 * N * M) personas [hatch 1]]
  ask personas [
    move
    if is-sick?[
      set ti ti + 1
      show_symptoms
      get_sick
      set tc tc + 1
      hosp
      muere
      clear-out
    ]
    if ti < dd [infect ]
    colorear-personas
   ]
  begin-quarantine
  end-quarantine
  ask patches [colorear-parche]
  set T T + 1
  set D PT - count personas
  set PT count personas

  tick
end

;;;;;;;;;;;;;;;TURTLES;;;;;;;;;;;;;;;;;;

to move
  ifelse hosp? [fd 0]
  [
  ifelse sr? [
    ifelse strategy = 1 [ifelse is-sick? and is_symptomatic? and responsivity >= information-effectiveness [ ][rt random 180 lt random 180 fd random-gamma 80 80]]
      [ifelse strategy = 2 [ask n-of (0.3 * ( count personas )) personas [if responsivity >= information-effectiveness [ fd 0]]][if strategy = 3 [ask n-of (0.8 * (count personas)) personas [if responsivity >= information-effectiveness [fd 0]] ]]]
  ]
  [rt random 180 lt random 180 fd random-gamma 80 80]
  ]
end

to colorear-personas
  ifelse is-healthy? [set color green][ ifelse is-sick? [ifelse is_symptomatic? [set color red][set color pink]][set color black]]
end

to infect

  let s count personas-on neighbors
  ask up-to-n-of 2.5  personas-on neighbors [if random 100 < 25 [set is-sick? true set is-healthy? false set ti ti + 1 ]]
  ;create-links-with personas-on neighbors
  ;nw:set-context personas links
end

to show_symptoms
  if ti >= random (13 + 1) [ifelse random 100 < 40 [set is_symptomatic? true set tc 38 + random-float 1 set symptoms-type 0 set ts  ts + 1][set is_symptomatic? false] ]
end

to get_sick
  if is_symptomatic? and ts > 3 and random 100 < 20 [set symptoms-type 1]
  if symptoms-type = 1 and (OB = 1 or hypt = 1 or DB = 1)[set symptoms-type 2]
  if symptoms-type = 2 and age > 45 [set symptoms-type 3]
  end

to hosp
  if is_symptomatic? and symptoms-type = 2 and tc > 3 [set hosp? true set color grey]
end

to begin-quarantine
  if quarantine and (count personas with [color = red] > trigger-pop )[set sr? true]
end

to end-quarantine
  if quarantine and (count personas with [color = black] > (count personas with [color = red] + count personas with [color = pink]) )[set sr? false]
end


to clear-out
  if ti >= dd and random 100 <= 40[set is-healthy? false set is-sick? false set ti 0 set hosp? false]
end

to muere
  if ((ti > 15 and random 100 <= 1) or (ts > 5 and symptoms-type = 3 and random 100 < 20)) [die]
  if (hosp? and ((count personas with [hosp? = true]) >  max-Bed) and random 100 < 20)[die]
end

;;;;;;;;;;;;;PATCHES;;;;;;;;;;;;;;;;;;;;

to colorear-parche
  ifelse epi-risk[ifelse any? personas-here with [is-sick? = true and is_symptomatic? = true][let g count personas-here with[is-sick? = true and is_symptomatic? = true] set pcolor 116 - g][let k count personas-here set pcolor pcolor + 0.1 * k]]
  [let k count personas-here set pcolor pcolor + 0.1 * k]
end


;;;;;;;;;;;;;;REPORTERS;;;;;;;;;;;

to-report infectados
  report ((count personas with [is-sick? = true]) / (count personas)) * 100
end
to-report suceptibles
  report ((count personas with [is-healthy? = true]) / (count personas)) * 100
end
to-report recuperados
  report ((count personas with [is-sick? = false and is-healthy? = false]) / (count personas)) * 100
end
to-report sintomaticos
  report ((count personas with [is-sick? = true and is_symptomatic? = true]) / (infectados / 100)) * 100
end
to-report asintomaticos
  report ((count personas with [is-sick? = true and is_symptomatic? = false]) / (infectados / 100)) * 100
end

to-report hospitalized
  report ((count personas with [hosp? = true])/(sintomaticos / 100 )) * 100
end

to-report mild-cases
  report (count personas with [symptoms-type = 0])
end
to-report moderate-cases
  report (count personas with [symptoms-type = 1])
end

to-report severe-cases
  report (count personas with [symptoms-type = 2])
end

to-report critical-cases
  report (count personas with [symptoms-type = 3])
end

;to-report spatial-hazard

 ; report ask patches[count personas-here with [is-sick? = true ]]

;end
;to-report mortalidad
;report ()
;end
to-report random-beta [ #alpha #beta ]
  let XX random-gamma #alpha 1
  let YY random-gamma #beta 1
  report XX / (XX + YY)
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
945
746
-1
-1
3.62
1
10
1
1
1
0
1
1
1
-100
100
-100
100
1
1
1
ticks
30.0

BUTTON
114
96
187
129
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
114
213
177
246
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
111
141
196
201
N
500.0
1
0
Number

PLOT
983
409
1600
792
Epidemic dynamics
días
% personas
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"recuperados" 1.0 0 -14070903 true "" "plot recuperados"
"susceptibles" 1.0 0 -11085214 true "" "plot suceptibles"
"infectados" 1.0 0 -2674135 true "" "plot infectados"

PLOT
1002
13
1631
312
Total population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot  count turtles"

SWITCH
49
332
185
365
quarantine
quarantine
1
1
-1000

CHOOSER
34
403
172
448
strategy
strategy
1 2 3
0

MONITOR
27
585
145
630
% de infectados
infectados
17
1
11

MONITOR
7
476
177
521
mean desease duration
dd
17
1
11

SLIDER
18
285
190
318
qt
qt
0
100
34.0
1
1
people
HORIZONTAL

PLOT
1669
442
2398
964
Asymptomatic
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"asintomáticos" 1.0 0 -8630108 true "" "plot count personas with [(is-sick? = true) and is_symptomatic? = false]"

PLOT
1653
28
2312
372
symptoms type
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"mild" 1.0 0 -1604481 true "" "plot ((count personas with [symptoms-type = 0]) / (count personas with [is_symptomatic? = true]))"
"moderate" 1.0 0 -2674135 true "" "plot ((count personas with [symptoms-type = 1]) / (count personas with [is_symptomatic? = true]))"
"severe" 1.0 0 -13628663 true "" "plot (count personas with [symptoms-type = 2]) / (count personas with [is_symptomatic? = true])"

PLOT
2412
430
3024
964
Symptomatic
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"sintomáticos" 1.0 0 -5298144 true "" "plot count personas with [(is-sick? = true) and is_symptomatic? = true]"

CHOOSER
30
35
168
80
M
M
1 2 3 4
3

MONITOR
19
694
128
739
poblacion total
count turtles
17
1
11

MONITOR
12
526
175
571
% infected hospitalized
hospitalized
17
1
11

SLIDER
30
367
202
400
mb
mb
0
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
57
639
114
684
NIL
D
17
1
11

SWITCH
26
773
129
806
Med
Med
0
1
-1000

SWITCH
140
774
253
807
Vaccine
Vaccine
0
1
-1000

PLOT
968
809
1645
1303
Tasa de mortalidad
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -14070903 true "" "plot D"

SLIDER
2
249
205
282
information-effectiveness
information-effectiveness
0
1
0.3
0.1
1
NIL
HORIZONTAL

SWITCH
44
814
153
847
epi-risk
epi-risk
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

CoVid19-abm is an agent based model for epidemic dynamics of covid19 desease in urban centers or megalopolis it aims to simulate transmission and desease dynamics  and also medicare dynamics.

## HOW IT WORKS

Agents represents people. There are four zones where these people 'lives' the size of each of  4*M populations is N

Individuals are in 1 of four classes: 

* Healthy-susceptible
* Infected-symtomatic
* Infected-asymptomatic
* Cured

The dynamics of the model are basedon local rules. A 8-neighborhood its used.

A healthy-susceptible person may be infected by an infected (symptomatic or asymptomatic) neighbor with some probability P.

An infected may show symptomatic desease only for a fraction of infected. Symptomatic individuals develop symptoms of four type:
* Mild
* moderate
* severe
* critical


There is a switch for studying theoutcome of a quarantine strategy:

* Strategy 1 consist on restricting movility only of symptomatic infected
* Strategy 2 consist on restricting movility of aproximate 30 % of people
* Strategy 3 consist on restricting movility of approximate 80 % of people



## HOW TO USE IT

Just choose a population size N, if running quarantine mode, choose an strategy.

## THINGS TO NOTICE

When running in qurantine mode there are two things to notice:

* Death by desease

* duration of outbreak


## THINGS TO TRY

It can be modified for include more than 4 patches of population. The rule of infection is local for first neighbors. But it can be changed for spreading the desease on second neighbors, this is not a CoVid19 behaviour but it may be useful for some other desease.

## EXTENSIONS

The movility algorithm althoug showing local features it's very limited. It can be a desired extension looking for network-based movility.



## RELATED MODELS

ABM_VPH



## CREDITS AND REFERENCES

Author: Augusto Cabrera-Becerril.

CoVid19_abm is licensed under the GNU General Public License v3.0
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Quarantine1" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <metric>count personas</metric>
    <metric>infectados * 100</metric>
    <metric>suceptibles * 100</metric>
    <metric>recuperados * 100</metric>
    <metric>sintomaticos * 100</metric>
    <metric>asintomaticos * 100</metric>
    <metric>hospitalized * 100</metric>
    <metric>D</metric>
    <steppedValueSet variable="qt" first="15" step="5" last="50"/>
    <enumeratedValueSet variable="N">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mb">
      <value value="50"/>
      <value value="70"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-effectiveness">
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Quarantine2" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <metric>count personas</metric>
    <metric>infectados * 100</metric>
    <metric>suceptibles * 100</metric>
    <metric>recuperados * 100</metric>
    <metric>sintomaticos * 100</metric>
    <metric>asintomaticos * 100</metric>
    <metric>hospitalized * 100</metric>
    <metric>D</metric>
    <steppedValueSet variable="qt" first="15" step="5" last="50"/>
    <enumeratedValueSet variable="N">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mb">
      <value value="50"/>
      <value value="70"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-effectiveness">
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Quarantine3" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <metric>count personas</metric>
    <metric>infectados * 100</metric>
    <metric>suceptibles * 100</metric>
    <metric>recuperados * 100</metric>
    <metric>sintomaticos * 100</metric>
    <metric>asintomaticos * 100</metric>
    <metric>hospitalized * 100</metric>
    <metric>D</metric>
    <steppedValueSet variable="qt" first="15" step="5" last="50"/>
    <enumeratedValueSet variable="N">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mb">
      <value value="50"/>
      <value value="70"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-effectiveness">
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NoQuarantine" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <metric>count personas</metric>
    <metric>infectados * 100</metric>
    <metric>suceptibles * 100</metric>
    <metric>recuperados * 100</metric>
    <metric>sintomaticos * 100</metric>
    <metric>asintomaticos * 100</metric>
    <metric>hospitalized * 100</metric>
    <metric>D</metric>
    <steppedValueSet variable="qt" first="15" step="5" last="50"/>
    <enumeratedValueSet variable="N">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mb">
      <value value="50"/>
      <value value="70"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-effectiveness">
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="prueba" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go
export-view word"prueba"word(behaviorspace-experiment-name)word"step"word(T)word"run"word(behaviorspace-run-number)".png"
nw:save-gml word"prueba"word(behaviorspace-experiment-name)word"step"word(T)word"run"word(behaviorspace-run-number)".gml"</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="qt">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-effectiveness">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="epi-risk">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Med">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vaccine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mb">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Quarantine1_NW" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go
export-view word(behaviorspace-experiment-name)word"step"word(T)word"run"word(behaviorspace-run-number)".png"
nw:save-gml word(behaviorspace-experiment-name)word"step"word(T)word"run"word(behaviorspace-run-number)".gml"</go>
    <timeLimit steps="365"/>
    <metric>count personas</metric>
    <metric>infectados * 100</metric>
    <metric>suceptibles * 100</metric>
    <metric>recuperados * 100</metric>
    <metric>sintomaticos * 100</metric>
    <metric>asintomaticos * 100</metric>
    <metric>hospitalized * 100</metric>
    <metric>D</metric>
    <steppedValueSet variable="qt" first="15" step="5" last="50"/>
    <enumeratedValueSet variable="N">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mb">
      <value value="50"/>
      <value value="70"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-effectiveness">
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Quarantine2_NW" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go
export-view word(behaviorspace-experiment-name)word"step"word(T)word"run"word(behaviorspace-run-number)".png"
nw:save-gml word(behaviorspace-experiment-name)word"step"word(T)word"run"word(behaviorspace-run-number)".gml"</go>
    <timeLimit steps="365"/>
    <metric>count personas</metric>
    <metric>infectados * 100</metric>
    <metric>suceptibles * 100</metric>
    <metric>recuperados * 100</metric>
    <metric>sintomaticos * 100</metric>
    <metric>asintomaticos * 100</metric>
    <metric>hospitalized * 100</metric>
    <metric>D</metric>
    <steppedValueSet variable="qt" first="15" step="5" last="50"/>
    <enumeratedValueSet variable="N">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mb">
      <value value="50"/>
      <value value="70"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-effectiveness">
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Quarantine3_NW" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go
export-view word(behaviorspace-experiment-name)word"step"word(T)word"run"word(behaviorspace-run-number)".png"
nw:save-gml word(behaviorspace-experiment-name)word"step"word(T)word"run"word(behaviorspace-run-number)".gml"</go>
    <timeLimit steps="365"/>
    <metric>count personas</metric>
    <metric>infectados * 100</metric>
    <metric>suceptibles * 100</metric>
    <metric>recuperados * 100</metric>
    <metric>sintomaticos * 100</metric>
    <metric>asintomaticos * 100</metric>
    <metric>hospitalized * 100</metric>
    <metric>D</metric>
    <steppedValueSet variable="qt" first="15" step="5" last="50"/>
    <enumeratedValueSet variable="N">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mb">
      <value value="50"/>
      <value value="70"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-effectiveness">
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NoQuarantine_NW" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go
export-view word(behaviorspace-experiment-name)word"step"word(T)word"run"word(behaviorspace-run-number)".png"
nw:save-gml word(behaviorspace-experiment-name)word"step"word(T)word"run"word(behaviorspace-run-number)".gml"</go>
    <timeLimit steps="365"/>
    <metric>count personas</metric>
    <metric>infectados * 100</metric>
    <metric>suceptibles * 100</metric>
    <metric>recuperados * 100</metric>
    <metric>sintomaticos * 100</metric>
    <metric>asintomaticos * 100</metric>
    <metric>hospitalized * 100</metric>
    <metric>D</metric>
    <steppedValueSet variable="qt" first="15" step="5" last="50"/>
    <enumeratedValueSet variable="N">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mb">
      <value value="50"/>
      <value value="70"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strategy">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-effectiveness">
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.8"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
