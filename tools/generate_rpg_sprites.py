"""Original 48px characters and 64px food monsters, drawn on a true pixel grid.

Run after generate_assets.py. The game requires only the generated PNG files.
"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'generated'
INK = '#30354a'
HAIR = '#503547'
HAIR_L = '#8b5864'
SKIN = '#ffd1ae'
PINK = '#df8796'
CREAM = '#fff5dd'

def sheet(w, h):
    im = Image.new('RGBA', (w, h))
    return im, ImageDraw.Draw(im)

def save(im, name):
    im.save(OUT / (name + '.png'))

def character(direction, frame):
    im, d = sheet(48, 64)
    stride = [0, 3, -3][frame]
    # Feet stay on one baseline so walking does not jitter between views.
    for x, s in [(18, stride), (28, -stride)]:
        d.rectangle((x+s, 47, x+s+4, 57), fill='#68556c')
        d.rectangle((x+s-1, 56, x+s+6, 59), fill=INK)
        d.rectangle((x+s, 56, x+s+3, 56), fill='#b1a0a0')
    if direction == 'side':
        d.polygon([(18,39),(30,39),(34,50),(15,50)], fill='#604862', outline=INK)
        d.line((18,48,31,48), fill='#a2718a', width=2)
        d.polygon([(19,28),(29,28),(33,41),(16,42)], fill=PINK, outline=INK)
        d.rectangle((25,29,28,39), fill=CREAM)
        d.rectangle((28,34,33,43), fill='#efb0ae')
        d.rectangle((29,42,33,45), fill=SKIN)
        d.line((18,32,13,43), fill='#875656', width=2)
        d.rectangle((10,42,18,50), fill='#c49162', outline=INK)
        d.rectangle((12,44,16,45), fill='#ffe0a1')
        d.ellipse((12,5,34,30), fill=HAIR, outline=INK)
        d.polygon([(12,17),(20,18),(20,31),(15,34),(11,29)], fill=HAIR)
        d.ellipse((21,12,35,28), fill=SKIN)
        d.polygon([(16,8),(27,6),(34,11),(35,17),(29,14),(23,16),(20,22),(15,20)], fill=HAIR)
        d.rectangle((17,10,24,12), fill=HAIR_L)
        d.rectangle((14,21,16,28), fill=HAIR_L)
        d.rectangle((31,18,33,21), fill=INK)
        d.point((32,18), fill=CREAM)
        d.rectangle((32,24,35,25), fill='#e59493')
        d.rectangle((25,10,29,11), fill='#ffb8be')
    else:
        d.polygon([(17,39),(31,39),(35,50),(13,50)], fill='#604862', outline=INK)
        d.line((16,48,32,48), fill='#a2718a', width=2)
        d.polygon([(16,28),(32,28),(34,42),(14,42)], fill=PINK, outline=INK)
        d.rectangle((22,29,26,39), fill=CREAM)
        d.rectangle((14,32,17,42), fill='#efb0ae')
        d.rectangle((32,32,35,42), fill='#efb0ae')
        d.rectangle((13,41,17,45), fill=SKIN)
        d.rectangle((32,41,36,45), fill=SKIN)
        d.ellipse((11,4,36,31), fill=HAIR, outline=INK)
        if direction == 'front':
            d.ellipse((17,12,31,28), fill=SKIN)
            d.polygon([(13,9),(20,6),(30,7),(35,13),(32,19),(28,13),(23,16),(18,13),(15,23),(12,21)], fill=HAIR)
            d.polygon([(12,20),(17,21),(16,31),(12,33),(10,28)], fill=HAIR)
            d.polygon([(32,20),(36,19),(38,29),(34,33),(31,29)], fill=HAIR)
            d.rectangle((19,19,21,22), fill=INK)
            d.rectangle((28,19,30,22), fill=INK)
            d.point((20,19), fill=CREAM)
            d.point((29,19), fill=CREAM)
            d.rectangle((17,24,20,25), fill='#e59493')
            d.rectangle((29,24,32,25), fill='#e59493')
            d.line((23,27,25,28,27,27), fill='#b8717d')
            d.rectangle((17,9,22,10), fill=HAIR_L)
        else:
            d.polygon([(12,16),(35,16),(38,28),(33,33),(26,31),(20,32),(13,34),(10,29)], fill=HAIR)
            d.rectangle((16,13,29,15), fill=HAIR_L)
            d.rectangle((13,20,16,27), fill='#6d4356')
            d.rectangle((29,19,32,26), fill='#6d4356')
        d.rectangle((31,11,34,13), fill='#ffb8be')
        d.line((33,32,38,42), fill='#875656', width=2)
        d.rectangle((35,41,43,49), fill='#c49162', outline=INK)
        d.rectangle((37,43,41,44), fill='#ffe0a1')
    return im

def eyes(d, x, y, gap=8):
    for ex in (x-gap, x+gap):
        d.rectangle((ex-2,y-3,ex+2,y+3), fill=INK)
        d.rectangle((ex-1,y-2,ex,y-1), fill=CREAM)
    d.rectangle((x-gap-4,y+5,x-gap,y+6), fill='#ec9294')
    d.rectangle((x+gap,y+5,x+gap+4,y+6), fill='#ec9294')
    d.line((x-3,y+5,x,y+7,x+3,y+5), fill=INK, width=1)

def monster(kind):
    im,d = sheet(64,64)
    for x in (20,41):
        d.rectangle((x,48,x+4,56),fill=INK)
        d.ellipse((x-4,54,x+7,60),fill='#a17fa3',outline=INK)
    # Small gloved arms give the food creatures a readable monster silhouette.
    d.ellipse((4,34,14,43),fill='#f6c7a0',outline=INK)
    d.ellipse((50,34,60,43),fill='#f6c7a0',outline=INK)
    if kind == 'donut':
        d.ellipse((9,10,55,53),fill='#a85e3d',outline=INK,width=2)
        d.ellipse((11,10,53,47),fill='#e5aa61')
        d.ellipse((13,11,51,40),fill='#73434e',outline=INK)
        d.arc((16,13,49,37),190,290,fill='#c9817c',width=2)
        d.ellipse((25,17,39,30),fill='#f2d38c',outline=INK,width=2)
        d.ellipse((28,20,36,27),fill=(0,0,0,0))
        for x,y,c in [(19,17,'#fff1bc'),(42,18,'#eab2ce'),(17,28,'#99d8ad'),(44,30,'#f5d978')]:
            d.rectangle((x,y,x+3,y+1),fill=c)
        eyes(d,32,39,9)
    elif kind == 'cake':
        d.polygon([(12,25),(40,13),(53,26),(52,51),(12,51)],fill='#e3a780',outline=INK,width=2)
        d.polygon([(15,29),(50,29),(50,46),(15,46)],fill='#fff2ce')
        d.rectangle((15,35,50,39),fill='#df8096')
        d.polygon([(12,25),(40,13),(53,26),(25,33)],fill='#fffbe8',outline=INK)
        d.ellipse((29,10,40,22),fill='#e66f83',outline=INK)
        d.rectangle((33,9,37,11),fill='#6aa16a')
        for x,y in [(32,14),(37,17),(33,19)]: d.point((x,y),fill='#ffe5ab')
        eyes(d,32,41,9)
    elif kind == 'karaage':
        d.polygon([(11,23),(19,13),(30,16),(39,11),(52,19),(55,32),(49,48),(34,53),(18,49),(9,36)],fill='#b56838',outline=INK,width=2)
        for x,y in [(19,23),(30,18),(41,22),(15,34),(26,42),(41,40)]:
            d.polygon([(x,y),(x+6,y-3),(x+10,y+3),(x+5,y+7),(x-2,y+5)],fill='#e4a351')
            d.line((x,y,x+5,y-1),fill='#ffcf77',width=2)
        eyes(d,32,33,9)
        d.arc((17,2,26,14),110,270,fill='#e0dfc8',width=2)
        d.arc((38,0,47,12),110,270,fill='#e0dfc8',width=2)
    elif kind == 'burger':
        d.ellipse((10,10,54,39),fill='#d58b44',outline=INK,width=2)
        d.ellipse((13,11,51,31),fill='#f0be69')
        for x,y in [(20,19),(30,15),(42,21),(34,24)]: d.line((x,y,x+2,y-1),fill=CREAM,width=2)
        d.rectangle((10,30,54,35),fill='#70ac65',outline=INK)
        d.rectangle((10,35,54,41),fill='#784744',outline=INK)
        d.polygon([(11,38),(23,43),(31,39),(43,44),(53,39),(51,46),(13,46)],fill='#f5d376',outline=INK)
        d.rounded_rectangle((12,44,52,53),radius=4,fill='#e6a559',outline=INK,width=2)
        eyes(d,32,29,9)
    elif kind == 'pizza':
        d.polygon([(9,16),(55,19),(33,55)],fill='#d58b45',outline=INK,width=2)
        d.polygon([(13,21),(50,23),(33,49)],fill='#f6d47b',outline='#be7251')
        d.line((11,17,53,20),fill='#e9aa66',width=5)
        for x,y in [(21,27),(41,27),(32,40)]:
            d.ellipse((x-4,y-4,x+4,y+4),fill='#d86c79',outline='#974b61')
            d.point((x-1,y-1),fill='#f4a287')
        eyes(d,32,33,7)
    elif kind == 'parfait':
        d.polygon([(16,29),(48,29),(43,51),(36,55),(27,55),(21,51)],fill='#9cc9d2',outline=INK,width=2)
        d.rectangle((22,34,43,39),fill='#e88fa7')
        d.rectangle((24,44,41,48),fill='#eec983')
        d.line((20,32,25,46),fill='#f6f6d7',width=2)
        d.ellipse((12,20,51,34),fill='#fff0d4',outline=INK)
        d.ellipse((20,12,42,28),fill=CREAM,outline=INK)
        d.ellipse((29,6,38,15),fill='#dd657c',outline=INK)
        d.rectangle((44,6,47,25),fill='#d6a665',outline=INK)
        eyes(d,32,37,8)
    elif kind in ('ramen','final'):
        d.polygon([(9,29),(55,29),(49,49),(41,55),(23,55),(15,49)],fill='#d76577',outline=INK,width=2)
        d.line((17,48,47,48),fill='#ffe1a8',width=2)
        d.ellipse((8,17,56,35),fill='#fff0ce',outline=INK,width=2)
        d.ellipse((12,20,52,31),fill='#d09b50')
        for x in (19,25,31,38): d.arc((x,21,x+10,30),10,280,fill='#ffe298',width=2)
        d.ellipse((17,19,28,27),fill='#c87971',outline='#935465')
        d.ellipse((36,20,45,29),fill=CREAM,outline='#aa9a79')
        d.ellipse((39,23,43,27),fill='#efc661')
        d.rectangle((43,15,48,20),fill='#609562')
        eyes(d,32,39,9)
        if kind == 'final':
            d.polygon([(5,15),(8,2),(17,7),(26,1),(35,7),(45,2),(51,16)],fill='#f2ce72',outline=INK)
            d.rectangle((10,13,48,17),fill='#ea996b',outline=INK)
            d.ellipse((3,31,15,44),fill='#c18644',outline=INK)
            d.ellipse((49,33,62,46),fill='#b97c40',outline=INK)
            for x,y in [(5,5),(56,11),(57,25)]:
                d.line((x-2,y,x+2,y),fill='#f6da86')
                d.line((x,y-2,x,y+2),fill='#f6da86')
    return im

for direction in ('front','back','side'):
    for frame in range(3):
        name = 'player_' + direction + ('' if frame == 0 else '_walk_' + ('a' if frame == 1 else 'b'))
        save(character(direction,frame),name)
save(character('back',1),'player_walk_a')
save(character('back',2),'player_walk_b')
save(character('front',0).rotate(90,expand=True,resample=Image.Resampling.NEAREST),'player_fallen')
im,d = sheet(64,64)
d.polygon([(20,42),(39,42),(51,54),(15,54)],fill='#604862',outline=INK)
d.rectangle((17,53,33,59),fill=INK)
d.rectangle((39,53,55,59),fill=INK)
# Reuse the same hand-drawn head and cardigan, preserving her identity in endings.
standing=character('front',0)
im.alpha_composite(standing.crop((0,0,48,44)),(6,0))
save(im,'player_seated')
for kind in ('donut','cake','karaage','burger','pizza','parfait','ramen','final'):
    save(monster(kind),kind)
print('Wrote original RPG character and monster sprites.')
