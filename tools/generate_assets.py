"""Generate original pixel art and synthesised audio. Runtime needs only the output files."""
from PIL import Image, ImageDraw
from pathlib import Path
import math, random, struct, wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'generated'
AUDIO = ROOT / 'assets' / 'audio'
OUT.mkdir(parents=True, exist_ok=True)
AUDIO.mkdir(parents=True, exist_ok=True)
random.seed(17)

def canvas(w=128, h=128):
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)

def save(im, name): im.save(OUT / (name + '.png'))
INK = '#44384d'

def face(d, x=64, y=67, gap=14, smile=True):
    d.rectangle((x-gap-5,y-4,x-gap-1,y+2), fill=INK)
    d.rectangle((x+gap+1,y-4,x+gap+5,y+2), fill=INK)
    d.rectangle((x-15,y+13,x+15,y+15), fill='#b45567' if smile else INK)
    d.rectangle((x-20,y+8,x-15,y+11), fill='#f18a98')
    d.rectangle((x+15,y+8,x+20,y+11), fill='#f18a98')

def legs(d, left=45, right=83, top=92):
    d.rectangle((left,top,left+13,top+18), fill=INK)
    d.rectangle((right-13,top,right,top+18), fill=INK)
    d.rectangle((left-4,top+16,left+17,top+21), fill='#5b4271')
    d.rectangle((right-17,top+16,right+4,top+21), fill='#5b4271')

def donut():
    im,d=canvas(); legs(d)
    d.ellipse((17,20,111,101), fill='#8e4d35', outline=INK, width=5)
    d.ellipse((22,19,106,88), fill='#c97a46')
    d.ellipse((29,23,99,76), fill='#55352d')
    d.ellipse((50,39,78,68), fill=(0,0,0,0))
    d.ellipse((50,39,78,68), fill='#3b324c')
    for x,y,c in [(32,32,'#fbd885'),(86,37,'#f7a9b5'),(94,61,'#b8d99b'),(37,70,'#f9e8a8'),(71,23,'#f19e89')]:
        d.rectangle((x,y,x+8,y+3),fill=c)
    face(d,64,76,17); save(im,'donut')

def cake():
    im,d=canvas(); legs(d,43,86,94)
    d.polygon([(22,90),(101,90),(82,28),(38,28)],fill='#fff1de')
    d.polygon([(30,67),(94,67),(90,55),(34,55)],fill='#dc6580')
    d.polygon([(38,28),(82,28),(89,51),(32,51)],fill='#fffaf0')
    d.rectangle((48,18,79,32),fill='#e86076'); d.rectangle((54,13,73,21),fill='#f3889b')
    d.rectangle((39,89,85,99),fill='#f7d0b5')
    face(d,63,71,12); save(im,'cake')

def karaage():
    im,d=canvas(); legs(d)
    d.polygon([(23,43),(43,23),(69,30),(92,19),(108,45),(101,74),(88,96),(41,99),(19,73)],fill='#b96d34',outline=INK)
    for x,y in [(35,43),(56,36),(82,41),(42,69),(69,78),(91,68)]:
        d.rectangle((x,y,x+12,y+10),fill='#d99245')
        d.rectangle((x+2,y+1,x+8,y+3),fill='#f5bc64')
    face(d,64,58,15); save(im,'karaage')

def burger():
    im,d=canvas(); legs(d)
    d.ellipse((17,18,111,75),fill='#eab46a',outline=INK,width=4)
    for x,y in [(40,34),(63,28),(84,39),(53,45)]: d.rectangle((x,y,x+5,y+3),fill='#fff0bd')
    d.rectangle((19,62,109,73),fill='#77a765')
    d.rectangle((15,74,113,89),fill='#674132')
    d.polygon([(23,85),(37,98),(50,86),(66,99),(81,86),(102,93),(105,101),(22,101)],fill='#efc65c')
    d.ellipse((22,86,106,112),fill='#e2a55f',outline=INK,width=3)
    face(d,63,64,17); save(im,'burger')

def pizza():
    im,d=canvas(); legs(d)
    d.polygon([(12,30),(111,43),(63,108)],fill='#d1964f',outline=INK)
    d.polygon([(17,34),(99,46),(63,96)],fill='#f4c96d')
    d.polygon([(13,28),(111,42),(109,53),(15,40)],fill='#d8894e')
    for x,y in [(45,48),(76,57),(59,76)]: d.ellipse((x-9,y-7,x+9,y+8),fill='#cf6670')
    face(d,64,57,11); save(im,'pizza')

