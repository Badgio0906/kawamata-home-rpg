"""Enumerate stage-two strategies and run seeded damage trials (design audit)."""
import json, random, itertools, math
from pathlib import Path

ENEMIES=json.loads((Path(__file__).resolve().parents[1]/'data/enemies.json').read_text(encoding='utf-8'))
ROUTE=['s2_donut','s2_karaage','s2_pizza','s2_burger','s2_parfait','s2_ramen','s2_feast','s2_final']

def simulate(plan, seed=0):
    rng=random.Random(seed)
    hp=cap=136; level=4; exp=240; atk=34; defense=14; cal=900; mot=80
    trace=[]
    for i,(key,cmd) in enumerate(zip(ROUTE,plan)):
        e=ENEMIES[key]
        if cmd==1:
            ehp=e['hp']
            for turn in range(1000):
                damage=0 if e.get('invulnerable') else max(1,math.floor(atk*(.5+mot/200)-e['defense']+rng.randint(-2,2)+.5))
                ehp-=damage
                if ehp<=0: break
                hp-=max(1,math.floor(e['attack']-defense*(.5+mot/200)+rng.randint(-2,2)+.5))
                if hp<=0: return 'hp',trace
            cal=max(0,cal+e['fight_calories']); mot-=e['motivation_cost']; exp+=e['exp']
            if level==4 and exp>=380:
                level=5; cap+=12; atk+=4; defense+=2; hp=min(cap,hp+20)
        elif cmd==2:
            for bite in range(e.get('eat_required',1)):
                cal+=e['eat_calories']; mot=min(100,mot+e['eat_motivation']); hp=min(cap,hp+e['eat_heal'])
                if cal>=1600: return 'calories',trace
        else:
            if e.get('cannot_call'): return 'blocked',trace
            mot-=e['motivation_cost']
        if mot<=10: return 'motivation',trace
        if i==2: hp=min(cap,hp+60)
        trace.append((key,hp,cal,mot,level))
    return 'clear',trace

if __name__=='__main__':
    viable=[]; outcomes={}
    for prefix in itertools.product((1,2,3),repeat=6):
        for last in (1,2,3):
            plan=prefix+(2,last)
            outcome,trace=simulate(plan)
            outcomes[outcome]=outcomes.get(outcome,0)+1
            if outcome=='clear':
                wins=sum(simulate(plan,seed)[0]=='clear' for seed in range(200))
                viable.append((wins,plan,trace))
    viable.sort(reverse=True)
    print('outcomes',outcomes,'of',3**7)
    for item in viable[:8]: print(item)

