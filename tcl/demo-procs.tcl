# demo-procs.tcl
ad_library {

    procedures for building demonstrations
    @creation-date 11 December 2013
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com
}

ad_proc -private hf_namelur { 
    {n "3"}
    {m "5"}
} {
    Returns N words up to M pseudo-syllables.
    Inspired by namelur GNU GPL v2 licensed, originally coded in C. 
    Code and following starwars configuration data retrieved from 
    https://sourceforge.net/projects/namelur/ on 3 June 2016
} {
    # from namelur/nar/starwars.nar # 
    # sw_names.txt converted by Namelur (C) legolas558
    set nar_file_list [list 
v382 a 4
v409 e 4
v170 i 4
v20 ae 4
v40 ee 4
v224 o 4
v327 a 1
v113 y 4
v94 y 1
v60 ye 4
v6 ea 4
v20 oo 4
v4 oi 4
v29 u 4
v4 yo 4
v11 ei 4
v34 ia 4
v4 eu 4
v15 ay 4
v5 yu 4
v1 oa 4
v3 eo 4
v8 yi 4
v2 ya 4
v6 oe 4
c82 p 4
c226 h 4
c72 f 1
c1083 r 4
c471 m 4
c465 k 4
c411 t 4
c646 l 4
c490 n 4
c224 t 1
c270 s 4
c74 kr 4
c154 s 1
c42 sr 4
c50 ht 4
c174 tr 4
c7 tl 4
c183 w 4
c23 ll 4
c7 ds 4
c92 h 1
c1 tg 4
c181 sh 4
c188 j 4
c73 hr 4
c151 n 1
c30 ms 4
c42 th 4
c193 d 4
c144 b 4
c148 g 4
c105 q 4
c26 ng 4
c71 sk 4
c42 rh 4
c3 ft 4
c70 ch 4
c60 l 1
c238 c 4
c4 rk 4
c3 dp 4
c2 fd 4
c14 fr 4
c4 kt 4
c32 dg 4
c47 f 4
c5 dn 4
c1 tp 4
c6 kn 4
c29 g 1
c26 rn 4
c80 z 4
c2 fv 4
c52 d 1
c134 dr 4
c28 pr 4
c18 dk 4
c36 ck 4
c3 fc 4
c4 hm 4
c9 dm 4
c8 rr 4
c4 rm 4
c6 tm 4
c5 hk 4
c5 fh 4
c4 fw 4
c9 kl 4
c5 dw 4
c12 dl 4
c1 tb 4
c4 tk 4
c3 hq 4
c4 rw 4
c7 dc 4
c12 dd 4
c6 hl 4
c2 hc 4
c4 ks 4
c5 db 4
c3 rl 4
c2 kv 4
c2 ts 4
c7 dt 4
c6 kh 4
c1 hv 4
c1 fb 4
c33 v 4
c5 kw 4
c3 hn 4
c5 rs 4
c2 kq 4
c2 tt 4
c6 km 4
c1 hw 4
c3 fk 4
c6 dh 4
c2 hd 4
c3 dv 4
c2 rq 4
c7 kk 4
c1 rc 4
c1 hh 4
c2 fp 4
c4 kd 4
c2 hb 4
c2 fm 4
c2 rg 4
c1 tc 4
c2 hp 4
c1 tw 4
c1 fn 4
c2 fl 4
c1 kc 4
c2 kb 4
c2 rb 4
c3 rt 4
c1 td 4
c1 fq 4
c1 fg 4
c1 kg 4 ]
    # create x y table for statistical proc
    set header [list x y]
    set bc_lists [list ]
    set bv_lists [list ]
    lappend bc_lists $header
    lappend bv_lists $header
    set mc_lists [list ]
    set mv_lists [list ]
    lappend mc_lists $header
    lappend mv_lists $header
    set ec_lists [list ]
    set ev_lists [list ]
    lappend ec_lists $header
    lappend ev_lists $header

    set y 0
    foreach {entry} $nar_file_list {
        switch -regexp -- $entry {
            [c][0-9]+ {
                set letter "c"
                set x [string range $entery 1 end]
            }
            [v][0-9]+ {
                set letter "v"
                set x [string range $entery 1 end]
            }
            [a-z]+ {
                incr y
                set y_arr(${y}) $entry
            }
            [0-9]+ {
                set row [list $x $y]
                if { [expr { $position & 4 } ] } {
                    # can be in middle
                    if { $letter eq "c" } {
                        lappend mc_lists $row
                    } elseif { $letter eq "v" } {
                        lappend mv_lists $row
                    }
                }
                if { [expr { $position & 2 } ] } {
                    # can be at beginning
                    if { $letter eq "c" } {
                        lappend bc_lists $row
                    } elseif { $letter eq "v" } {
                        lappend bv_lists $row
                    }
                }
                if { [expr { $position & 1 } ] } {
                    # can be at end of word
                    if { $letter eq "c" } {
                        lappend ec_lists $row
                    } elseif { $letter eq "v" } {
                        lappend ev_lists $row
                    }
                }
            }
        }
    }
    set names_list [list ]
    for {set j 0} {$j < $n} {incr j} {
        set chars_list [list ]
        if { [random] > .5 } {
            set y1 [qaf_y_of_x_dist_curve [random] $bc_lists]
            lappend chars_list $y(${y1})
        } 
        set y1 [qaf_y_of_x_dist_curve [random] $bv_lists]
        lappend chars_list $y(${y1})

        set max [randomRange $m]
        for {set i 1 } {$i < $max } { incr i } {
            set ymc [qaf_y_of_x_dist_curve [random] $mc_lists]
            lappend chars_list $y(${ymc})
            set ymv [qaf_y_of_x_dist_curve [random] $mv_lists]
            lappend chars_list $y(${ymv})
        }
        set yec [qaf_y_of_x_dist_curve [random] $ec_lists]
        lappend chars_list $y(${yec})
        if { [random] > .5 } {
            set yev [qaf_y_of_x_dist_curve [random] $ev_lists]
            lappend chars_list $y(${yev})
        }
        lappend names_list [join $chars_list ""]
    }
    return names_list
}