def parfait():
    im,d=canvas(); legs(d,51,77,101)
    d.polygon([(29,47),(99,47),(88,98),(77,108),(51,108),(39,98)],fill='#d7d0e5',outline=INK)
    d.rectangle((39,60,89,71),fill='#dc8eaa'); d.rectangle((45,78,83,87),fill='#f4d89a')
    d.ellipse((24,30,104,62),fill='#fff4e4',outline=INK,width=3)
    d.ellipse((43,13,81,49),fill='#fff8eb'); d.ellipse((59,8,74,22),fill='#d95362')
    d.rectangle((80,9,85,52),fill='#e4c063')
    face(d,64,56,14); save(im,'parfait')

def ramen():
    im,d=canvas(); legs(d,48,80,99)
    d.ellipse((14,33,114,76),fill='#fff2d3',outline=INK,width=5)
    d.ellipse((22,36,106,69),fill='#d19e57')
    for y in (46,51,56,61): d.arc((31,y-10,95,y+10),0,180,fill='#f1d278',width=3)
    for x in (43,78): d.ellipse((x-10,37,x+12,59),fill='#c78172',outline='#aa594f',width=2)
    d.ellipse((55,41,76,59),fill='#fff3d9'); d.ellipse((61,46,71,56),fill='#f1c360')
    d.polygon([(19,67),(109,67),(94,107),(37,107)],fill='#d75d66',outline=INK)
    d.rectangle((45,84,84,90),fill='#f4c985')
    face(d,65,75,13); save(im,'ramen')

def final():
    im,d=canvas(160,150); legs(d,58,104,122)
    d.ellipse((10,72,150,136),fill='#e8d7b7',outline=INK,width=5)
    d.ellipse((19,77,141,125),fill='#f7e8cc')
    d.ellipse((25,47,98,100),fill='#d1a667',outline=INK,width=3)
    d.ellipse((31,53,90,89),fill='#edd37b')
    d.polygon([(78,53),(125,39),(137,86),(88,91)],fill='#fff1df',outline=INK)
    d.ellipse((99,26,125,53),fill='#ed6f83')
    for x,y in [(32,98),(53,107),(117,95)]: d.ellipse((x,y,x+26,y+18),fill='#bd763c',outline=INK,width=2)
    d.polygon([(115,102),(139,89),(132,118)],fill='#ecc95b')
    face(d,73,77,10); save(im,'final')

def player(name,back=False,step=0):
    im,d=canvas(64,80)
    shoe='#35364f'; skirt='#33415f'; skin='#efb48d'; hair='#493543'
    shift=3 if step==1 else -3 if step==2 else 0
    d.rectangle((20+shift,61,30+shift,75),fill=skirt)
    d.rectangle((35-shift,61,45-shift,75),fill=skirt)
    d.rectangle((17+shift,73,31+shift,78),fill=shoe)
    d.rectangle((34-shift,73,48-shift,78),fill=shoe)
    d.polygon([(20,38),(43,38),(48,62),(17,62)],fill='#e8e5dd',outline=INK)
    d.rectangle((16,43,20,60),fill=skin); d.rectangle((44,43,48,60),fill=skin)
    d.rectangle((39,44,53,65),fill='#a86d53')
    d.rectangle((42,50,56,67),fill='#bd8061')
    d.rectangle((25,31,39,43),fill=skin)
    d.ellipse((16,7,48,43),fill=hair,outline=INK,width=2)
    if not back:
        d.ellipse((21,13,43,38),fill=skin)
        d.rectangle((24,23,27,26),fill=INK); d.rectangle((36,23,39,26),fill=INK)
        d.rectangle((28,32,37,33),fill='#bc7180')
        d.rectangle((19,10,42,17),fill=hair)
    else:
        d.rectangle((19,25,46,43),fill=hair)
        d.rectangle((27,38,37,51),fill='#abb4c3')
    save(im,name)

def building(name,base,roof,sign):
    im,d=canvas(176,160)
    d.rectangle((8,38,168,154),fill=base,outline=INK,width=4)
    d.polygon([(3,38),(22,11),(155,11),(173,38)],fill=roof,outline=INK)
    d.rectangle((23,49,153,78),fill=sign,outline=INK,width=3)
    for x in (25,69,113):
        d.rectangle((x,88,x+34,130),fill='#acc8cc',outline=INK,width=3)
        d.rectangle((x+4,93,x+30,111),fill='#e8dba8')
    d.rectangle((68,128,108,159),fill='#685868',outline=INK,width=3)
    save(im,name)

