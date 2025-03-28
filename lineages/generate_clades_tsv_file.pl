#!/usr/bin/env perl

# Generates clades.tsv file from defining mutations copy/pasted from an augur tree. Each
# clade should have the word CLADE followed by the name of the clade on one line, followed
# by the defining mutations copy/pasted from the augur tree on the next lines. Include all
# clades. Only includes nucleotide mutations in output clades.tsv file, and includes all
# nucleotide mutations in output clades.tsv file.

# Example input file:

# CLADE III
# nuc	unique	T12C, T176G, A333G, G618A, C638T, T640G, T725A, A749G, A840C, A842T, A857G, T863A, G921T, T922C, A989T, G1013A, G1055T, T1157A, T1178A, T1307A, A1328T, A1385T, A1388T, A1415G, G1442C, T1454A, T1499A, G1514T, T1587G, T1616A, C1637A, T1643C, A1676T, A1736T, T1751A, T1781A, A1905C, G1906A, T1934A, A1958T, T2000A, T2030C, G2037T, T2066A, G2081C, A2237C, G2250A, G2300T, T2435A, G2477T, A2513T, A2579T, T2642A, G2693T, C2697T, G2738T, A2765T, T2858A, G2891T, T3003A, T3020A, A3036G, A3053T, A3096C, G3100A, A3216C, A3305T, T3371A, C3393T, T3395A, T3410G, C3528T, T3557A, T3572A, G3654A, T3677A, T3680A, C3691G, C3789T, C3971A, A4031T, G4085C, A4087G, T4093A, A4115T, T4283A, A4296G, A4304T, T4314G, C4353T, A4418T, A4466C, T4517A, A4532T, A4680C, A4715T, C4775G, T4925A, A4974T, G4991T, T5006A, A5088C, T5126A, A5141G, T5210C, C5218G, A5279T, T5318G, G5366T, A5432G, T5513G, G5531T, T5546A, A5561G, A5648T, G5748A, A5780T, A5801G, A5888G, T6101A, A6186T, T6199C, T6236A, A6356T, T6359G, T6397C, A6437T, A6473G, G6504T, T6762A, C6763T, T6836A, A6956T, T7028G, T7033C, T7196C, T7199A, T7205A, T7259C, G7381A
# nuc	homoplasies	T112C, C180T, T546C, T573C, T723C, T746C, T779C, T899A, C930T, A950G, T953A, A964G, G971A, A1010G, T1067C, A1100G, T1229A, T1301A, C1319T, A1352T, T1376C, A1430T, G1439A, T1440C, T1739C, A1892G, T1907C, A1961T, A2006T, G2024A, C2057T, C2073T, A2153T, T2180C, A2204T, T2264A, T2267C, A2289G, T2298C, G2317A, G2324A, A2339T, A2369C, A2387G, A2423G, A2447T, T2489C, T2504A, T2519C, A2531T, A2537T, C2648T, A2690T, T2702A, T2705A, T2736C, C2780T, T2867C, T2889C, A3005C, G3062A, A3065T, A3086T, C3095T, C3134T, A3329G, C3485T, T3522C, A3536G, A3605G, C3639T, T3656A, A3692T, T3708C, G3764T, C3813T, T3824A, A3947T, T3999A, C4004A, A4165G, C4169T, C4184T, C4193T, G4250A, A4316T, G4322T, T4355A, T4376C, A4430G, A4451T, C4484T, G4505A, T4560C, A4598T, T4700C, T4745C, G4754A, T4763A, T4766C, G4784A, T4845C, A4893G, T4938C, T4989C, T4997A, C5078T, T5108C, A5168T, A5207G, A5348T, T5375C, T5573A, G5618A, T5646C, G5660T, T5690A, A5696T, A5711G, G5729A, G5762T, T5786A, G5820A, T5852A, A5873T, A5912G, C6064T, T6071C, A6080G, A6110G, T6113A, A6140G, C6160T, A6164T, T6167C, T6173C, A6185T, T6263C, C6296T, A6323G, C6348T, A6353G, T6384C, G6396A, A6494G, G6581T, G6878A, C6896T, A6897G, G6965A, T6990C, T6998C, T7013C, C7032T, G7043A, A7045G, A7064G, C7068T, T7088A, A7097G, C7166T, A7175G, G7235A, G7241A, T7295C, T7349C
# nuc	undeletions	-122A
# nuc	gaps	G20-, T204-
# HAVgp1	unique	V63S, S285A, D339E, S391H, A435S, E506K, M519V, R528Q, S757T, N768D, R789K, D941E, V974I, A986G, F1089I, M1117I, K1118R, F1120Y, K1127N, S1188G, S1194A, T1495S, V1672I, M1818L, L1822P, L1872F, V1888T, A1924S, S2010I, E2074D, L2100S, R2216K
# HAVgp1	homoplasies	K77R, K1144R, I1387V, D1397E, T1414S, V1696I, A1777V, A1809V, I2055V, K2104R
# HAVgp2	unique	V61S, S283A, D337E, S389H, A433S, E504K, M517V, R526Q, S755T, N766D, R787K, D939E, V972I, A984G, F1087I, M1115I, K1116R, F1118Y, K1125N, S1186G, S1192A, T1493S, V1670I, M1816L, L1820P, L1870F, V1886T, A1922S, S2008I, E2072D, L2098S, R2214K
# HAVgp2	homoplasies	K75R, K1142R, I1385V, D1395E, T1412S, V1694I, A1775V, A1807V, I2053V, K2102R
# 
# CLADE IIIA
# nuc	unique	T24C, G535A, T845C, T921C, T1055C, T1145C, A1172T, T1190G, T1274C, T1337C, A1394C, G1562T, A1598G, C1812T, A1814G, T1904C, T1925C, A1934G, T1964A, A2240T, A2366T, T2408C, T2477C, A2678T, A2696G, A2858G, T2924A, T3023A, T3065C, A3098T, A3140G, G3218T, A3281T, A3395G, T3455A, A3530G, A3563G, G3614A, A3680G, G3791A, A3809C, A3824G, T3899G, A3971G, G3986T, T4139G, A4146C, T4169A, A4178G, G4244A, T4316C, T4406C, T4418C, T4433C, A4436C, C4529A, A4682T, T4712A, T4715C, A4892T, G4903A, A5004T, T5078A, G5089A, A5199C, C5208T, A5564C, G5858A, G6191T, A6251G, G6357C, A6368G, T6446C, T6476A, A6524G, T6719A, G6740T, A6762G, T6903C, T6929C, G6935A, G6992T, C7133A, C7137T, G7139A, A7223G, A7299C, T7466C
# nuc	homoplasies	T171C, A177G, C375T, C566T, T604C, G818A, T869C, T917C, A959T, T1059C, G1076A, T1092C, A1142G, T1154A, T1184C, C1259T, T1298C, A1322G, T1325C, A1367T, T1371C, G1373A, T1391C, A1448G, T1457C, A1460G, T1523C, T1560C, T1565C, T1589C, T1697C, G1787A, T1826C, T1850C, G1865A, T1914C, G1919A, T1982C, C1991T, T2090C, T2108C, T2111C, C2144T, G2162A, C2189T, T2198C, T2231C, T2246A, C2279T, G2293A, A2308G, G2331A, A2336G, A2399G, G2405A, C2465T, A2585T, C2600T, T2603C, T2648A, C2657T, T2690C, T2741C, A2774G, A2810G, T2822C, T2825C, T2840C, T2843A, A2846G, G3143A, G3233A, C3255T, T3260C, G3269A, A3338C, A3359G, A3404G, A3413G, G3443A, T3449C, T3491C, T3497C, C3591T, T3603C, T3608C, A3617G, T3623C, A3626G, A3659G, A3686G, T3698C, A3699C, T3737A, T3758C, T3764C, T3776C, G3836A, C3839T, C3857T, T3867C, T3908C, C3920T, C3939T, G3989A, C3998T, T4022C, C4052T, T4076C, G4101C, C4112T, G4118A, C4137T, C4148T, A4157G, T4197C, A4199T, T4232C, G4235A, A4241G, T4274C, C4298T, G4301A, G4313A, C4343T, G4349A, C4382A, A4400G, T4409C, T4415C, T4446C, T4511A, C4568T, G4652A, G4673A, T4697C, T4730A, A4772G, T4781C, A4790G, T4802C, G4835A, G4871A, T4890C, T4907C, A4919G, A4928G, A5000G, G5048A, A5080G, T5087A, A5198G, G5201A, T5228G, G5258A, A5285G, A5360G, C5384T, G5408A, T5417C, T5429C, C5486T, T5498A, G5525A, T5588A, T5633C, T5657A, A5666G, T5693C, A5708G, C5714T, T5744C, T5747C, G5789A, T6108C, G6134T, G6146T, A6218G, G6308A, T6369C, T6413C, T6440C, A6449G, T6465C, T6518C, T6542C, T6713C, A6722G, A6758C, A6776G, T6788C, C6818T, A6923G, T7001C, G7130A, T7214A, A7244G, T7391C
# nuc	reversionsToRoot	G818A, G1076A, C1812T, G1865A, C1991T, G2405A, C2600T, C3857T, G3989A, C4298T, G4301A, C4568T, G4871A, G4903A, G5089A, G5201A, C5208T, C5384T, G5408A, C6818T, G7130A, C7137T
# nuc	undeletions	-120T
# HAVgp1	unique	S63P, V1123L, N1138H, S1390N, I1424L, R1452Q, K1489Q, P1492S, V1875L, I2010V, K2189Q
# HAVgp1	homoplasies	R520K, K525R, V533I, K1449R, E1804D
# HAVgp2	unique	S61P, V1121L, N1136H, S1388N, I1422L, R1450Q, K1487Q, P1490S, V1873L, I2008V, K2187Q
# HAVgp2	homoplasies	R518K, K523R, V531I, K1447R, E1802D
# 
# CLADE IIIB
# nuc	unique	A122G, C186T, A187G, T193C, T733A, T839C, T912G, G932A, A974T, T1232G, T1262A, A1307G, T1391A, A1403C, G1772T, T1775A, T1847C, T1877A, A1883G, T1988G, T2333G, A2399T, A2429T, T2513C, T2579C, G2726A, T2738C, A3033T, G3035A, A3083G, A3299G, T3462C, G3641A, T3645A, G3710T, G3724C, T4373C, A4643G, T4691A, A4709C, T4799A, T4922A, A5006G, A5144G, A5390T, A5411G, T5417A, A5654C, T5669A, T5717A, A5741C, T5825C, T5891C, G5903C, G5975A, T6125C, A6239C, C6311A, T6581C, T6593A, T6763A, T6785A, T6815C, T6863A, A6869T, A6941C, G6960A, G6962A, A7044C, A7046T, G7070A, T7085A, T7124G, A7163T, T7434C, T7468G
# nuc	homoplasies	A21T, T31C, C109T, A190G, T214C, G372A, T376C, G540A, T545A, C561T, T621C, C622T, A635G, C791T, G836T, C911T, A920G, C938T, C947T, G962A, G965A, A980G, G1061A, G1064A, G1073A, T1085C, T1091C, G1130A, G1163A, G1175A, A1193T, T1214C, T1224C, T1256C, A1277G, G1283A, T1292C, A1304G, T1313C, G1346A, T1361G, G1370A, T1388C, C1407T, G1409A, C1416T, T1433C, G1436A, G1451A, C1458T, T1517C, G1520A, A1532G, A1571G, T1574C, T1583C, T1619C, T1679C, A1682T, G1691A, G1694A, T1721C, A1730G, A1757G, A1763T, T1770C, T1838A, A1859G, T1860C, A1862G, C1890T, A1910T, T1925A, T1928C, A2015G, T2042C, A2048G, C2093T, G2099A, T2102C, T2120C, T2153C, T2156C, A2252G, T2282C, T2300C, A2309G, A2318G, T2330C, T2342C, G2354A, A2357T, T2411C, A2417G, T2444A, T2453C, A2498T, A2522G, T2543C, A2552T, T2564C, T2567A, C2586T, G2612A, G2621A, C2627T, T2628C, T2633C, G2636A, G2654A, A2705G, C2708T, A2714T, T2747C, T2783C, T2811C, T2828C, T2843C, C2850T, A2873T, A2930G, T3002C, C3038T, G3092A, T3113C, A3119G, G3125A, T3131C, A3137G, T3158C, G3161A, C3168T, G3182A, T3189C, A3206G, T3236C, A3287G, T3314C, T3324C, A3338G, A3344T, A3389T, G3470A, T3482C, A3500G, G3501A, T3515C, G3549T, A3554G, A3557G, A3575G, T3581C, C3590T, G3653A, A3662G, T3665C, T3716A, C3728T, A3731G, T3749C, A3767T, A3773G, T3782C, A3809G, T3866C, T3893C, T3902C, A3941G, G3983A, C3984T, T4019C, A4081G, G4103C, T4106C, A4154G, A4160T, A4166G, A4202G, A4217G, A4220G, A4259G, T4260C, A4286G, A4295T, T4322C, A4340G, G4364A, A4370T, G4379A, A4442G, A4481G, A4556G, A4562G, G4565A, T4571A, T4586C, G4604A, T4607C, T4626C, T4661C, G4676A, T4679C, T4733C, C4760A, T4769C, C4773T, A4796G, T4829C, T4844C, G4847A, T4868C, C4874T, T4889C, A4892G, T4895C, T4904C, T4910C, G4911A, T4913C, T4917C, G4940A, A4964G, C5018T, A5039G, T5051C, G5090A, T5105C, G5117A, A5165G, T5168C, C5180T, A5222G, G5246A, A5249T, C5265T, G5267A, T5276C, A5300G, A5321G, G5324A, T5333C, C5393T, G5396A, T5420C, A5441G, C5489T, T5516A, A5519G, T5523C, T5534G, T5537C, C5550T, A5558G, T5627C, A5636G, C5637T, G5651A, A5690G, T5696C, T5765C, G5813T, C5816T, C5837T, G5843A, T5861A, T5879C, G5897A, G6010A, A6041G, C6095A, G6104T, A6155G, G6188A, T6200C, A6203G, C6233T, T6278C, T6290A, A6299G, A6302G, A6305G, T6306C, A6317G, T6362C, T6374A, A6386G, A6416T, G6422A, T6456C, A6458G, C6470T, A6482G, T6503C, T6512A, T6548C, A6551T, T6569C, T6575C, T6617C, C6669T, G6704T, C6737A, T6761C, A6773G, C6779T, T6794C, T6797C, T6830C, A6836G, G6842T, T6866C, G6875A, A6890T, C6893T, T6902C, T6911C, T6938C, T6959C, A6980G, C7004A, T7031C, T7037C, A7063G, A7067G, C7094T, T7106C, C7110T, G7127A, G7142A, T7172C, T7181C, T7206C, A7208G, T7214C, A7301C, T7465A
# nuc	reversionsToRoot	C109T, T733A, G962A, G1064A, G1130A, G1163A, G1283A, C1407T, G1520A, G2099A, G2612A, C2708T, G2726A, C2850T, C3590T, G3983A, C3984T, G4379A, G4676A, T4799A, C4874T, G5117A, C5637T, C5816T, G5843A, G6010A, G6422A, T7085A, C7094T, G7142A
# nuc	undeletions	-99T, -120G, -125A, -482A
# nuc	gaps	A96-, T480-
# HAVgp1	unique	S60A, M767L, L971M, S997T, I1424M, I2010N, V2076I, E2143D, K2189N
# HAVgp1	homoplasies	V923I, A939S, K1116R, V1393I, R1759K, K2110R
# HAVgp1	reversionsToRoot	R1759K
# HAVgp2	unique	S58A, M765L, L969M, S995T, I1422M, I2008N, V2074I, E2141D, K2187N
# HAVgp2	homoplasies	V921I, A937S, K1114R, V1391I, R1757K, K2108R
# HAVgp2	reversionsToRoot	R1757K

