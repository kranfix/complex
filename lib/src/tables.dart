part of fastmath;

/// Sine, Cosine, Tangent tables are for 0, 1/8, 2/8, ... 13/8 = PI/2 approx.
const int sineTableLen = 14;

/// Sine table (high bits).
const sineTableA = <double>[
  0.0,
  0.1246747374534607,
  0.24740394949913025,
  0.366272509098053,
  0.4794255495071411,
  0.5850973129272461,
  0.6816387176513672,
  0.7675435543060303,
  0.8414709568023682,
  0.902267575263977,
  0.9489846229553223,
  0.9808930158615112,
  0.9974949359893799,
  0.9985313415527344,
];

/// Sine table (low bits).
const sineTableB = <double>[
  0.0,
  -4.068233003401932E-9,
  9.755392680573412E-9,
  1.9987994582857286E-8,
  -1.0902938113007961E-8,
  -3.9986783938944604E-8,
  4.23719669792332E-8,
  -5.207000323380292E-8,
  2.800552834259E-8,
  1.883511811213715E-8,
  -3.5997360512765566E-9,
  4.116164446561962E-8,
  5.0614674548127384E-8,
  -1.0129027912496858E-9,
];

/// Cosine table (high bits).
const cosineTableA = <double>[
  1.0,
  0.9921976327896118,
  0.9689123630523682,
  0.9305076599121094,
  0.8775825500488281,
  0.8109631538391113,
  0.7316888570785522,
  0.6409968137741089,
  0.5403022766113281,
  0.4311765432357788,
  0.3153223395347595,
  0.19454771280288696,
  0.07073719799518585,
  -0.05417713522911072,
];

/// Cosine table (low bits).
const cosineTableB = <double>[
  0.0,
  3.4439717236742845E-8,
  5.865827662008209E-8,
  -3.7999795083850525E-8,
  1.184154459111628E-8,
  -3.43338934259355E-8,
  1.1795268640216787E-8,
  4.438921624363781E-8,
  2.925681159240093E-8,
  -2.6437112632041807E-8,
  2.2860509143963117E-8,
  -4.813899778443457E-9,
  3.6725170580355583E-9,
  2.0217439756338078E-10,
];

/// Tangent table, used by atan() (high bits).
const tangentTableA = <double>[
  0.0,
  0.1256551444530487,
  0.25534194707870483,
  0.3936265707015991,
  0.5463024377822876,
  0.7214844226837158,
  0.9315965175628662,
  1.1974215507507324,
  1.5574076175689697,
  2.092571258544922,
  3.0095696449279785,
  5.041914939880371,
  14.101419448852539,
  -18.430862426757812,
];

/// Tangent table, used by atan() (low bits).
const tangentTableB = <double>[
  0.0,
  -7.877917738262007E-9,
  -2.5857668567479893E-8,
  5.2240336371356666E-9,
  5.206150291559893E-8,
  1.8307188599677033E-8,
  -5.7618793749770706E-8,
  7.848361555046424E-8,
  1.0708593250394448E-7,
  1.7827257129423813E-8,
  2.893485277253286E-8,
  3.1660099222737955E-7,
  4.983191803254889E-7,
  -3.356118100840571E-7,
];