ad_proc -private hf_asset_summary_status {
    {customer_ids_list ""}
    {interval_remaining_ts ""}
    {list_limit ""}
    {now_ts ""}
    {interval_length_ts ""}
    {list_offset ""}
} {
    Returns summary list of status, highest scores first. Ordered lists are: asset_label asset_name asset_type metric latest_sample unit percent_quota projected_eop score score_message
} {
    # interval_remaining_ts  timestamp in seconds
    # # following two options might be alternatives to interval_remaining_ts
    # now_ts                in timestamp seconds
    # interval_length_ts    in timestamp seconds

    if { [llength $customer_ids_list] == 0 } {
        set customer_ids_list [list ]
    } 
    # list_limit            limits the number of items returned.
    # list_offset           where to begin in the list
    # This is configured as a demo.
    # A release version would require user_id, customer_ids_list..
    
    if { $now_ts eq "" } {
        set now_ts [clock seconds]
    }

    # EOT = end of term
    # classic
    # asset_type attribute quota current_sample projected_EOT
    
    # compact view: percent of alloted resources
    # asset_type attribute pct_of_quota projected_EOT_pct
    

    # from ams example
    # HW Traffic 102400000000 136.69 GB 146.67 GB
    # HW Storage 10.00 TB 2.37 TB 3.25 TB
    # HW Memory 768.00 GB 537.00 GB 580.00 GB
    # VM Traffic 1024 GB 136.69 MB 146.67 MB
    # VM Storage 10.00 GB 2.37 GB 3.25 GB
    # VM Memory 768.00 MB 537.00 MB 580.00 MB
    # SS Traffic 1024 MB 136.69 KB 146.67 KB
    # SS Storage 10.00 MB 2.37 MB 3.25 MB
    # SS Memory 768.00 KB 537.00 KB 580.00 KB
    
    if { $list_limit ne "" } {
        # do nothing here
    } else {
        # generate a set of pseudo random list of numbers.. that changes about every 10 minutes.
        set random [expr { wide( [clock seconds] / 360 ) }] 
        set i 0
        set random_list [list ]
        while { $i < 20000 } {
            set random [expr { wide( fmod( $random * 38629 , 279470273 ) * 71 ) } ]
            lappend random_list [expr { srand($random) } ]
            incr i
        }
#        ns_log Notice "random_list $random_list"
    }

    # following from hipsteripsum.me
    set random_names [list Umami gastropub authentic keytar Church-key Brooklyn four loko yr VHS craft beer hoodie Shoreditch gluten-free food truck squid seitan disrupt synth you probably havent heard of them Hoodie beard polaroid single-origin coffee skateboard organic irony plaid XOXO ethical IPhone squid photo booth irony street art lomo gastropub bitters literally kogi Bicycle rights PBR small batch deep ab.v post-ironic Vice photo booth Mustache Portland selvage Vice yr YOLO Banksy slow-carb Odd Future cred Shabby chic Blue Bottle pop-up XOXO cray locavore sartorial deep v butcher readymade gluten-free hub center socialhub sportshub businesshub mediahub musichub newshub designhub healthhubhub Umamihub gastropubhub authentichub keytarhub Church-keyhub Brooklynhub fourhub lokohub yrhub VHShub crafthub beerhub hoodiehub Shoreditchhub gluten-freehub foodhub truckhub squidhub seitanhub disrupthub synthhub youhub probablyhub haventhub heardhub ofhub themhub Hoodiehub beardhub polaroidhub single-originhub coffeehub skateboardhub organichub ironyhub plaidhub XOXOhub ethicalhub IPhonehub squidhub photohub boothhub ironyhub streethub arthub lomohub gastropubhub bittershub literallyhub kogihub Bicyclehub rightshub PBRhub smallhub batchhub deephub ab.vhub post-ironichub Vicehub photohub boothhub Mustachehub Portlandhub selvagehub Vicehub yrhub YOLOhub Banksyhub slow-carbhub Oddhub Futurehub credhub Shabbyhub chichub Bluehub Bottlehub pop-uphub XOXOhub crayhub locavorehub sartorialhub deephub vhub butcherhub readymadehub gluten-freehub hubhubub centerhubub Umamiub gastropubub authenticub keytarub Church-keyub Brooklynub fourub lokoub yrub VHSub craftub beerub hoodieub Shoreditchub gluten-freeub foodub truckub squidub seitanub disruptub synthub youub probablyub haventub heardub ofub themub Hoodieub beardub polaroidub single-originub coffeeub skateboardub organicub ironyub plaidub XOXOub ethicalub IPhoneub squidub photoub boothub ironyub streetub artub lomoub gastropubub bittersub literallyub kogiub Bicycleub rightsub PBRub smallub batchub deepub ab.vub post-ironicub Viceub photoub boothub Mustacheub Portlandub selvageub Viceub yrub YOLOub Banksyub slow-carbub Oddub Futureub credub Shabbyub chicub Blueub Bottleub pop-upub XOXOub crayub locavoreub sartorialub deepub vub butcherub readymadeub gluten-freeub hubub centerub socialhubub sportshubub businesshubub mediahubub musichubub newshubub designhubub healthhubhubub Umamihubub gastropubhubub authentichubub keytarhubub Church-keyhubub Brooklynhubub fourhubub lokohub Umaami gaastropub aauthentic keytaar Church-key Brooklyn four loko yr VHS craaft beer hoodie Shoreditch gluten-free food truck squid seitaan disrupt synth you probaably haavent heaard of them Hoodie beaard polaaroid single-origin coffee skaateboaard orgaanic irony plaaid XOXO ethicaal IPhone squid photo booth irony street aart lomo gaastropub bitters literaally kogi Bicycle rights PBR smaall baatch deep aab.v post-ironic Vice photo booth Mustaache Portlaand selvaage Vice yr YOLO Baanksy slow-caarb Odd Future cred Shaabby chic Blue Bottle pop-up XOXO craay locaavore saartoriaal deep v butcher reaadymaade gluten-free quy center sociaalquy sportsquy businessquy mediaaquy musicquy newsquy designquy heaalthquyquy Umaamiquy gaastropubquy aauthenticquy keytaarquy Church-keyquy Brooklynquy fourquy lokoquy yrquy VHSquy craaftquy beerquy hoodiequy Shoreditchquy gluten-freequy foodquy truckquy squidquy seitaanquy disruptquy synthquy youquy probaablyquy haaventquy heaardquy ofquy themquy Hoodiequy beaardquy polaaroidquy single-originquy coffeequy skaateboaardquy orgaanicquy ironyquy plaaidquy XOXOquy ethicaalquy IPhonequy squidquy photoquy boothquy ironyquy streetquy aartquy lomoquy gaastropubquy bittersquy literaallyquy kogiquy Bicyclequy rightsquy PBRquy smaallquy baatchquy deepquy aab.vquy post-ironicquy Vicequy photoquy boothquy Mustaachequy Portlaandquy selvaagequy Vicequy yrquy YOLOquy Baanksyquy slow-caarbquy Oddquy Futurequy credquy Shaabbyquy chicquy Bluequy Bottlequy pop-upquy XOXOquy craayquy locaavorequy saartoriaalquy deepquy vquy butcherquy reaadymaadequy gluten-freequy quyhoodob centerhoodob Umaamiub gaastropubub aauthenticub keytaarub Church-keyub Brooklynub fourub lokoub yrub VHSub craaftub beerub hoodieub Shoreditcquy gluten-freeub foodub truckub squidub seitaanub disruptub syntquy youub probaablyub haaventub heaardub ofub themub Hoodieub beaardub polaaroidub single-originub coffeeub skaateboaardub orgaanicub ironyub plaaidub XOXOub ethicaalub IPhoneub squidub photoub bootquy ironyub streetub aartub lomoub gaastropubub bittersub literaallyub kogiub Bicycleub rightsub PBRub smaallub baatcquy deepub aab.vub post-ironicub Viceub photoub bootquy Mustaacheub Portlaandub selvaageub Viceub yrub YOLOub Baanksyub slow-caarbub Oddub Futureub credub Shaabbyub chicub Blueub Bottleub pop-upub XOXOub craayub locaavoreub saartoriaalub deepub vub butcherub reaadymaadeub gluten-freeub hoodob centerub sociaalhoodob sportshoodob businesshoodob mediaahoodob musichoodob newshoodob designhoodob heaalthquyhoodob Umaamihoodob gaastropubhoodob aauthentichoodob keytaarhoodob Church-keyhoodob Brooklynhoodob fourhoodob lokoquy Umami3 gastropub3 authentic3 keytar3 Church-key3 Brooklyn3 four3 loko3 yr3 VHS3 craft3 beer3 hoodie3 Shoreditch3 gluten-free3 food3 truck3 squid3 seitan3 disrupt3 synth3 you3 probably3 havent3 heard3 of3 them3 Hoodie3 beard3 polaroid3 single-origin3 coffee3 skateboard3 organic3 irony3 plaid3 XOXO3 ethical3 IPhone3 squid3 photo3 booth3 irony3 street3 art3 lomo3 gastropub3 bitters3 literally3 kogi3 Bicycle3 rights3 PBR3 small3 batch3 deep3 ab.v3 post-ironic3 Vice3 photo3 booth3 Mustache3 Portland3 selvage3 Vice3 yr3 YOLO3 Banksy3 slow-carb3 Odd3 Future3 cred3 Shabby3 chic3 Blue3 Bottle3 pop-up3 XOXO3 cray3 locavore3 sartorial3 deep3 v3 butcher3 readymade3 gluten-free3 hub3 center3 socialhub3 sportshub3 businesshub3 mediahub3 musichub3 newshub3 designhub3 healthhubhub3 Umamihub3 gastropubhub3 authentichub3 keytarhub3 Church-keyhub3 Brooklynhub3 fourhub3 lokohub3 yrhub3 VHShub3 crafthub3 beerhub3 hoodiehub3 Shoreditchhub3 gluten-freehub3 foodhub3 truckhub3 squidhub3 seitanhub3 disrupthub3 synthhub3 youhub3 probablyhub3 haventhub3 heardhub3 ofhub3 themhub3 Hoodiehub3 beardhub3 polaroidhub3 single-originhub3 coffeehub3 skateboardhub3 organichub3 ironyhub3 plaidhub3 XOXOhub3 ethicalhub3 IPhonehub3 squidhub3 photohub3 boothhub7 ironyhub7 streethub7 arthub7 lomohub7 gastropubhub7 bittershub7 literallyhub7 kogihub7 Bicyclehub7 rightshub7 PBRhub7 smallhub7 batchhub7 deephub7 ab.vhub7 post-ironichub7 Vicehub7 photohub7 boothhub7 Mustachehub7 Portlandhub7 selvagehub7 Vicehub7 yrhub7 YOLOhub7 Banksyhub7 slow-carbhub7 Oddhub7 Futurehub7 credhub7 Shabbyhub7 chichub7 Bluehub7 Bottlehub7 pop-uphub7 XOXOhub7 crayhub7 locavorehub7 sartorialhub7 deephub7 vhub7 butcherhub7 readymadehub7 gluten-freehub7 hubhubub7 centerhubub7 Umamiub7 gastropubub7 authenticub7 keytarub7 Church-keyub7 Brooklynub7 fourub7 lokoub7 yrub7 VHSub7 craftub7 beerub7 hoodieub7 Shoreditchub7 gluten-freeub7 foodub7 truckub7 squidub7 seitanub7 disruptub7 synthub7 youub7 probablyub7 haventub7 heardub7 ofub7 themub7 Hoodieub7 beardub7 polaroidub7 single-originub7 coffeeub7 skateboardub7 organicub7 ironyub7 plaidub7 XOXOub7 ethicalub7 IPhoneub7 squidub7 photoub7 boothub7 ironyub7 streetub7 artub7 lomoub7 gastropubub7 bittersub7 literallyub7 kogiub7 Bicycleub7 rightsub7 PBRub7 smallub7 batchub7 deepub7 ab.vub7 post-ironicub7 Viceub7 photoub7 boothub7 Mustacheub7 Portlandub7 selvageub7 Viceub7 yrub7 YOLOub7 Banksyub7 slow-carbub7 Oddub7 Futureub7 credub7 Shabbyub7 chicub7 Blueub7 Bottleub7 pop-upub7 XOXOub7 crayub7 locavoreub7 sartorialub7 deepub7 vub7 butcherub7 readymadeub7 gluten-freeub7 hubub7 centerub7 socialhubub7 sportshubub7 businesshubub7 mediahubub7 musichubub7 newshubub7 designhubub7 healthhubhubub7 Umamihubub7 gastropubhubub7 authentichubub7 keytarhubub7 Church-keyhubub7 Brooklynhubub7 fourhubub7 lokohub7 Umaami7 gaastropub7 aauthentic7 keytaar7 Church-key7 Brooklyn7 four7 loko7 yr7 VHS7 craaft7 beer7 hoodie7 Shoreditch7 gluten-free7 food7 truck8 squid8 seitaan8 disrupt8 synth8 you8 probaably8 haavent8 heaard8 of8 them8 Hoodie8 beaard8 polaaroid8 single-origin8 coffee8 skaateboaard8 orgaanic8 irony8 plaaid8 XOXO8 ethicaal8 IPhone8 squid8 photo8 booth8 irony8 street8 aart8 lomo8 gaastropub8 bitters8 literaally8 kogi8 Bicycle8 rights8 PBR8 smaall8 baatch8 deep8 aab.v8 post-ironic8 Vice8 photo8 booth8 Mustaache8 Portlaand8 selvaage8 Vice8 yr8 YOLO8 Baanksy8 slow-caarb8 Odd8 Future8 cred8 Shaabby8 chic8 Blue8 Bottle8 pop-up8 XOXO8 craay8 locaavore8 saartoriaal8 deep8 v8 butcher8 reaadymaade8 gluten-free8 quy8 center8 sociaalquy8 sportsquy8 businessquy8 mediaaquy8 musicquy8 newsquy8 designquy8 heaalthquyquy8 Umaamiquy8 gaastropubquy8 aauthenticquy8 keytaarquy8 Church-keyquy8 Brooklynquy8 fourquy8 lokoquy8 yrquy8 VHSquy8 craaftquy8 beerquy8 hoodiequy8 Shoreditchquy8 gluten-freequy8 foodquy8 truckquy8 squidquy8 seitaanquy8 disruptquy8 synthquy8 youquy8 probaablyquy8 haaventquy8 heaardquy8 ofquy8 themquy8 Hoodiequy8 beaardquy8 polaaroidquy8 single-originquy8 coffeequy8 skaateboaardquy8 orgaanicquy8 ironyquy8 plaaidquy8 XOXOquy8 ethicaalquy8 IPhonequy8 squidquy8 photoquy8 boothquy8 ironyquy8 streetquy8 aartquy8 lomoquy8 gaastropubquy8 bittersquy8 literaallyquy5 kogiquy5 Bicyclequy5 rightsquy5 PBRquy5 smaallquy5 baatchquy5 deepquy5 aab.vquy5 post-ironicquy5 Vicequy5 photoquy5 boothquy5 Mustaachequy5 Portlaandquy5 selvaagequy5 Vicequy5 yrquy5 YOLOquy5 Baanksyquy5 slow-caarbquy5 Oddquy5 Futurequy5 credquy5 Shaabbyquy5 chicquy5 Bluequy5 Bottlequy5 pop-upquy5 XOXOquy5 craayquy5 locaavorequy5 saartoriaalquy5 deepquy5 vquy5 butcherquy5 reaadymaadequy5 gluten-freequy5 quyhoodob5 centerhoodob5 Umaamiub5 gaastropubub5 aauthenticub5 keytaarub5 Church-keyub5 Brooklynub5 fourub5 lokoub5 yrub5 VHSub5 craaftub5 beerub5 hoodieub5 Shoreditcquy5 gluten-freeub5 foodub5 truckub5 squidub5 seitaanub5 disruptub5 syntquy5 youub5 probaablyub5 haaventub5 heaardub5 ofub5 themub5 Hoodieub5 beaardub5 polaaroidub5 single-originub5 coffeeub5 skaateboaardub5 orgaanicub5 ironyub5 plaaidub5 XOXOub5 ethicaalub5 IPhoneub5 squidub5 photoub5 bootquy5 ironyub5 streetub5 aartub5 lomoub5 gaastropubub5 bittersub5 literaallyub5 kogiub5 Bicycleub5 rightsub5 PBRub5 smaallub5 baatcquy5 deepub5 aab.vub5 post-ironicub5 Viceub5 photoub5 bootquy5 Mustaacheub5 Portlaandub5 selvaageub5 Viceub5 yrub5 YOLOub5 Baanksyub5 slow-caarbub5 Oddub5 Futureub5 credub5 Shaabbyub5 chicub5 Blueub5 Bottleub5 pop-upub5 XOXOub5 craayub5 locaavoreub5 saartoriaalub5 deepub5 vub5 butcherub5 reaadymaadeub5 gluten-freeub5 hoodob5 centerub5 sociaalhoodob5 sportshoodob5 businesshoodob5 mediaahoodob5 musichoodob5 newshoodob5 designhoodob5 heaalthquyhoodob5 Umaamihoodob5 gaastropubhoodob5 aauthentichoodob5 keytaarhoodob5 Church-keyhoodob5 Brooklynhoodob5 fourhoodob5 lokoquy11]
    set names_count [llength $random_names]
    set random_names_list [list ]
    set random_suffix_list [list net com me info ca us pa es co.uk tv no dk de fr jp cn in org cc biz nu ws bz org.uk tm ms pro mx tw jobs ac io sh eu at nl la fm it co ag pl sc hn mn tk vc pe au ch ru se fi if os so be do hi ho is jo ro un cae use pae ese co.uke tve noe dke dee fre jpe cne ine orge cce bize nue wse bze org.uke tme mse proe mxe twe jobse ace ioe she eue ate nle lae fme ite coe age ple sce hne mne tke vce pee aue che rue see fie ife ose soe bee doe hie hoe ise joe roe yunz netz comz mez infoz caz usz paz esz co.ukz tvz noz dkz dez frz jpz cnz inz orgz ccz bizz nuz wsz bzz org.ukz tmz msz proz mxz twz jobsz acz ioz shz euz atz nlz laz fmz itz coz agz plz scz hnz mnz tkz vcz pez auz chz ruz sez fiz ifz osz soz bez doz hiz hoz isz joz roz unz caez usez paez esez co.ukez tvez noez dkez deez frez jpez cnez inez orgez ccez bizez nuez wsez bzez org.ukez tmez msez net comq meq infoq caq usq paq esq co.ukq tvq noq dkq deq frq jpq cnq inq orgq ccq bizq nuq wsq bzq org.ukq tmq msq proq mxq twq jobsq acq ioq shq euq atq nlq laq fmq itq coq agq plq scq hnq mnq tkq vcq peq auq chq ruq seq fiq ifq osq soq beq doq hiq hoq isq joq roq unq]
    set suffix_count [llength $random_suffix_list ]
    foreach name $random_names {
        if { $list_limit ne "" } {
            set tld [lindex $random_suffix_list [expr { wide( [random ] * $suffix_count ) } ]]
            set domain [lindex $random_names [expr { wide( [random ] * $names_count ) } ]]
        } else {
            set tld [lindex $random_suffix_list [expr { wide( [hf_peek_pop_stack random_list ] * $suffix_count ) } ]]
            set domain [lindex $random_names [expr { wide( [hf_peek_pop_stack random_list ] * $names_count ) } ]]
        }
        lappend random_names_list "$domain.$tld"
    }
    set random_names_list_2 [lsort -unique $random_names_list]
    set as_root_lists [list [list DC traffic power other] \
                           [list HW traffic storage] \
                           [list VM traffic storage memory] \
                           [list VH storage] \
                           [list SS traffic storage memory]]
    foreach asr_list $as_root_lists {
        set i [lindex $asr_list 0]
        set asr_arr($i) [lreplace $asr_list 0 0]
#        ns_log Notice "hf_asset_summary_status: asr_arr($i) '$asr_arr($i)'"
    }
    set as_type_list [list DC HW VM VH SS]
    set as_type_count [llength $as_type_list]
    
    set quota_lists [list \
                         [list DC traffic 102400000000000] \
                         [list DC power 10000000000000] \
                         [list DC other 10000000000000] \
                         [list HW traffic 102400000000] \
                         [list HW storage 10000000000000] \
                         [list VM traffic 1024000000000] \
                         [list VM storage 10000000000] \
                         [list VM memory 768000000] \
                         [list VH storage 10000000] \
                         [list SS traffic 1024000000] \
                         [list SS storage 10000000] \
                         [list SS memory 768000]]
    foreach q_list $quota_lists {
        set i "[lindex $q_list 0],[lindex $q_list 1]"
        set quota_arr($i) [lindex $q_list 2]
    }
    
    # asset db
    # attribute = meter_type = metric
    # as_label as_name as_type 
    set asset_db_lists [list ]
    if { $list_limit ne "" } {
        set as_count [expr { wide( [random ] * 50 ) + 1 } ]
    } else {
        # let's use a consistent random thread, vary the seed periodically
        # so that there is some continuity between pages
        set as_count [expr { wide ( [hf_peek_pop_stack random_list] * 1000 ) + 1 } ]
    }

    for { set i 0} {$i < $as_count} {incr i} {
        if { $list_limit ne "" } {
            set name_i [expr { wide( [random ] * $names_count ) } ]
        } else {
            set name_i [expr { wide ( [hf_peek_pop_stack random_list] * $names_count ) } ]
        }
        set as_label [lindex $random_names_list $name_i]
        # remove as_label from list
        set random_names_list [lreplace $random_names_list $name_i $name_i]
        incr names_count -1
        set as_name $as_label
        if { $list_limit ne "" } { 
            set as_type [lindex $as_type_list [expr { wide( [random ] * $as_type_count ) } ]]
        } else {
            set as_type [lindex $as_type_list [expr { wide( [hf_peek_pop_stack random_list] * $as_type_count ) } ]]
        }
        #ns_log Notice "hf_asset_summary_status: as_type '$as_type' "
        # as_label as_name as_type
        set as_list [list $as_label $as_name $as_type]
        lappend asset_db_lists $as_list
    }
#    ns_log Notice "hf_asset_summary_status(196): asset_db_lists '$asset_db_lists' "
    
    
    # for the demo,  manually build a fake list instead of calling a procedure
    # as_label as_name as_type metric latest_sample unit percent_quota projected_eop score score_message
    set asset_report_lists [list ]
    set debug_counter 0
    foreach asset_list $asset_db_lists {
        incr debug_counter

        set sample_html ""
        #calc $sample_html $unit $pct_quota_html $projected_eop_html $health_score $hs_message
        # asset_list is a list of asset attributes: label, name, type
        set as_type [lindex $asset_list 2]
        # start rolling dice..
        if { $list_limit ne "" } {
            set active_p [expr { wide( [random ] * 16 ) > 1 } ] 
        } else {
            set active_p [expr { wide( [hf_peek_pop_stack random_list] * 16 ) > 1 } ] 
        }
        # asset_list =  $as_label $as_name $as_type
        
        if { $active_p } {
            # sometimes an account is new, so not enough info exists
            # role dice..
            if { $list_limit ne "" } {
                set history_exists_p [expr { wide( [random ] * 16 ) > 1 } ]
            } else {
                set history_exists_p [expr { wide( [hf_peek_pop_stack random_list] * 16 ) > 1 } ]
            }
            # metric1 metric2 metric..
            set metric_list $asr_arr($as_type) 
   #         ns_log Notice "hf_asset_summary_status(221): metric_list '$metric_list' llength [llength $metric_list]"
            foreach as_at $metric_list {
                set as_reports_list $asset_list
  #              ns_log Notice "hf_asset_summary_status(224): counter $debug_counter active_p $active_p as_type $as_type as_reports_list,asset_list $as_reports_list"
#                ns_log Notice "hf_asset_summary_status(218): as_type $as_type as_at $as_at"
                # quota_arr(as_type,metric) = quota amount
                set iq "${as_type},${as_at}"
                set quota [expr { wide( $quota_arr($iq) ) } ]
                # 16 health scores, lets randomly try to get all cases for demo and testing
                # only 1/8 are stressfull , 1/8 = 0.125
                if { $list_limit ne "" } {
                    set sample [expr { wide( sqrt( [random ] * [random ] ) * $quota * 1.325 ) } ]
                } else {
                    set sample [expr { wide( sqrt( [hf_peek_pop_stack random_list] * [random ] ) * $quota * 1.325 ) } ]
                }
                set unit "B"
                set pct_quota [expr { wide( 100. * $sample / ( $quota * 1.) ) } ]
#                set pct_quota_html [format "%d%%" $pct_quota]
                set pct_quota_html $pct_quota
                if { $history_exists_p } {
                    if { $list_limit ne "" } {
                        set weeks_rate [expr { wide( [random ] * $sample / 3. ) } ]  
                    } else {
                        set weeks_rate [expr { wide( [hf_peek_pop_stack random_list] * $sample / 3. ) } ]  
                    }
                    # convert rate to interval_length
                    # 1 week = 604800 clicks
                    # interval_rate = units_per_week / secs_per_week * secs_per_interval_remaining
                    set interval_rate [expr { $weeks_rate * $interval_remaining_ts / 604800. } ]
                    set projected_eop [expr { $sample + $interval_rate } ]
#ns_log Notice "hf_asset_summary_status(242): sample $sample pct_quota $pct_quota pct_quota_html $pct_quota_html weeks_rate $weeks_rate interval_rate $interval_rate projected_eop $projected_eop"
                    set projected_eop_html $projected_eop
                    if { $as_at eq "traffic" } {
                        set sample_html $sample
#                        set sample_html [qal_pretty_bytes_iec $sample]
#                        set projected_eop_html [qal_pretty_bytes_iec $projected_eop]
                        set projected_eop_html $projected_eop
 #                       ns_log Notice "hf_asset_summary_status(247): pretty_bytes_iec calc sample_html $sample_html projected_eop_html $projected_eop_html"
                    } else {
#                        set sample_html [qal_pretty_bytes_dec $sample]
                        set sample_html $sample
#                        set projected_eop_html [qal_pretty_bytes_dec $projected_eop]
                        set projected_eop_html $projected_eop
 #                       ns_log Notice "hf_asset_summary_status(251): pretty_bytes_dec calc sample_html $sample_html projected_eop_html $projected_eop_html"
                    }

                } else {
                    # not enough history to calculate
                    set projected_eop 0
# These values could be set to N/A, since it is too early to make projections,
# but that causes problems with sorting the results.
# So, we make a projection based on existing values and assume change is negligible. 
#                    set projected_eop_html "#accounts-ledger.N_A#"
                    # let's use e/2 just for the heck of it..
                    set projected_eop_html [expr { $sample * 1.35914 } ]
                    if { $as_at eq "traffic" } {
#                        set sample_html [qal_pretty_bytes_iec $sample]
                        set sample_html $sample
                    } else {
#                        set sample_html [qal_pretty_bytes_dec $sample]
                        set sample_html $sample
                    }

                }
                
                # calc health score value
                # initial health is based on background performance..
                set health_score [expr { wide( [random ] * 11 ) + 1 } ]
                set hs_message "#accounts-ledger.${health_score}#"
                if { $projected_eop > [expr { $quota * 0.9 } ] || $pct_quota > 80 } {
                    set health_score 13
                    set hs_message "Near quota limit."
                }
                if { $projected_eop > $quota } {
                    set health_score 14
                    set hs_message "May be over quota before end of term."
                }
                if { $pct_quota > 100 } {
                    set health_score 15
                    set hs_message "Over quota."
                }
                # $as_at is metric
                lappend as_reports_list $as_at
 #               ns_log Notice "hf_asset_summary_status(271): as_reports_list $as_reports_list"
                lappend as_reports_list $sample_html $pct_quota_html $projected_eop_html $health_score $hs_message
#                ns_log Notice "hf_asset_summary_status(273): as_reports_list $as_reports_list"
                # as_label as_name as_type metric latest_sample unit percent_quota projected_eop score score_message
                lappend asset_report_lists $as_reports_list
 #               ns_log Notice "hf_asset_summary_status(278): as_reports_list $as_reports_list"
            }
        } else {
            # asset not active
            set as_reports_list $asset_list
 #           ns_log Notice "hf_asset_summary_status(290): counter $debug_counter active_p $active_p as_type $as_type as_reports_list,asset_list $as_reports_list"
            set health_score 0
            set hs_message ""
            lappend as_reports_list "#accounts-ledger.N_A#" "0" "0" "0" $health_score "inactive"
#            ns_log Notice "hf_asset_summary_status(282): as_reports_list $as_reports_list"
            lappend asset_report_lists $as_reports_list
        }
    }
    
    # report db built from hf_monitor_config_n_control, monitor_log, hf_monitor_status
    # reportdb asset_label as_type as_attribute monitor_label portions_count health report_id
    # for quota monitoring, portions_count is count per last two weeks.

    # qal_pretty_* numbers get processed after the proc is returned, otherwise sorts get complciated.
    if { $list_limit ne "" } {
        # secondary sorts
        # as_label as_name as_type metric latest_sample percent_quota projected_eop score score_message
        set asset_report_lists [lsort -real -index 6 -increasing $asset_report_lists]
        set asset_report_lists [lsort -integer -index 5 -decreasing $asset_report_lists]
        # then presort by projected value, followed by quota
        # primary sort
        set asset_db_sorted_lists [lsort -integer -index 7 -decreasing $asset_report_lists]
    } {
        # don't sort here.. waste of time..
        set asset_db_sorted_lists $asset_report_lists
    }

    if { $list_limit ne "" } {
        incr list_limit -1
    } else {
        set list_limit "end"
    }
    if { $list_offset eq "" } {
        set list_offset 0
    }
    set asset_db_sorted_lists [lrange $asset_db_sorted_lists $list_offset $list_limit]
    
   # ns_log Notice "hf_asset_summary_status: asset_db_sorted_lists $asset_db_sorted_lists"
    return $asset_db_sorted_lists
}

