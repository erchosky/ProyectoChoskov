import math,random,wave,struct,pathlib
random.seed(21)
for name,freq,duration in [('shot',180,.13),('rifle',135,.09),('hit',110,.16),('loot',690,.24),('reload',260,.35),('extract',520,.65),('heal',440,.4),('shotgun',75,.25),('step',65,.09),('dodge',90,.22)]:
 samples=[]
 for i in range(int(22050*duration)):
  t=i/22050; env=(1-t/duration)**2
  tone=math.sin(2*math.pi*(freq+t*freq)*t)
  noise=random.uniform(-1,1)
  val=(noise*.65+tone*.35) if name in ['shot','rifle','hit','reload','shotgun'] else (tone*.65+math.sin(2*math.pi*freq*1.5*t)*.25)
  if name in ['step','dodge']:
   val=tone*.45+noise*.2
  samples.append(struct.pack('<h',int(val*env*18000)))
 with wave.open(str(pathlib.Path('assets')/(name+'.wav')),'wb') as f:
  f.setparams((1,2,22050,0,'NONE','not compressed'));f.writeframes(b''.join(samples))