# Usage:
# perl generate_clades_tsv_file.pl [file with copy/pasted defining mutations for each clade]

# Prints to console. To print to file, use
# perl generate_clades_tsv_file.pl [file with copy/pasted defining mutations for each clade]
# > [output clades.tsv file path]


use strict;
use warnings;


my $copy_pasted_defining_mutations = $ARGV[0];


my $NUCLEOTIDE_MUTATIONS_ONLY = 1;
my $GAPS_MUTATIONS_INCLUDED = 1;

my $NEWLINE = "\n";
my $DELIMITER = "\t";


# verifies that input file exists and is not empty
if(!$copy_pasted_defining_mutations or !-e $copy_pasted_defining_mutations
	or -z $copy_pasted_defining_mutations)
{
	print STDERR "Error: input file not provided, does not exist, or empty:\n\t"
		.$copy_pasted_defining_mutations."\nExiting.\n";
	die;
}


# prints header line
print "clade".$DELIMITER;
print "gene".$DELIMITER;
print "site".$DELIMITER;
print "alt".$NEWLINE;


# reads in copy/pasted clade-defining mutations and generates clades.tsv file
my $current_clade = "";
open DEFINING_MUTATIONS, "<$copy_pasted_defining_mutations" || die "Could not open $copy_pasted_defining_mutations to read; terminating =(\n";
while(<DEFINING_MUTATIONS>) # for each row in the file
{
	chomp;
	my $line = $_;
	
	# start of new clade
	if($line =~ /CLADE (.*)/)
	{
		$current_clade = $1;
		print $NEWLINE;
	}
	
	# list of defining nucleotide mutations
	# ex. nuc	unique	T12C, T176G, A333G, G618A, C638T, T640G, T725A, A749G, A840C, A842T, A857G, T863A, G921T, T922C, A989T, G1013A, G1055T, T1157A, T1178A, T1307A, A1328T, A1385T, A1388T, A1415G, G1442C, T1454A, T1499A, G1514T, T1587G, T1616A, C1637A, T1643C, A1676T, A1736T, T1751A, T1781A, A1905C, G1906A, T1934A, A1958T, T2000A, T2030C, G2037T, T2066A, G2081C, A2237C, G2250A, G2300T, T2435A, G2477T, A2513T, A2579T, T2642A, G2693T, C2697T, G2738T, A2765T, T2858A, G2891T, T3003A, T3020A, A3036G, A3053T, A3096C, G3100A, A3216C, A3305T, T3371A, C3393T, T3395A, T3410G, C3528T, T3557A, T3572A, G3654A, T3677A, T3680A, C3691G, C3789T, C3971A, A4031T, G4085C, A4087G, T4093A, A4115T, T4283A, A4296G, A4304T, T4314G, C4353T, A4418T, A4466C, T4517A, A4532T, A4680C, A4715T, C4775G, T4925A, A4974T, G4991T, T5006A, A5088C, T5126A, A5141G, T5210C, C5218G, A5279T, T5318G, G5366T, A5432G, T5513G, G5531T, T5546A, A5561G, A5648T, G5748A, A5780T, A5801G, A5888G, T6101A, A6186T, T6199C, T6236A, A6356T, T6359G, T6397C, A6437T, A6473G, G6504T, T6762A, C6763T, T6836A, A6956T, T7028G, T7033C, T7196C, T7199A, T7205A, T7259C, G7381A
	if($line =~ /(.*)\t.*\t(.*)/)
	{
		my $gene = $1;
		my $mutations_list_string = $2;
		my @mutations = split(", ", $mutations_list_string);
		foreach my $mutation(@mutations)
		{
			if($mutation =~ /^([\w-])(\d+)([\w-])$/)
			{
				my $base = $1;
				my $site = $2;
				my $alt = $3;
				
				# prints line for mutation
				if((!$NUCLEOTIDE_MUTATIONS_ONLY or $gene eq "nuc")
					and ($GAPS_MUTATIONS_INCLUDED or $base ne "-" and $alt ne "-"))
				{
					print $current_clade.$DELIMITER;
					print $gene.$DELIMITER;
					print $site.$DELIMITER;
					print $alt.$NEWLINE;
				}
			}
			else
			{
				print STDERR "Error: mutation ".$mutation." not recognized. Exiting.\n";
				die;
			}
		}
	}
}
close DEFINING_MUTATIONS;


# November 18, 2024
