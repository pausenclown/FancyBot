$s = '';
while ( $line = <DATA>)
{
	if ( $line =~ /^(IS|CL)$/ )
	{
		$s =~ s/\n+/;/msg; $s =~ s/\?//msg;
		
		if ( $s )
		{
			my ($Kind, $Tech, $Name, $Weight, $Speed, $ArmorPoints, $Acceleration, $Decceleration, $TurnRate,
			$TwistRange, $TwistSpeed, $Ecm, $Bap, $Iff, $Opt, $Ams, $Lams, $Lamp, $Jets, $Gyro, 
			$ESlot, $BSlot, $MSlot, $OSlot, $DSlot, $HSlot, $ASlot) = ('energy', grep { $_ }  map { s/^ +$//; $_ }  split /;/, $s);
			print "<Mech><Tech>$Tech</Tech><Name>$Name</Name><Weight>$Weight</Weight><Speed>$Speed</Speed><ArmorPoints>$ArmorPoints</ArmorPoints>",
			      "<Acceleration>$Acceleration</Acceleration><Decceleration>$Decceleration</Decceleration><TurnRate>$TurnRate</TurnRate><TwistRange>$TwistRange</TwistRange>",
				  "<TwistSpeed>$TwistSpeed</TwistSpeed>",
				  "<electronics><ecm>$Ecm</ecm><bap>$Bap</bap><iff>$Iff</iff><optics>$Opt</optics><ams>$Ams</ams><lams>$Lams</lams><lamp>$Lamp</lamp><jets>$Jets</jets><gyro>$Gyro</gyro></electronics>",
				  "<Slots><Energy>$ESlot</Energy><Ballistic>$BSlot</Ballistic><Missile>$MSlot</Missile><Omni>$OSlot</Omni><DirectFire>$DSlot</DirectFire><HeatProducing>$HSlot</HeatProducing><AmmoDependant>$ASlot</AmmoDependant></Slots></Mech>\n";
			$s = '';
		}
		
	}
	
	$s .= $line;
}
__DATA__	
IS



ANNIHILATOR

100

18.7

810

4.38

5.56

40

360

40

N

N

N

N

Y

Y

N

N

N

4

16

IS



ATLAS

100

22.5

840

4.38

6.56

40

80

50

Y

Y

Y

N

Y

Y

N

N

Y

11

6

6

IS



AWESOME

80

26.39

483

7.41

11.11

50

80

60

Y

N

N

N

Y

Y

N

N

Y

10

4

3

IS



BATTLEMASTER

85

27.11

576

5

7

50

135

60

N

N

N

N

Y

Y

N

N

Y

8

4

3

4

CL



BATTLEMASTER2C

85

27.11

531

5

7

50

135

60

N

N

N

N

N

Y

N

N

Y

8

4

3

4

CL



BEHEMOTH

100

21.11

870

2

2.5

40

80

30

N

N

N

Y

N

Y

Y

Y

N

13

6

2

CL



BEHEMOTH2

100

21.11

870

2

2.5

40

80

30

N

Y

N

Y

N

Y

Y

Y

N

10

7

2

CL



BLOODASP

90

25

633

6

8

55

360

45

Y

Y

N

N

N

Y

N

N

N

8

6

2

4

CL



CANIS

80

26

567

6.41

10.61

50

105

55

N

N

N

Y

N

Y

Y

Y

N

10

6

IS



CYCLOPS

90

25

579

5.75

8.63

45

80

50

Y

Y

Y

N

Y

Y

N

N

Y

5

7

5

CL



DAISHI

100

21.11

790

4.06

6.09

40

80

50

N

N

N

N

N

Y

N

N

Y

6

6

2

8

CL



DEIMOS

85

27.11

618

7

9.46

50

100

50

N

Y

N

Y

N

Y

N

N

N

6

6

6

4

IS



FAFNIR

100

21.28

870

3

5

35

80

50

Y

N

N

N

Y

Y

N

N

Y

14

8

CL



GARGOYLE

80

28

513

11.81

17.71

50

135

70

Y

N

N

N

N

Y

N

N

Y

4

4

2

6

CL



GLADIATOR

95

23.5

666

5

7.5

50

90

50

Y

N

N

N

N

N

Y

Y

N

8

3

4

3

CL



HAUPTMANN

95

22.11

706

4.06

6.09

50

80

50

N

N

N

N

N

Y

N

N

Y

5

5

3

6

IS



HIGHLANDER

90

24.17

525

6.41

9.11

50

120

60

Y

N

Y

N

Y

Y

Y

Y

N

6

5

2

4

CL



KODIAK

100

25.44

750

5.75

8.27

50

80

50

Y

N

N

N

Y

Y

Y

Y

N

8

4

10

3

IS



LONGBOW

85

26.83

507

4.75

8.63

50

80

50

N

Y

N

N

Y

Y

N

N

N

4

14

CL



MADCAT_MKII

90

25.83

615

5.6

8.39

45

80

50

N

Y

N

N

N

Y

Y

Y

N

2

2

6

4

6

IS



MARAUDER2

100

25.67

864

4.5

7

50

80

40

N

Y

Y

N

Y

Y

Y

Y

Y

12

7

4

CL



MASAKARI

85

27.39

507

5

8

55

80

50

N

Y

N

Y

N

Y

N

N

Y

6

2

5

6

IS



MAULER

90

25

633

5.75

8.63

50

80

50

N

Y

N

N

Y

Y

N

N

Y

6

6

6

IS



STALKER

85

27.39

600

6.06

8.09

40

100

50

Y

N

N

N

Y

Y

N

N

Y

8

4

6

4

IS



SUNDER

90

25

525

5.75

8.63

40

120

50

Y

N

N

N

Y

Y

N

N

N

10

3

4

CL



SUPERNOVA

90

22.5

609

4.06

6.09

40

80

50

N

N

N

Y

N

Y

Y

Y

N

16

IS



TALOS

80

25.67

567

5.75

8.27

50

120

50

Y

N

N

N

Y

Y

Y

Y

Y

10

4

4

IS



TEMPLAR

85

27.11

501

9.41

15.11

50

100

60

Y

N

N

N

Y

Y

Y

Y

Y

4

4

2

6

IS



THUG

80

26.39

483

7.41

11.11

50

80

60

N

Y

Y

N

Y

Y

N

N

N

8

6

IS



VICTOR

80

26.56

483

8.41

13.61

50

100

50

Y

N

N

N

Y

Y

Y

Y

Y

7

7

4

IS



WARLORD

100

22.5

840

4.38

6.56

40

80

50

N

N

N

N

Y

N

Y

Y

N

9

6

8

CL



WARTHOG

95

27.11

706

4.5

7

50

80

50

Y

N

N

Y

N

Y

N

N

Y

10

6

4

IS



ZEUS

80

26

483

7.41

11.11

50

80

50

N

Y

N

N

Y

Y

N

N

Y

9

4

4

	


BRIGAND

25

34.72

204

26.04

39.06

75

120

80

Y

N

N

N

N

N

Y

Y

Y

6

2

CL



CLANINFANTRYB

1

8.89

21

16.78

20.67

171.9

90

150

Y

Y

N

Y

N

N

Y

Y

Y

5

6

CL



CLANINFANTRYE

1

8.89

21

16.78

20.67

171.9

90

150

Y

Y

N

Y

N

N

Y

Y

Y

11

CL



CLANINFANTRYM

1

8.89

21

16.78

20.67

171.9

90

150

Y

Y

N

Y

N

N

Y

Y

Y

5

6

IS



COMMANDO

25

37.5

180

35

45

120

140

70

N

N

Y

N

Y

Y

Y

Y

Y

1

4

4

CL



COUGAR

35

36.67

213

19.26

28.89

130

140

80

N

Y

N

Y

N

Y

Y

Y

Y

2

4

4

CL



DASHER

20

47

180

40

50

140

140

80

Y

Y

N

N

N

Y

N

N

Y

2

2

2

IS



DUANGUNG

25

34.72

204

26.04

39.06

75

120

80

N

N

N

N

N

N

Y

Y

Y

6

2

CL



ELEMENTAL

2

20

45

16.78

20.67

75

90

95

Y

N

N

Y

N

N

Y

Y

Y

7

7

10

5

IS



FLEA

20

42.11

165

45

55

120

140

80

Y

N

N

N

Y

Y

N

N

N

2

2

2

CL



GNOME

3

16

60

9.78

13.67

75

90

75

Y

N

N

Y

N

N

Y

Y

Y

11

11

14

CL



GOLEM

4

15

90

8

12

75

90

55

Y

N

N

Y

N

Y

N

N

Y

14

25

10

IS



GRAYDEATH

2

20

27

12.78

16.67

75

90

80

Y

Y

Y

N

N

N

N

N

Y

7

5

7

5

IS



INFILTRATOR

2

20

45

11.78

15.67

75

360

85

Y

Y

Y

N

N

N

N

N

Y

6

7

6

IS



ISINFANTRYB

1

8.89

21

16.78

20.67

171.9

90

150

Y

Y

Y

N

N

N

Y

Y

Y

11

IS



ISINFANTRYE

1

8.89

21

16.78

20.67

171.9

90

150

Y

Y

Y

N

N

N

Y

Y

Y

6

5

IS



ISINFANTRYM

1

8.89

21

16.78

20.67

171.9

90

150

Y

Y

Y

N

N

N

Y

Y

Y

5

6

CL



JENNER2C

35

40

243

15.74

23.61

75

140

70

Y

N

N

Y

N

Y

Y

Y

N

4

7

IS



KANAZUCHI

4

15

90

7.78

11.67

75

90

60

Y

N

Y

N

N

Y

N

N

Y

22

12

20

IS



KOTO

25

45

177

35

45

120

15

40

Y

N

N

N

Y

Y

N

N

Y

7

2

CL



LOCUST2C

25

45

177

35

45

120

15

40

Y

N

N

N

N

Y

N

N

Y

5

4

IS



LONGINUS

2

20

45

11.78

15.67

75

90

85

Y

N

Y

N

N

N

Y

Y

Y

7

7

10

IS



OSIRIS

30

43

201

34.72

52.08

140

90

70

N

N

Y

N

Y

Y

Y

Y

Y

5

1

2

IS



OWENS

35

36

213

29.86

44.79

140

90

80

Y

Y

Y

N

Y

Y

N

N

Y

2

6

2

IS



PANTHER

35

34.72

228

29.86

44.79

125

120

70

Y

N

Y

N

N

N

Y

Y

Y

4

2

2

1

CL



PUMA

35

30

213

19.26

28.89

75

90

60

N

N

N

N

N

Y

N

N

Y

2

1

6

IS



RAVEN

35

34.72

213

29.86

44.79

125

360

80

Y

Y

Y

N

Y

Y

N

N

Y

4

3

IS



RAZORBACK

30

33

231

26.04

39.06

75

120

80

Y

N

Y

N

Y

Y

N

N

N

5

4

2

CL



SALAMANDER

2

20

45

8.78

12.67

75

90

95

Y

N

N

Y

N

N

Y

Y

Y

14

14

6

CL



SOLITAIRE

25

43

192

40

50

140

130

70

N

Y

N

Y

N

N

N

N

N

9

IS



STANDARD

2

20

36

12.78

16.67

75

90

80

Y

N

Y

N

N

N

Y

Y

Y

7

5

11

CL



ULLER

30

40.28

201

45

55

140

140

80

Y

N

N

N

N

Y

N

N

Y

1

2

3

2

IS



URBANMECH

30

21.67

210

9.26

13.89

60

360

70

Y

N

Y

N

Y

Y

Y

Y

N

4

5

CL



URBANMECH_IIC

30

21.67

210

8.96

13.94

60

360

80

Y

N

N

Y

N

Y

Y

Y

N

6

4

IS



WASP

20

40

165

35

45

120

140

70

Y

N

Y

N

N

N

Y

Y

N

2

1

2

2

IS



WOLFHOUND

35

34.72

228

29.86

44.79

125

120

70

Y

N

Y

N

N

N

N

N

N

9

IS



ARCHER

70

29.17

420

9.41

13.11

55

120

55

Y

Y

N

N

Y

Y

N

N

N

4

10

2

CL



ARES

60

32.78

378

15.74

23.61

75

140

70

N

Y

N

Y

N

Y

Y

Y

N

6

4

3

2

IS



ARGUS

60

26.94

372

11.81

17.71

75

120

70

N

N

N

N

N

N

N

N

N

5

3

4

IS



ARGUSXT

65

26.94

390

11.81

17.71

75

120

70

N

N

Y

N

Y

Y

N

N

N

2

6

4

IS



AVATAR

70

30

475

9.41

13.11

60

120

70

N

Y

N

N

Y

Y

Y

Y

Y

5

3

4

3

1

CL



BLACKHEART

70

29

501

12

18

55

140

70

Y

N

Y

N

N

Y

N

N

Y

2

6

6

IS



BLACKKNIGHT

75

29.17

492

7.41

11.11

50

120

90

Y

Y

N

N

N

N

Y

Y

N

9

2

6

CL



BOWMAN

70

26.94

510

11.81

17.71

55

135

45

Y

Y

N

Y

N

Y

N

N

N

2

2

8

5

IS



CATAPULT

65

28.89

306

9.22

13.83

55

100

60

N

Y

N

N

Y

Y

Y

Y

Y

8

8

IS



CATAPULTK2

65

28.89

390

9.22

13.83

55

100

60

N

Y

N

N

Y

Y

Y

Y

Y

10

6

CL



CAULDRONBORN

65

29.89

470

6.3

10.23

50

100

60

N

Y

N

Y

N

Y

N

N

Y

2

2

4

6

CL



DRAGON

60

32.94

390

12

18

75

140

70

Y

N

Y

N

N

Y

N

N

Y

5

3

2

4

CL



GRIZZLY

70

26.94

470

11.81

17.71

55

135

45

Y

N

N

N

N

Y

Y

Y

N

8

5

4

CL



LOKI

65

32.78

420

12.99

19.48

60

140

60

Y

Y

N

N

N

Y

N

N

N

3

2

2

6

1

CL



MADCAT

75

27.78

515

7.64

11.46

50

100

60

N

Y

N

Y

N

Y

N

N

N

4

6

4

4

IS



MARAUDER

75

26.4

529

6.3

10.23

50

100

60

N

Y

N

N

N

N

N

N

N

12

4

CL



NOVACAT

70

30

420

9.78

14.67

55

100

60

N

Y

N

N

N

N

N

N

Y

8

4

4

CL



ORIONIIC

75

30

542

6.41

10.61

55

135

45

N

Y

N

Y

N

Y

N

N

Y

8

4

4

3

CL



PITBULL

70

26.94

489

11.81

17.71

55

80

70

N

N

N

Y

N

Y

Y

Y

Y

8

8

IS



RIFLEMAN

60

29.44

411

11.81

17.71

50

360

165

Y

Y

Y

N

Y

Y

N

N

N

8

4

IS



TENCHI

65

32.78

450

14.74

20.61

75

140

70

Y

N

N

N

Y

N

Y

Y

N

4

6

3

IS



THANATOS

75

29.17

432

5.75

8.27

50

360

70

Y

N

Y

N

Y

Y

Y

Y

N

4

4

3

2

IS



THANATOSXT

75

29.17

432

5.75

8.27

50

360

70

Y

N

Y

N

Y

Y

N

N

N

6

6

2

CL



THOR

70

30.28

455

11.81

17.71

55

360

45

Y

N

N

Y

N

Y

Y

Y

N

2

2

2

7

CL



VULTURE

60

29.17

396

7.87

11.81

60

360

45

Y

N

N

Y

N

Y

N

N

N

6

8

2

CL



VULTURE2

75

27.78

512

7.64

11.46

50

360

45

Y

N

N

Y

N

Y

N

N

N

6

3

4

3

2

CL



VULTUREC

60

29.17

420

7.87

11.81

60

360

90

Y

N

N

Y

N

Y

N

N

N

4

2

3

IS



WARHAMMER

70

29.17

480

9.41

10.23

50

120

55

N

Y

Y

N

Y

Y

N

N

N

10

4

2

CL



WILDCAT

75

27.78

432

7.64

11.46

50

100

60

Y

N

N

N

N

Y

Y

Y

Y

10

6

IS



YEOMAN

60

26.83

357

4.75

8.63

50

140

50

N

Y

N

N

Y

Y

N

N

N

4

10

CL



ARCTICWOLF

40

35.28

291

26.04

39.06

110

120

60

N

Y

N

N

N

Y

N

N

Y

6

5

IS



ASSASSIN2

45

37.5

297

16.86

24.79

90

360

90

Y

N

Y

N

Y

Y

Y

Y

N

2

6

4

CL



BLACKHAWK

50

33.67

363

13.74

20.61

140

60

70

N

N

N

N

N

Y

Y

Y

N

6

4

2

IS



BLACKJACK2

50

29.17

363

7.41

11.11

75

360

70

N

N

Y

N

Y

Y

Y

Y

N

4

2

6

CL



BLACKLANNER

55

32.78

381

13.74

23.61

75

360

70

Y

Y

N

Y

N

Y

N

N

N

2

4

5

IS



BUSHWACKER

55

29.44

363

15.74

23.61

75

120

70

N

Y

Y

N

Y

Y

N

N

Y

2

5

5

IS



CENTURION

50

29.44

360

7.78

11.67

75

120

80

N

Y

N

N

Y

Y

N

N

N

3

3

4

IS



CHIMERA

40

32.5

243

18.43

27.64

115

120

70

N

N

N

N

Y

Y

Y

Y

Y

3

3

4

IS



CRAB

50

30

339

9.78

14.67

55

135

75

N

Y

Y

N

N

N

N

N

N

12

CL



FENRIS

45

34.72

321

16.86

24.79

125

120

70

N

Y

N

Y

N

Y

N

N

N

6

2

3

CL



GESU

45

37.5

321

26

40

140

360

90

N

Y

N

Y

N

Y

N

N

Y

4

4

4

IS



GRIMREAPER

55

32.78

348

10

14

75

140

70

Y

N

Y

N

Y

Y

Y

Y

N

6

4

4

CL



HELLHOUND

50

33.22

315

34.72

52.08

140

120

70

Y

N

N

N

N

Y

Y

Y

Y

2

2

2

4

IS



HELLSPAWN

45

32.78

312

17.59

26.39

90

120

70

Y

N

Y

N

Y

Y

Y

Y

N

1

1

5

4

IS



HOLLANDER

45

30

312

5.75

8.27

90

360

75

N

N

N

N

N

N

N

N

Y

6

4

2

IS



HUNCHBACK

50

33.22

347

7.78

11.67

75

120

80

Y

N

Y

N

Y

Y

N

N

N

4

6

2

2

CL



HUNCHBACK2C

50

26.94

351

7.78

11.67

75

120

80

N

N

N

N

N

N

Y

Y

N

6

6

IS



PRIVATEER

55

30

357

5.75

8.27

55

135

75

N

Y

Y

N

Y

Y

N

N

N

3

4

4

2

CL



RABIDCOYOTE

55

30

333

5.75

8.27

55

135

75

Y

N

N

N

N

Y

N

N

Y

4

4

4

CL



REAVER

40

34.72

255

16.86

24.79

125

120

70

N

Y

N

N

N

Y

Y

Y

N

8

CL



RYOKEN

55

29.44

333

15.74

23.61

75

140

90

N

Y

N

Y

N

N

Y

Y

N

4

4

4

CL



SHADOWCAT

45

32.5

273

17.96

26.94

105

120

70

N

Y

N

Y

N

Y

Y

Y

N

4

2

3

3

IS



SHADOWHAWK

55

32.78

363

17.59

26.39

75

140

70

Y

N

Y

N

Y

Y

Y

Y

N

7

3

2

IS



STRIDER

40

31.11

258

17.59

26.39

120

90

90

N

Y

Y

N

Y

Y

N

N

N

2

4

4

IS



TREBUCHET

50

33.22

347

7.78

11.67

75

120

80

N

N

N

N

N

N

Y

Y

N

6

5

CL



URSUS

50

33.22

391

19

25

75

120

80

Y

N

N

Y

N

Y

N

N

N

6

2

3

IS



UZIEL

50

31.39

337

7.78

11.67

80

120

70

N

Y

N

N

Y

Y

Y

Y

N

8

4

3