for name,fn in [('donut',donut),('cake',cake),('karaage',karaage),('burger',burger),('pizza',pizza),('parfait',parfait),('ramen',ramen),('final',final)]: fn()
for name,back,step in [('player_front',False,0),('player_back',True,0),('player_walk_a',True,1),('player_walk_b',True,2)]: player(name,back,step)
im=Image.open(OUT/'player_front.png').rotate(90,expand=True,resample=Image.Resampling.NEAREST)
save(im,'player_fallen')
im,d=canvas(80,80)
d.rectangle((18,60,66,71),fill='#33415f',outline=INK,width=2)
d.rectangle((27,69,70,76),fill='#35364f')
d.polygon([(25,35),(54,35),(62,62),(18,62)],fill='#e8e5dd',outline=INK)
d.rectangle((53,42,69,61),fill='#b77b60')
d.ellipse((20,6,56,43),fill='#493543',outline=INK,width=2)
d.ellipse((26,12,51,38),fill='#efb48d')
d.rectangle((31,22,34,25),fill=INK); d.rectangle((43,22,46,25),fill=INK)
d.rectangle((36,32,44,33),fill='#bc7180')
save(im,'player_seated')
for name,base,roof,sign in [
    ('office','#7888a1','#536077','#e7c989'),('home','#e7ad92','#ae686d','#f8e6ac'),
    ('sweets','#dc9caa','#a95e76','#ffe4bd'),('diner','#d7ad70','#936b59','#f8db9d'),
    ('shop','#8db3a7','#567980','#f2da9d'),('houses','#aca0b2','#686077','#d3c3ab')]: building(name,base,roof,sign)
im,d=canvas(80,100)
d.rectangle((37,65,45,99),fill='#6a4b49')
for x,y,r,c in [(40,43,28,'#4e806a'),(23,58,22,'#5d9a72'),(58,58,21,'#5d9a72'),(41,20,19,'#6ca681')]:d.ellipse((x-r,y-r,x+r,y+r),fill=c,outline='#365b5b',width=3)
save(im,'tree')
im,d=canvas(40,90)
d.rectangle((18,20,23,89),fill='#75696c'); d.rectangle((7,14,35,25),fill='#5c5365')
d.ellipse((8,5,34,24),fill='#ffe09d',outline='#d9b875',width=3)
save(im,'lamp')

