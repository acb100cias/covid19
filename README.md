### CoVid19


(computational model for covid19 desease)

CoVid19-ABM it's an implementation on NetLogo of an  Agent-based Model for transmission of coronavirus and desease dynamics in  nearby urban centers.
## WHAT IS IT?

CoVid19-abm is an agent based model for epidemic dynamics of covid19 desease in urban centers or megalopolis it aims to simulate transmission and desease dynamics  and also medicare dynamics.

## HOW IT WORKS

Agents represents people. There are four zones where these people 'lives' the size of each of 4 populations is N

Individuals are in 1 of four classes: 

* Healthy-susceptible
* Infected-symtomatic
* Infected-asymptomatic
* Cured

The dynamics of the model are basedon local rules. A 8-neighborhood its used.

A healthy-susceptible person may be infected by an infected (symptomatic or asymptomatic) neighbor with some probability P.

An infected may show symptomatic desease only for a fraction of infected.


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

