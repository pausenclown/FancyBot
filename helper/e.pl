$s = '';
while ( $line = <DATA>)
{
	if ( $line =~ /^(I\.S\.|CLAN|MIX)$/ )
	{
		$s =~ s/\n+/;/msg; $s =~ s/\?//msg;
		
		if ( $s )
		{
			my ($Kind, $Tech, $Name, $Weight, $Damage, $DamagePerSecond, $Heat, $HeatPerSecond, $Ammo, $Range, $Reload, $Slots) = ('energy', grep { $_ }  map { s/^ +$//; $_ }  split /;/, $s);
			print "<Gun><Kind>$Kind</Kind><Tech>$Tech</Tech><Name>$Name</Name><Weight>$Weight</Weight><Damage>$Damage</Damage><Range>$Range</Range><DamagePerSecond>$DamagePerSecond</DamagePerSecond><Heat>$Heat</Heat><HeatPerSecond>$HeatPerSecond</HeatPerSecond><Ammo>$Ammo</Ammo><Reload>$Reload</Reload><Slots>$Slots</Slots></Gun>\n";
			$s = '';
		}
		
	}
	
	$s .= $line;
}
__DATA__	
I.S.

 

L Laser

5

7.5

1.5

5

1

600

5

2

I.S.

 

M Laser

1

1.2

0.4

0.6

0.2

300

3

1

I.S.

 

S Laser

0.5

0.3

0.3

0.1

0.1

200

1

1

CLAN

 

ER L Laser

4

8

1.66

8

1.66

800

5

2

CLAN

 

ER M Laser

1

1.5

0.5

1.2

0.4

400

3

1

CLAN

 

ER S Laser

0.5

0.35

0.35

0.2

0.2

200

1

1

I.S.

 

L Pulse

7

2.62

2.096

1.75

1.4

600

1.25

2

I.S.

 

M Pulse

2

0.6

0.8

0.3

0.4

300

0.75

1

I.S.

 

S Pulse

1

0.15

0.6

0.05

0.2

150

0.25

1

I.S.



L X-Pulse

5

7

3.11

7

3.11

700

2.25

2

I.S.



M X-Pulse

3

2.75

2.2

2

1.6

400

1.25

1

I.S.



S X-Pulse

1.5

0.8

1.33

0.25

0.416

200

0.6

1

CLAN

 

ER L Pulse

6

3

2.4

3

2.4

800

1.25

2

CLAN

 

ER M Pulse

2

0.75

1

0.6

0.8

400

0.75

1

CLAN

 

ER S Pulse

1.5

0.27

1.08

0.12

0.48

200

0.25

1

I.S.

 

PPC

7

10

1.66

10

1.66

750

6

3

CLAN

 

ER PPC

6

14

1.75

15

1.875

900

8

3

I.S.

 

Flamer

1

1

0.25

4

1

150

4

2

CLAN

 

Flamer

0.5

1

0.25

4

1

150

4

2

I.S.

 

Bombast Laser

7

10

2.5

8

2

500

4

2



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

RANGE
/ METERS

RECYCLE

SLOTS


I.S.



Assault Laser

5

20

3.33

18

3

200

6

3

I.S.



L Beam Laser

5

1

1?

1

1?

750

0

2

I.S.

 

L Laser

5

7.5

1.5

6

1.2

650

5

2

I.S.

 

M Laser

1

2

0.66

1.5

0.5

300

3

1

I.S.



M Laser

1

2.5

0.833

1.75

0.583

300

3

1

I.S.

 

S Laser

0.5

1.25

0.625

0.85

0.425

150

2

1

I.S.



S Laser

1

1.75

0.833

1

0.5

150

2

1

CLAN

 

ER L Laser

4

7.5

1.5

9

1.8

800

5

2

CLAN

 

ER M Laser

1

2.45

0.816

2.5

0.833

400

3

1

CLAN



ER M Laser

1

3

1

3

1

400

3

1

CLAN

 

ER S Laser

0.5

1.6

0.8

1.15

0.575

200

2

1

CLAN



ER S Laser

0.5

2

1

2

1

200

2

1

CLAN



Hvy. L Laser

4

15

3

18

3.6

450

5

3

CLAN



Hvy. L Laser

4

16

3.2

15

3

500

5

3

CLAN



Hvy. M Laser

1

6

1.5

6

1.5

300

4

2

CLAN



Hvy. S Laser

0.5

2.5

0.833

2.0

0.66

150

3

1

I.S.

 

L Pulse

7

4

5.33

4

5.33

650

0.75

2

I.S.



L Pulse

7

4.5

6

4.5

6

650

0.75

2

I.S.

 

M Pulse

2

1.25

2.5

1.13

2.26

300

0.5

1

I.S.



M Pulse

2

1.5

3

1.25

2.5

300

0.5

1

I.S.

 

S Pulse

1

0.5

2

0.4

1.6

150

0.25

1

I.S.



S Pulse

1

0.7

2.8

0.5

2

150

0.25

1

I.S.

 

L X-Pulse

5

5.75

3.833

6.33

4.22

700

1.5

2

I.S.

 

M X-Pulse

2.5

2.5

2.5

2.5

2.5

400

1

1

I.S.



M X-Pulse

2.5

2.75

2.75

2.75

2.75

400

1

1

I.S.

 

S X-Pulse

1.5

1.25

2.5

1.33

2.66

200

0.5

1

I.S.



S X-Pulse

1.5

1.5

3

1.25

2.5

200

0.5

1

CLAN

 

ER L Pulse

6

4.5

6

5.4

7.2

800

0.75

2

CLAN

 

ER M Pulse

2

1.5

3

1.65

3.3

400

0.5

1

CLAN



ER M Pulse

2

1.75

3.5

1.75

3.5

400

0.5

1

CLAN

 

ER S Pulse

1

0.6

2.4

0.60

2.4

200

0.25

1

CLAN



ER S Pulse

1

0.75

3

0.6

2.4

200

0.25

1

I.S.

 

PPC

7

12

2

11

1.833

850

6

3

I.S.



CAP-PPC

8

18

2.25

16.50

2.0625

850

8

4

CLAN

 

ER PPC

6

14

1.75

16

2

925

8

3

CLAN



ER PPC

6

14

1.75

15

1.875

925

8

3

CLAN



Linked CAP-PPC

8

10

3

9.5

2.85

925

3.33

4

CLAN



Plasma Cannon

10

30

3.75

28

3.5

600

8

4

I.S.

 

Flamer

1

1

0.25

4

1

150

4

2

CLAN

 

Flamer

0.5

1

0.25

4

1

150

4

2

I.S.



Coolant Pod

2

0

0

-10

-0.5

0

20

1

CLAN



Coolant Pod

4

0

0

-30

-1.5

0

20

2

MIX



Targeting Laser

1

0

0

0.2?

0.2?

1000

0

1