# The first pass establishes the silhouettes. This second pass draws at twice
# the source resolution, so faces, fabric, food toppings and shop fronts retain
# real detail when the browser scales the game canvas.
def polish_food(name):
    source = Image.open(OUT / (name + '.png')).convert('RGBA')
    im = source.resize((source.width * 2, source.height * 2), Image.Resampling.NEAREST)
    d = ImageDraw.Draw(im)
    w, h = im.size
    # A broken pixel highlight gives every monster a shared, hand-drawn style.
    for x, y in [(30, 51), (33, 47), (38, 44), (89, 47), (93, 52), (96, 58)]:
        if x * 2 < w and y * 2 < h:
            d.rectangle((x*2, y*2, x*2+3, y*2+2), fill='#fff3cf')
    if name == 'donut':
        for x, y, c in [(31,48,'#f3a8b1'),(39,35,'#ffe796'),(82,29,'#d8e9ae'),(92,54,'#f2b2bd'),(36,77,'#fff0ab'),(88,75,'#bfe1d0')]:
            d.rectangle((x*2,y*2,x*2+12,y*2+4),fill=c)
        d.arc((40,48,215,192),195,337,fill='#f4ac75',width=4)
    elif name == 'cake':
        for y in (39,47,82):
            d.line((73,y*2,178,y*2),fill='#ffd1d4',width=3)
        for x in (51,65,79):
            d.ellipse((x*2,63,x*2+9,71),fill='#fff9dd')
        d.ellipse((114,26,142,51),fill='#db4d68',outline='#ffe5cf',width=3)
    elif name == 'karaage':
        for x,y in [(31,48),(48,34),(74,39),(91,54),(43,78),(72,82)]:
            d.polygon([(x*2,y*2),(x*2+15,y*2-4),(x*2+22,y*2+5),(x*2+8,y*2+9)],fill='#e9a857')
            d.rectangle((x*2+4,y*2,x*2+10,y*2+2),fill='#ffe0a2')
        for x in (45,70,90): d.arc((x*2,20,x*2+13,47),190,345,fill='#ead6b2',width=3)
    elif name == 'burger':
        for x in (26,42,58,74,92):
            d.polygon([(x*2,117),(x*2+9,121),(x*2+4,126)],fill='#84b65a')
        d.line((39,156,210,156),fill='#f4d184',width=5)
        for x,y in [(36,38),(49,28),(70,36),(88,46)]: d.ellipse((x*2,y*2,x*2+8,y*2+4),fill='#fff0c2')
    elif name == 'pizza':
        for x,y in [(37,49),(49,65),(75,67),(67,82)]:
            d.ellipse((x*2,y*2,x*2+10,y*2+5),fill='#f7e69b')
        for x,y in [(50,46),(83,55),(62,76)]:
            d.ellipse((x*2,y*2,x*2+12,y*2+11),outline='#a74456',width=3)
        d.line((37,82,202,111),fill='#f9d488',width=3)
    elif name == 'parfait':
        for x,y,c in [(47,45,'#ffe3b3'),(77,45,'#ffd0d0'),(51,68,'#f8cbd5'),(70,83,'#fff0bb')]:
            d.ellipse((x*2,y*2,x*2+14,y*2+8),fill=c)
        d.line((85,186,169,186),fill='#fff4db',width=4)
        d.rectangle((119,19,139,29),fill='#ffd3d0')
    elif name == 'ramen':
        for x in (40,49,58,77,87):
            d.arc((x*2,86,x*2+20,131),70,245,fill='#ffe18c',width=3)
        d.rectangle((77,159,170,164),fill='#fff1cd')
        d.polygon([(104,84),(113,78),(121,88),(110,94)],fill='#558f66')
        d.polygon([(172,96),(186,85),(189,104),(177,110)],fill='#558f66')
    elif name == 'final':
        for x,y,c in [(41,62,'#ffe084'),(65,68,'#e47376'),(97,66,'#f4c565'),(113,46,'#ffd8e0'),(46,105,'#dfa153')]:
            d.ellipse((x*2,y*2,x*2+15,y*2+11),fill=c)
        for x,y in [(30,38),(140,37),(149,78),(24,88)]:
            d.line((x*2-7,y*2,x*2+7,y*2),fill='#fff2b9',width=3)
            d.line((x*2,y*2-7,x*2,y*2+7),fill='#fff2b9',width=3)
    im.save(OUT / (name + '.png'))

