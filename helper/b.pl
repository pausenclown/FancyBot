$s = '';
while ( $line = <DATA>)
{
	if ( $line =~ /^(I\.S\.|CLAN)$/ )
	{
		$s =~ s/\n+/;/msg; $s =~ s/\?//msg;
		
		if ( $s )
		{
			my ($Kind, $Tech, $Name, $Weight, $Damage, $DamagePerSecond, $Heat, $HeatPerSecond, $Ammo, $Range, $Reload, $Slots) = ('ballistic', grep { $_ }  map { s/^ +$//; $_ }  split /;/, $s);
			print "<Gun><Kind>$Kind</Kind><Tech>$Tech</Tech><Name>$Name</Name><Weight>$Weight</Weight><Damage>$Damage</Damage><Range>$Range</Range><DamagePerSecond>$DamagePerSecond</DamagePerSecond><Heat>$Heat</Heat><HeatPerSecond>$HeatPerSecond</HeatPerSecond><Ammo>$Ammo</Ammo><Reload>$Reload</Reload><Slots>$Slots</Slots></Gun>\n";
			$s = '';
		}
		
	}
	
	$s .= $line;
}
__DATA__	
I.S.

 

AC 5

8

2

1.33

0.2

0.133

60

600

1.5

1

I.S.

 

AC 10

13

9

2.25

0.6

0.15

36

400

4

2

I.S.



AC 20

16

18

3

1.8

0.3

20

250

6

3

I.S.

 

LBX 10

12

14

3.5

1

0.25

36

450

4

2

I.S.

 

LBX 20

15

24

4

2

0.33

20

300

6

3

CLAN

 

LBX 10

10

14

3.5

1

0.25

36

450

4

2

CLAN

 

LBX 20

12

24

4

2

0.33

20

300

6

3

I.S.

 

Ultra AC 2

8

2

2

0.1

0.1

120

900

1

1

I.S.

 

Ultra AC 5

10

4

2.66

0.15

0.1

60

600

1.5

1

CLAN

 

Ultra AC 2

6

2

2

0.11

0.11

120

900

1

1

CLAN

 

Ultra AC 5

8

4

2.66

0.15

0.1

60

600

1.5

1

CLAN



Ultra AC 10

13

18

4.5

0.75

0.187

36

400

4

2

CLAN



Ultra AC 20

18

36

6

1.5

0.25

20

250

6

3

I.S.

 

Lt. Gauss

13

12

2

0.8

0.133

30

1200

6

2

I.S.

 

Gauss

16

17

2.125

1

0.125

24

800

8

3

I.S.



Heavy Gauss

18

27

3.375

2

0.25

16

600

8

4

CLAN

 

Gauss

13

17

2.125

1

0.125

24

800

8

3

I.S.

 

MG Array

2

0.2

0.66

0

0

600

150

0.3

1

CLAN

 

MG Array

2

0.3

0.9

0

0

600

200

0.3

1

I.S.

 

Long Tom

20

25

3.57

25

3.57

18

700

7

3

CLAN



Cluster Bomb

10

28

9.33

10

3.33

10

1200

3

3



Tech

XP

Name / TYPE

WT

Damage

Damage
/ SEC.

Heat

Heat
/ SEC.

Ammo
/ TON.

RANGE
/ METERS

Reload
/ SEC.

Slots


I.S.



LT. AC 2

5

2

1.33

0.15

0.1

200

900

1.5

1

I.S.



LT. AC 5

6

3.75

1.5

0.3

0.12

100

700

2.5

1

I.S.



LT. AC 5

6

5

1.66

0.3

0.1

100

600

3

1

I.S.

 

AC 5

8

3.75

2.14

0.2

0.11

100

750

1.75

1

I.S.



AC 5

8

5

2.22

0.45

0.2

100

800

2.25

1

I.S.

 

AC 10

13

9

3.46

0.6

0.23

36

600

2.60

2

I.S.



AC 10

12

10

3.636

0.9

0.327

36

600

2.75

2

I.S.

 

AC 20

15

18

4

1.8

0.4

20

400

4.5

3

I.S.



AC 20

15

20

4.44

1.8

0.4

20

400

4.5

3

I.S.



HV-AC 2

9

3

1.5

0.3

0.15

120

1200

2

1

I.S.



HV-AC 2

8

3

2

0.3

0.2

120

1200

1.5

1

I.S.



HV-AC 5

12

6

2

0.6

0.3

60

1000

3

2

I.S.



HV-AC 5

10

6

2.4

0.6

0.24

60

1000

2.5

2

I.S.



HV-AC 10

15

12

3

1.2

0.3

30

800

4

3

I.S.



HV-AC 10

14

12

3.428

1.2

0.342

30

800

3.5

3

I.S.



HV-AC 20

17

24

4.36

2.4

0.436

15

550

5.5

4

I.S.



HV-AC 20

17

24

4.363

2.4

0.436

15

550

5.5

4

I.S.



LBX AC 5

8

7

2.33

0.5

0.166

72

700

3

1

I.S.

 

LBX AC 10

12

14

3.5

1

0.25

36

450

4

2

I.S.

 

LBX AC 20

15

28

4.66

2

0.33

20

350

6

3

CLAN



LBX AC 5

7

7

2.33

0.5

0.166

72

700

3

1

CLAN

 

LBX AC 10

10

14

3.5

1

0.25

36

450

4

2

CLAN

 

LBX AC 20

12

28

4.67

2

0.33

20

350

6

3

I.S.

 

Rotary AC 2

8

1.85

7.4

0.15

0.6

120

900

0.25

2

I.S.

 

Rotary AC 5

10

2.35

7.83

0.2

0.667

100

550

0.3

2

I.S.



Rotary AC 5

10

2.5

8.33

0.25

0.833

100

550

0.3

2

I.S.

 

Ultra AC 2

8

2.5

2.5

0.1

0.1

120

1000

1

1

I.S.



Ultra AC 2

8

2.5

2.5

0.1

0.1

240

1000

1

1

I.S.

 

Ultra AC 5

10

4.5

3.0

0.15

0.1

60

700

1.5

1

I.S.



Ultra AC 5

10

5

3.33

0.15

0.1

120

700

1.5

1

I.S.

 

Ultra AC 10

15

18

4.5

0.75

0.187

36

500

4

2

I.S.



Ultra AC 10

14

18

4.5

0.75

0.187

36

500

4

2

I.S.

 

Ultra AC 20

20

36

6

1.5

0.25

20

350

6

3

I.S.



Ultra AC 20

18

36

6

1.5

0.25

20

350

6

3

CLAN

 

Ultra AC 2

6

2.5

2.5

0.1

0.1

120

1000

1

1

CLAN



Ultra AC 2

6

2.5

2.5

0.11

0.11

240

1000

1

1

CLAN

 

Ultra AC 5

8

4.5

3.0

0.15

0.1

60

700

1.5

1

CLAN



Ultra AC 5

8

5

3.33

0.15

0.1

120

700

1.5

1

CLAN

 

Ultra AC 10

13

18

4.5

0.75

0.187

36

500

4

2

CLAN



Ultra AC 10

12

18

4.5

0.75

0.187

36

500

4

2

CLAN

 

Ultra AC 20

18

36

6

1.5

0.25

20

350

6

3

CLAN



Ultra AC 20

17

36

6

1.5

0.25

20

350

6

3

I.S.



Mini Gauss

9

8

1.33

0.5

0.083

30

950

6

1

I.S.

 

Lt. Gauss

13

12

2

0.8

0.133

30

1200

6

2

I.S.

 

Gauss

16

17

2.428

1

0.142

24

800

7

3

I.S.



Gauss

16

18

2.57

1

0.142

24

800

7

3

I.S.

 

Heavy Gauss

18

29

3.625

2

0.25

16

600

8

4

CLAN

 

Gauss

13

18

2.57

1

0.142

24

800

7

3

I.S.

 

MG Array

2

0.4

1.33

0

0

900

250

0.3

1

I.S.



MG Array

2

0.4

1.33

0

0

900

400

0.3

1

CLAN



Clan Heavy MG

3

1.2

3.6

0

0

300

200

0.3

2

CLAN



Clan Light MG

2

0.3

1.2

0

0

1800

600

0.25

1

CLAN

 

MG Array

2

0.45

1.5

0

0

1200

250

0.3

1

CLAN



MG Array

2

0.45

1.5

0

0

1200

400

0.3

1

I.S.

 

Long Tom

20

35

5

20

2.857

18

1200

7

3

I.S.



Long Tom

20

40

5.714

18

2.57

18

1200

7

3

I.S.



Long Tom Tracer

1.5

0

0

2

1

80

1200

2

1

I.S.



Long Tom Tracer

1.5

1

0.5

2

1

80

1200

2

1

MIX



Smoke - AGL?

2

0

0

6

0.4

2

2000

15

3

I.S.



AGL? Tracer

1.5

0

0

2

1

80

900

2

1

I.S.



AGL? Tracer

1.5

1

0.5

2

1

80

2000

2

1

MIX



INF? - AGL?

8

4-Heat

0.5-Heat

6

0.75

10

900

8

3

I.S.



INF? - AGL?

8

4-Heat

0.5-Heat

6

0.75

10

2000

8

3

I.S.



HEAP? - AGL?

15

10

4

9

3.6

25

900

2.5

3

MIX



HEAP? - AGL?

15

16

4

8

2

30

2000

4

3

