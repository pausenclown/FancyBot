$s = '';
while ( $line = <DATA>)
{
	if ( $line =~ /^(I\.S\.|CLAN|MIX)$/ )
	{
		$s =~ s/\n+/;/msg; $s =~ s/\?//msg;
		
		if ( $s )
		{
			my ($Kind, $Tech, $Name, $Weight, $Damage, $DamagePerSecond, $Heat, $HeatPerSecond, $Ammo, $Range, $Reload, $Slots) = ('missile', grep { $_ }  map { s/^ +$//; $_ }  split /;/, $s);
			print "<Gun><Kind>$Kind</Kind><Tech>$Tech</Tech><Name>$Name</Name><Weight>$Weight</Weight><Damage>$Damage</Damage><Range>$Range</Range><DamagePerSecond>$DamagePerSecond</DamagePerSecond><Heat>$Heat</Heat><HeatPerSecond>$HeatPerSecond</HeatPerSecond><Ammo>$Ammo</Ammo><Reload>$Reload</Reload><Slots>$Slots</Slots></Gun>\n";
			$s = '';
		}
		
	}
	
	$s .= $line;
}
__DATA__	
I.S.

 

LRM 5

3

4

0.66

1.2

0.2

240

1000

6

1

I.S.

 

LRM 10

6

8

1.33

2.4

0.4

240

1000

6

1

I.S.

 

LRM 15

8

12

2

3

0.5

240

1000

6

2

I.S.

 

LRM 20

11

16

2.66

3.6

0.6

240

1000

6

2

CLAN

 

LRM 5

2

4

0.66

1.2

0.2

240

1000

6

1

CLAN

 

LRM 10

3.5

8

1.33

2.4

0.4

240

1000

6

1

CLAN

 

LRM 15

4.5

12

2

3

0.5

240

1000

6

2

CLAN

 

LRM 20

6

16

2.66

3.6

0.6

240

1000

6

2

I.S.

 

MRM 10

5

8

1.6

2.4

0.48

240

400

5

1

I.S.

 

MRM 20

8

16

3.2

4.8

0.96

240

400

5

2

I.S.

 

MRM 30

11

24

4.8

6

1.2

240

400

5

2

I.S.

 

MRM 40

13

32

6.4

7.2

1.44

240

400

5

3

CLAN



S/MRM 10 ?

5

7

1

2.4

0.34

240

400

7

1

CLAN



S/MRM 20 ?

8

14

2

4.8

0.685

240

400

7

2

CLAN



S/MRM 30 ?

11

21

3

6

0.85

240

400

7

2

CLAN



S/MRM 40 ?

13

28

4

7.2

1.02

240

400

7

3

I.S.

 

SRM 2

2

2

1

0.4

0.2

120

250

2

1

I.S.

 

SRM 4

3

4

2

0.6

0.3

120

250

2

1

I.S.

 

SRM 6

4

6

3

0.8

0.4

120

250

2

2

CLAN

 

STREAK 2

2

2.4

0.8

0.6

0.2

120

250

3

1

CLAN

 

STREAK 4

3

4.8

1.6

0.9

0.3

120

250

3

1

CLAN

 

STREAK 6

4

7.2

2.4

1.2

0.4

120

250

3

2

I.S.

 

Thunderbolt

14

28

3.5

7

0.875

15

1000

8

3

? S/MRM: Streak Medium Range Missile.



TECH

XP

NAME / TYPE

WT

DAMAGE

DAMAGE
/ SEC.

HEAT

HEAT
/ SEC.

AMMO
/ TON.

RANGE
/ METERS

RELOAD
/ SEC.

SLOTS


I.S.



Hvy. Rocket Launcher

8

15

15

3

3

30

1200

1

3

I.S.



Rocket Launcher

1.5

4

12.12

0.8

0.808

10

500

0.33

2

I.S.



Rocket Launcher

1.5

4

8

1.5

3

20

500

0.5

2

CLAN



ATM 3 Med.?

2.5

6

1

1.2

0.2

144

650

6

1

CLAN



ATM 3 Ext.?

2.5

4.5

0.75

1.2

0.2

144

1200

6

1

CLAN



ATM 6 Med.?

4.5

12

2

2.4

0.4

144

650

6

1

CLAN



ATM 6 Ext.?

4.5

9

1.5

2.4

0.4

144

1200

6

1

CLAN



ATM 12 Med.?

8

24

4

3.6

0.6

144

650

6

2

CLAN



ATM 12 Ext.?

8

18

3

3.6

0.6

144

1200

6

2

I.S.

 

LRM 5

3

4

1

0.8

0.2

240

1000

4

1

I.S.



LRM 5

2.5

4

0.8

0.8

0.16

240

1000

5

1

I.S.

 

LRM 10

6

8

2

1.6

0.4

240

1000

4

1

I.S.



LRM 10

4.5

8

1.6

1.6

0.32

240

1000

5

1

I.S.

 

LRM 15

8

12

3

2

0.5

240

1000

4

2

I.S.



LRM 15

6

12

2.4

2

0.4

240

1000

5

2

I.S.

 

LRM 20

11

16

4

2.4

0.6

240

1000

4

2

I.S.



LRM 20

8

16

3.2

2.4

0.48

240

1000

5

2

CLAN

 

LRM 5

2

4

0.66

1.2

0.2

240

1000

6

1

CLAN

 

LRM 10

3.5

8

1.33

2.4

0.4

240

1000

6

1

CLAN

 

LRM 15

4.5

12

2

3

0.5

240

1000

6

2

CLAN

 

LRM 20

6

16

2.66

3.6

0.6

240

1000

6

2

I.S.

 

MRM 10

5

7

1.4

1.2

0.24

360

450

5

1

I.S.



MRM 10

4

7

1.4

1.2

0.24

360

450

5

1

I.S.

 

MRM 20

8

14

2.8

2.4

0.48

360

450

5

2

I.S.



MRM 20

7

14

2.8

2.4

0.48

360

450

5

2

I.S.

 

MRM 30

11

21

4.2

3

0.6

360

450

5

2

I.S.



MRM 30

10

21

4.2

3

0.6

360

450

5

2

I.S.

 

MRM 40

13

28

5.6

3.6

0.72

360

450

5

3

CLAN

 

S/MRM 10

5

7

1.166

1.6

0.266

360

450

6

1

CLAN



S/MRM 10

4

7

1.166

1.6

0.266

360

450

6

1

CLAN

 

S/MRM 20

8

14

2.33

3.2

0.533

360

450

6

2

CLAN



S/MRM 20

7

14

2.33

3.2

0.533

360

450

6

2

CLAN

 

S/MRM 30

11

21

3.5

4

0.66

360

450

6

2

CLAN



S/MRM 30

10

21

3.5

4

0.66

360

450

6

2

CLAN

 

S/MRM 40

13

28

4.66

4.8

0.8

360

450

6

3

I.S.



ISRM 2

2

2 ?

0.66 ?

0.8

0.266

60

250

3

2

I.S.

 

SRM 2

2

3

1.5

0.4

0.2

120

250

2

1

I.S.

 

SRM 4

3

6

3

0.6

0.3

120

250

2

1

I.S.

 

SRM 6

4

9

4.5

0.8

0.4

120

250

2

2

CLAN

 

Streak 2

2

3

1

0.6

0.2

120

250

3

1

CLAN

 

Streak 4

3

6

2

0.9

0.3

120

250

3

1

CLAN

 

Streak 6

4

9

3

1.2

0.4

120

250

3

2

I.S.

 

Cluster Missile

18

32

3.2

7

0.7

15

1200

10

3

I.S.

 

Thunderbolt

14

28

3.5

7

1.077

15

1200

6.5

3

I.S.



Thunderbolt

14

28

4.66

4

0.66

15

1200

6

3