def detailed_player(name, facing='front', step=0):
    im, d = canvas(96, 120)
    skin, shadow, hair, hairlight = '#f2b58f', '#d99178', '#443344', '#725162'
    navy, navylight, blouse = '#303d5a', '#566681', '#f5eee1'
    stride = 6 if step == 1 else -6 if step == 2 else 0
    # The bag always hangs on her left shoulder and is visible in every view.
    if facing == 'side':
        d.rectangle((35-stride,89,45-stride,108),fill=navy)
        d.rectangle((54+stride,89,64+stride,108),fill=navy)
        d.rectangle((32-stride,106,48-stride,114),fill='#262b43')
        d.rectangle((52+stride,106,70+stride,114),fill='#262b43')
        d.polygon([(34,55),(63,55),(69,91),(36,91)],fill=blouse,outline=INK)
        d.polygon([(45,57),(59,57),(62,83),(49,87)],fill='#d8dce0')
        d.rectangle((52,61,78,92),fill='#9c6855',outline=INK,width=2)
        d.rectangle((56,66,75,86),fill='#c78a67')
        d.line((47,58,61,80),fill='#856054',width=4)
        d.polygon([(35,62),(43,60),(43,81),(35,88),(29,83)],fill=skin,outline=shadow)
        d.polygon([(61,60),(68,65),(70,84),(62,88),(57,81)],fill=skin,outline=shadow)
        d.rectangle((42,45,54,58),fill=skin)
        d.ellipse((27,14,69,64),fill=hair,outline=INK,width=2)
        d.ellipse((42,25,72,57),fill=skin)
        d.polygon([(29,19),(46,11),(65,17),(70,32),(60,31),(52,27),(40,37),(29,37)],fill=hair)
        d.rectangle((66,40,70,44),fill=INK)
        d.rectangle((71,49,74,51),fill='#ac6973')
        d.rectangle((31,48,39,62),fill=hair)
        d.rectangle((39,20,47,24),fill=hairlight)
        d.rectangle((52,17,61,20),fill=hairlight)
    else:
        d.rectangle((28+stride,88,42+stride,109),fill=navy)
        d.rectangle((55-stride,88,69-stride,109),fill=navy)
        d.rectangle((26+stride,107,47+stride,115),fill='#252b42')
        d.rectangle((52-stride,107,74-stride,115),fill='#252b42')
        d.rectangle((31,86,66,94),fill=navylight)
        d.polygon([(29,55),(66,55),(73,89),(24,89)],fill=blouse,outline=INK)
        d.polygon([(45,56),(54,56),(58,78),(49,89),(40,77)],fill='#c8d1d8')
        d.rectangle((25,60,31,84),fill=skin)
        d.rectangle((67,60,73,84),fill=skin)
        d.rectangle((23,82,32,89),fill=shadow)
        d.rectangle((66,82,75,89),fill=shadow)
        d.rectangle((29,62,37,91),fill='#a56f59')
        d.rectangle((28,77,46,96),fill='#be8465',outline=INK,width=2)
        d.line((32,61,45,83),fill='#775366',width=3)
        d.rectangle((42,45,56,59),fill=skin)
        d.ellipse((24,12,74,66),fill=hair,outline=INK,width=2)
        if facing == 'front':
            d.ellipse((31,21,67,58),fill=skin)
            d.rectangle((24,16,70,29),fill=hair)
            d.polygon([(24,28),(33,24),(33,48),(27,56)],fill=hair)
            d.rectangle((40,41,44,45),fill=INK)
            d.rectangle((56,41,60,45),fill=INK)
            d.rectangle((46,53,55,55),fill='#ad6974')
            d.rectangle((32,48,38,50),fill='#e99d92')
            d.rectangle((62,48,68,50),fill='#e99d92')
        else:
            d.rectangle((25,30,73,68),fill=hair)
            d.rectangle((33,37,62,53),fill=hairlight)
            d.rectangle((27,62,70,66),fill=hair)
            d.line((37,58,50,78),fill='#866174',width=3)
    d.rectangle((33,72,36,78),fill='#fffaf0')
    d.rectangle((59,72,62,78),fill='#fffaf0')
    save(im,name)

def polish_building(name):
    source = Image.open(OUT / (name + '.png')).convert('RGBA')
    im = source.resize((352,320), Image.Resampling.NEAREST)
    d = ImageDraw.Draw(im)
    # Rows of masonry, roof tiles, warm window panes and a unique shop emblem.
    for y in (181,215,249):
        for x in range(26 + (y//34%2)*23,322,46):
            d.line((x,y,x+29,y),fill='#f5dbc8',width=2)
    for y in (34,49,64):
        for x in range(42,310,30):
            d.line((x,y,x+17,y),fill='#f4d0b0',width=2)
    for x in (50,138,226):
        d.rectangle((x+7,184,x+56,250),outline='#f2e4cb',width=3)
        d.rectangle((x+11,190,x+52,202),fill='#fff1be')
        d.line((x+31,184,x+31,250),fill='#e4eee3',width=3)
    d.rectangle((142,270,210,310),fill='#67576c',outline='#e8d1ba',width=3)
    d.ellipse((197,287,202,292),fill='#f4d389')
    d.rectangle((59,106,293,148),fill='#f4e6c8',outline=INK,width=3)
    emblem = {
        'office': ('#6e83a1',[(89,114,124,140),(133,114,168,140),(177,114,212,140)]),
        'home': ('#d57e79',[(157,115,184,141)]),
        'sweets': ('#d66d8b',[(126,121,159,141),(163,116,194,141)]),
        'diner': ('#ae7856',[(137,121,186,138)]),
        'shop': ('#5c9b87',[(137,117,190,140)]),
        'houses': ('#887894',[(141,116,187,141)])
    }
    color, shapes = emblem[name]
    for shape in shapes: d.rectangle(shape,fill=color)
    if name == 'sweets':
        d.ellipse((146,111,172,130),fill='#f5a8af')
        d.ellipse((173,110,196,129),fill='#fff7d8')
    elif name == 'diner':
        d.arc((125,106,199,144),0,180,fill='#f2ca79',width=5)
    elif name == 'shop':
        d.polygon([(153,119),(163,108),(175,119)],fill='#ffedb5')
    elif name == 'home':
        d.polygon([(143,118),(170,101),(198,118)],fill='#f5d6b0')
    im.save(OUT / (name + '.png'))

def polish_street(name):
    source = Image.open(OUT / (name + '.png')).convert('RGBA')
    im = source.resize((source.width * 2,source.height * 2),Image.Resampling.NEAREST)
    d = ImageDraw.Draw(im)
    if name == 'tree':
        for x,y in [(19,59),(27,38),(47,28),(60,46),(69,62),(36,73),(52,69),(24,77)]:
            d.rectangle((x*2,y*2,x*2+15,y*2+6),fill='#8dbb86')
            d.rectangle((x*2+4,y*2-5,x*2+10,y*2-2),fill='#b1d09a')
        d.rectangle((77,149,84,181),fill='#906f62')
    else:
        d.ellipse((7,1,75,57),outline='#fff0b2',width=3)
        d.rectangle((37,65,46,168),fill='#9a8590')
        d.rectangle((12,33,67,39),fill='#928393')
        d.rectangle((43,48,50,54),fill='#fff6c2')
    im.save(OUT / (name + '.png'))

def polish_seated():
    source = Image.open(OUT / 'player_seated.png').convert('RGBA')
    im = source.resize((160,160),Image.Resampling.NEAREST)
    d = ImageDraw.Draw(im)
    d.rectangle((48,21,76,26),fill='#725162')
    d.rectangle((51,42,57,49),fill='#b4786b')
    d.rectangle((83,43,89,49),fill='#b4786b')
    d.rectangle((52,89,71,94),fill='#f9f0e5')
    d.rectangle((54,104,108,108),fill='#d8d6d4')
    d.rectangle((107,92,133,118),outline='#e1ac88',width=3)
    d.line((48,88,77,123),fill='#8c6072',width=4)
    d.rectangle((41,139,101,145),fill='#59667e')
    im.save(OUT / 'player_seated.png')

for food_name in ('donut','cake','karaage','burger','pizza','parfait','ramen','final'):
    polish_food(food_name)
for building_name in ('office','home','sweets','diner','shop','houses'):
    polish_building(building_name)
for street_name in ('tree','lamp'):
    polish_street(street_name)
polish_seated()
for direction in ('front','back','side'):
    for frame in range(3):
        detailed_player('player_%s' % direction if frame == 0 else 'player_%s_walk_%s' % (direction,'a' if frame == 1 else 'b'),direction,frame)
# Keep the established filenames for projects that used the old back walk art.
Image.open(OUT / 'player_back_walk_a.png').save(OUT / 'player_walk_a.png')
Image.open(OUT / 'player_back_walk_b.png').save(OUT / 'player_walk_b.png')
Image.open(OUT / 'player_front.png').rotate(90,expand=True,resample=Image.Resampling.NEAREST).save(OUT / 'player_fallen.png')

RATE=22050
def tone(name, notes, duration=.11, volume=.22, loop=False):
    samples=[]
    for freq in notes:
        count=int(RATE*duration)
        for i in range(count):
            t=i/RATE; env=(1-i/count)**1.4
            v=volume*env*(math.sin(2*math.pi*freq*t)+.22*math.sin(4*math.pi*freq*t))
            samples.append(max(-32767,min(32767,int(v*32767))))
    with wave.open(str(AUDIO/(name+'.wav')),'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(RATE)
        f.writeframes(struct.pack('<%dh'%len(samples),*samples))
for name,notes in {'select':[660,880],'cancel':[440,330],'encounter':[440,550,660,880],
    'attack':[390,270],'damage':[250,160],'eat':[550,660,880], 'phone':[740,740,740],
    'victory':[523,659,784,1047], 'level':[660,880,1100,1320],
    'gameover':[440,349,262,196], 'clear':[523,659,784,1047,1318]}.items(): tone(name,notes)
for name,notes in {'title':[523,659,784,659,587,698,784,1047],
    'field':[392,494,587,494,440,523,659,523],
    'battle':[330,392,440,523,440,392,349,294],
    'ending':[523,659,784,1047,784,659,523,392]}.items():
    tone('bgm_'+name,notes,.24,.065)
print('Generated',len(list(OUT.glob('*.png'))),'PNGs and',len(list(AUDIO.glob('*.wav'))),'WAVs')
